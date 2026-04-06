import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/constant/http_constants.dart';
import '../../../config/data/local/app_data.dart';
import '../data/location_tracking_datasource.dart';

const _kPingIntervalSeconds    = 20;     // REST ping to store route in DB
const _kMinDistanceMeters      = 10.0;   // skip WS broadcast if not moved 15 m
const _kNotificationId         = 901;
const _kNotificationChannelId  = 'fw_location_channel';

// SharedPreferences keys (persisted so the background isolate can read them)
const _kPrefTaskId  = 'fw_bg_task_id';
const _kPrefStepId  = 'fw_bg_step_id';
const _kPrefRoomId  = 'fw_bg_room_id';
const _kPrefToken   = 'fw_bg_token';
const _kPrefBaseUrl = 'fw_bg_base_url';

// ── Top-level background entry point (must be a top-level / static function) ──
@pragma('vm:entry-point')
Future<void> _onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    try {
      // await service.setAsForegroundService();
      // await service.setForegroundNotificationInfo(
      //   title: "Jedlo Delivery Partner",
      //   content: "Waiting for order...",
      // );
    } catch (e) {
      debugPrint("⚠️ Foreground service setup failed: $e");
    }
    service.on('setAsForeground').listen((_) => service.setAsForegroundService());
    service.on('setAsBackground').listen((_) => service.setAsBackgroundService());
  }

  service.on('stopService').listen((_) => service.stopSelf());

  final prefs  = await SharedPreferences.getInstance();
  final taskId = prefs.getString(_kPrefTaskId);
  final stepId = prefs.getString(_kPrefStepId);
  final token  = prefs.getString(_kPrefToken);
  final baseUrl = prefs.getString(_kPrefBaseUrl) ?? '';

  if (taskId == null || stepId == null || token == null) {
    debugPrint('[BG] No active task — stopping service');
    service.stopSelf();
    return;
  }

  debugPrint('[BG] Starting location tracking — task: $taskId');

  // ── Socket.IO connection ────────────────────────────────────────────────
  final wsUrl = baseUrl.replaceFirst('/api', '').replaceFirst(RegExp(r'/$'), '');
  final socket = IO.io(
    wsUrl,
    IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setExtraHeaders({'Authorization': 'Bearer $token'})
        .build(),
  );

  socket.connect();

  socket.onConnect((_) {
    debugPrint('[BG] Socket connected — joining task room');
    socket.emit('join_task_location', {'token': token, 'taskId': taskId});
  });

  socket.on('joined_task_location', (data) {
    debugPrint('[BG] Joined WS room: ${data['room']}');
  });

  socket.on('error', (data) {
    debugPrint('[BG] Socket error: $data');
  });

  socket.onDisconnect((_) => debugPrint('[BG] Socket disconnected'));

  // ── GPS + ping state ────────────────────────────────────────────────────
  Position? lastPingedPosition;
  Position? lastBroadcastPosition;
  DateTime  lastPingTime = DateTime.now().subtract(
      const Duration(seconds: _kPingIntervalSeconds));
  String    currentStepId = stepId;

  // ── GPS stream ──────────────────────────────────────────────────────────
  const locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 5,   // OS-level filter — only fire if moved 5 m
  );

  StreamSubscription<Position>? positionSub;

  positionSub = Geolocator.getPositionStream(locationSettings: locationSettings)
      .listen((position) async {
    // ── 1. WebSocket broadcast (real-time, low-overhead) ──────────────
    final movedEnoughForBroadcast = lastBroadcastPosition == null ||
        Geolocator.distanceBetween(
          lastBroadcastPosition!.latitude,  lastBroadcastPosition!.longitude,
          position.latitude,                position.longitude,
        ) >= _kMinDistanceMeters;

    if (socket.connected && movedEnoughForBroadcast) {
      socket.emit('location_update', {
        'taskId':   taskId,
        'stepId':   currentStepId,
        'lat':      position.latitude,
        'lng':      position.longitude,
        'accuracy': position.accuracy,
      });
      lastBroadcastPosition = position;
    }

    // ── 2. REST ping (route persistence, throttled to every 30 s) ─────
    final now = DateTime.now();
    final elapsed = now.difference(lastPingTime).inSeconds;
    if (elapsed >= _kPingIntervalSeconds) {
      lastPingTime = now;
      _sendRestPing(
        baseUrl:    baseUrl,
        token:      token,
        taskId:     taskId,
        stepId:     currentStepId,
        lat:        position.latitude,
        lng:        position.longitude,
        accuracy:   position.accuracy,
      );
      lastPingedPosition = position;
    }
  });

  // ── Listen to main-isolate commands ────────────────────────────────────
  service.on('update_step').listen((data) {
    if (data != null && data['stepId'] != null) {
      currentStepId = data['stepId'] as String;
      debugPrint('[BG] Step updated to: $currentStepId');
    }
  });

  service.on('stop_tracking').listen((_) async {
    debugPrint('[BG] stop_tracking received — cleaning up');
    await positionSub?.cancel();
    socket.emit('leave_task_location', {'taskId': taskId});
    socket.disconnect();
    service.stopSelf();
  });
}

  // ── iOS background handler (required, can be minimal) ────────────────────────
  @pragma('vm:entry-point')
  Future<bool> _onIosBackground(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  // ── Fire-and-forget REST ping (runs in background isolate) ───────────────────
  Future<void> _sendRestPing({
    required String baseUrl,
    required String token,
    required String taskId,
    required String stepId,
    required double lat,
    required double lng,
    double? accuracy,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/tasks/location/ping');
      final client = HttpClientWrapper(token: token);
      await client.post(uri, body: {
        'taskId':      taskId,
        'stepId':      stepId,
        'coordinates': [lng, lat],
        if (accuracy != null) 'accuracyMeters': accuracy,
      });
      debugPrint('[BG] REST ping sent for step $stepId');
    } catch (e) {
      debugPrint('[BG] REST ping failed: $e');
    }
  }

// ── Minimal HTTP wrapper safe to use in background isolate ───────────────────
class HttpClientWrapper {
  final String token;
  HttpClientWrapper({required this.token});

  Future<void> post(Uri uri, {required Map<String, dynamic> body}) async {
    await http.post(
      uri,
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════════
//  LocationBackgroundService  — public API used from main isolate
// ═══════════════════════════════════════════════════════════════════════════════

class LocationBackgroundService {
  LocationBackgroundService._();
  static final LocationBackgroundService instance = LocationBackgroundService._();

  final _service = FlutterBackgroundService();
  final _ds      = LocationTrackingDatasource();


  // ── initialize()  — call once in main() before runApp() ──────────────────
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        autoStartOnBoot:                  true,
        onStart:                          _onStart,
        autoStart:                        true,
        isForegroundMode:                 false,
        foregroundServiceNotificationId:  _kNotificationId,
        initialNotificationTitle:         'Task Room',
        initialNotificationContent:       'Location tracking active…',
        notificationChannelId:            _kNotificationChannelId,
        foregroundServiceTypes: [
          AndroidForegroundType.location,
          AndroidForegroundType.dataSync,
        ],
      ),
      iosConfiguration: IosConfiguration(
        autoStart:    true,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
    await service.startService();
  }

  // ── syncWithActiveTask()  — call on splash / home screen ─────────────────
  // Checks the backend for an ongoing task and auto-starts tracking if needed.
  Future<void> syncWithActiveTask() async {
    try {
      final status = await _ds.getActiveStatus();
      if (status == null || !status.hasActiveTask) {
        // No active task — make sure service is not running
        final running = await _service.isRunning();
        if (running) await stopTracking();
        return;
      }

      if (!status.requiresTracking) {
        // Task exists but does not need GPS tracking
        return;
      }

      // Start / resume tracking
      await startTracking(
        taskId: status.taskId!,
        stepId: status.stepId ?? '',
        roomId: status.roomId ?? '',
      );
    } catch (e) {
      debugPrint('[LocationBGService] syncWithActiveTask error: $e');
    }
  }

  // ── startTracking()  — call when an employee starts a task ───────────────
  Future<void> startTracking({
    required String taskId,
    required String stepId,
    required String roomId,
  }) async {
    // 1. Persist credentials so the background isolate can read them
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefTaskId,  taskId);
    await prefs.setString(_kPrefStepId,  stepId);
    await prefs.setString(_kPrefRoomId,  roomId);
    await prefs.setString(_kPrefToken,   AppData().getAccessToken() ?? '');
    await prefs.setString(_kPrefBaseUrl, HttpConstants.getBaseURL);

    // 2. Request location permissions if needed
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    // 3. Start (or restart) the background service
    final running = await _service.isRunning();
    if (!running) {
      await _service.startService();
      debugPrint('[LocationBGService] service started');
    } else {
      // Already running — just update the step
      _service.invoke('update_step', {'stepId': stepId});
      debugPrint('[LocationBGService] service already running — step updated');
    }
  }

  // ── updateStep()  — call when employee starts a new step ─────────────────
  Future<void> updateStep(String stepId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefStepId, stepId);

    final running = await _service.isRunning();
    if (running) {
      _service.invoke('update_step', {'stepId': stepId});
    }
  }

  // ── stopTracking()  — call when task is completed or cancelled ────────────
  Future<void> stopTracking() async {
    final running = await _service.isRunning();
    if (running) {
      _service.invoke('stop_tracking');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPrefTaskId);
    await prefs.remove(_kPrefStepId);
    await prefs.remove(_kPrefRoomId);

    debugPrint('[LocationBGService] tracking stopped');
  }

  Future<bool> get isRunning => _service.isRunning();
}