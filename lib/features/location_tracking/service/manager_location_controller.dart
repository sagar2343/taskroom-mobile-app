// lib/features/location_tracking/service/manager_location_controller.dart
//
// Used by ManagerTaskDetailScreen / TaskLocationMapSheet.
//
// In live mode the controller:
//   1. Seeds the map from the REST endpoint (initial position when sheet opens)
//   2. Connects a Socket.IO client and listens for "employee_location" events
//   3. Calls reloadData() whenever a new position arrives → map re-renders
//
// The existing REST-based loadLiveLocation() / loadLocationTrace() on
// ManagerTaskDetailController are still used for the route-history (Full Route)
// mode and as a seed for live mode. Nothing is removed — this controller
// extends the live-mode capability.

import 'dart:async';

import 'package:field_work/config/constant/http_constants.dart';
import 'package:field_work/config/data/local/app_data.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// ── EmployeeLocationUpdate  ───────────────────────────────────────────────────
class EmployeeLocationUpdate {
  final String taskId;
  final String stepId;
  final double lat;
  final double lng;
  final double? accuracy;
  final int? battery;
  final DateTime timestamp;

  EmployeeLocationUpdate({
    required this.taskId,
    required this.stepId,
    required this.lat,
    required this.lng,
    this.accuracy,
    this.battery,
    required this.timestamp,
  });

  LatLng get latLng => LatLng(lat, lng);

  factory EmployeeLocationUpdate.fromMap(Map<String, dynamic> data) {
    return EmployeeLocationUpdate(
      taskId:    data['taskId'] as String? ?? '',
      stepId:    data['stepId'] as String? ?? '',
      lat:       (data['lat']  as num).toDouble(),
      lng:       (data['lng']  as num).toDouble(),
      accuracy:  (data['accuracy'] as num?)?.toDouble(),
      battery:   (data['battery']  as num?)?.toInt(),
      timestamp: (DateTime.tryParse(data['timestamp'] as String? ?? '')
          ?? DateTime.now()).toLocal(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
class ManagerLocationController {
  final VoidCallback reloadData;
  final String taskId;

  ManagerLocationController({
    required this.reloadData,
    required this.taskId,
  });

  // ── State ─────────────────────────────────────────────────────────────────
  IO.Socket? _socket;
  bool  isConnecting = false;
  bool  isConnected  = false;
  String? connectionError;

  EmployeeLocationUpdate? latestUpdate;
  final List<LatLng> liveTrail = [];   // breadcrumb trail shown on map

  // ── Connect (call when LocationMapSheet opens in live mode) ───────────────
  Future<void> connect() async {
    if (isConnected || isConnecting) return;

    isConnecting   = true;
    connectionError = null;
    reloadData();

    final token  = AppData().getAccessToken() ?? '';
    final wsUrl  = HttpConstants.getBaseURL
        .replaceFirst('/api', '')
        .replaceFirst(RegExp(r'/$'), '');

    _socket = IO.io(
      wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
      // Disable automatic reconnection — the sheet's lifecycle manages this.
      // Without this the socket keeps reconnecting after dispose(), causing
      // setState() calls on a defunct widget.
          .disableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[ManagerWS] connected');
      // Guard: only emit if we haven't already joined (prevents duplicate
      // watch_task_location emits on transient reconnects)
      if (!isConnected) {
        _socket!.emit('watch_task_location', {
          'token':  token,
          'taskId': taskId,
        });
      }
    });

    _socket!.on('watching_task_location', (data) {
      // Ignore duplicate events (socket may fire this more than once)
      if (isConnected) return;
      isConnecting   = false;
      isConnected    = true;
      connectionError = null;
      debugPrint('[ManagerWS] now watching ${data['room']}');
      reloadData();
    });

    _socket!.on('employee_location', (data) {
      if (!isConnected) return;
      try {
        final update = EmployeeLocationUpdate.fromMap(
          Map<String, dynamic>.from(data as Map),
        );
        latestUpdate = update;
        liveTrail.add(update.latLng);
        if (liveTrail.length > 500) liveTrail.removeAt(0);
        reloadData();
      } catch (e) {
        debugPrint('[ManagerWS] parse error: $e');
      }
    });

    _socket!.on('tracking_stopped', (_) {
      debugPrint('[ManagerWS] employee stopped tracking');
      reloadData();
    });

    _socket!.on('error', (data) {
      connectionError = data is Map ? data['message'] as String? : data.toString();
      isConnecting    = false;
      isConnected     = false;
      reloadData();
    });

    _socket!.onConnectError((data) {
      connectionError = 'Connection failed. Check your network.';
      isConnecting    = false;
      isConnected     = false;
      reloadData();
    });

    _socket!.onDisconnect((_) {
      isConnected = false;
      debugPrint('[ManagerWS] disconnected');
      reloadData();
    });

    _socket!.connect();
  }

  // ── Disconnect (call when sheet closes) ───────────────────────────────────
  void disconnect() {
    _socket?.emit('unwatch_task_location', {'taskId': taskId});
    _socket?.disconnect();
    _socket?.dispose();
    _socket        = null;
    isConnected    = false;
    isConnecting   = false;
    debugPrint('[ManagerWS] disconnected by manager');
  }

  void dispose() => disconnect();
}