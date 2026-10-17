import 'dart:convert';
import 'dart:io';
import 'package:field_work/config/constant/http_constants.dart';
import 'package:field_work/config/data/local/app_data.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/routes/api_routes.dart';
import '../features/task/model/voice_note.dart';

class UploadService {
  static String get _base => HttpConstants.getBaseURL;
  static String? get _token => AppData().getAccessToken();

  // ── Public API ────────────────────────────────────────────────────────────

  static Future<String?> uploadProfilePicture(File imageFile) async {
    return _uploadImage(
      endpoint: APIRouteUploadProfilePicture,
      imageFile: imageFile,
    );
  }

  static Future<String?> uploadStepPhoto(
      File imageFile, {
        required String taskId,
        required String stepId,
      }) async {
    return _uploadImage(
      endpoint: APIRouteUploadStepPhoto,
      imageFile: imageFile,
      extraFields: {'taskId': taskId, 'stepId': stepId},
    );
  }

  /// Upload a room image. Returns Cloudinary secure_url or null.
  static Future<String?> uploadRoomImage(
      File imageFile, {
        required String roomId,
      }) async {
    return _uploadImage(
      endpoint: APIRouteUploadRoomImage,
      imageFile: imageFile,
      extraFields: {'roomId': roomId},
    );
  }

  /// Uploads a manager's recorded voice note (m4a/AAC). Returns the stored
  /// VoiceNote (Cloudinary url + duration) or null on any failure.
  static Future<VoiceNote?> uploadTaskVoiceNote(
      File audioFile, {
        int? fallbackDurationSeconds,
      }) async {
    final fullUrl = '$_base$APIRouteUploadTaskVoiceNote';
    debugPrint('[UploadService] POST $fullUrl');

    try {
      final request = http.MultipartRequest('POST', Uri.parse(fullUrl));
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      // Explicit type — never application/octet-stream (multer would reject it).
      request.files.add(
        await http.MultipartFile.fromPath(
          'voice',
          audioFile.path,
          contentType: MediaType('audio', 'mp4'),
        ),
      );

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final body     = await streamed.stream.bytesToString();
      debugPrint('[UploadService] HTTP ${streamed.statusCode}');

      if (!body.trimLeft().startsWith('{')) {
        debugPrint('[UploadService] ❌ Non-JSON response: $body');
        return null;
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['success'] == true) {
        final data = json['data'] as Map<String, dynamic>?;
        final url  = data?['url'] as String?;
        if (url == null) return null;
        return VoiceNote(
          url: url,
          durationSeconds:
          (data?['durationSeconds'] as num?)?.toInt() ?? fallbackDurationSeconds,
        );
      }

      debugPrint('[UploadService] ❌ API error: ${json['message']}');
      return null;
    } on SocketException catch (e) {
      debugPrint('[UploadService] ❌ Network error: $e');
      return null;
    } catch (e) {
      debugPrint('[UploadService] ❌ Unexpected error: $e');
      return null;
    }
  }

  // ── Private helper ────────────────────────────────────────────────────────

  static Future<String?> _uploadImage({
    required String endpoint,
    required File imageFile,
    Map<String, String>? extraFields,
  }) async {
    final fullUrl = '$_base$endpoint';
    debugPrint('[UploadService] POST $fullUrl');

    try {
      final uri     = Uri.parse(fullUrl);
      final request = http.MultipartRequest('POST', uri);

      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      if (extraFields != null) {
        request.fields.addAll(extraFields);
      }

      // Detect MIME type from extension.
      // image_picker cache files may lack a recognisable extension on some
      // devices, so we always fall back to image/jpeg rather than letting
      // http package default to application/octet-stream (which multer rejects).
      final ext      = imageFile.path.split('.').last.toLowerCase();
      final subtype  = (ext == 'png') ? 'png'
          : (ext == 'webp') ? 'webp'
          : (ext == 'gif') ? 'gif'
          : 'jpeg';                // default — covers jpg + unknown
      final mimeType = MediaType('image', subtype);

      debugPrint('[UploadService] MIME → image/$subtype');

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: mimeType,   // ← explicit type; never application/octet-stream
        ),
      );

      final fileSizeKb = (await imageFile.length()) / 1024;
      debugPrint('[UploadService] Sending ${fileSizeKb.toStringAsFixed(1)} KB');

      final streamed = await request.send();
      final body     = await streamed.stream.bytesToString();

      debugPrint('[UploadService] HTTP ${streamed.statusCode}');

      if (!body.trimLeft().startsWith('{')) {
        debugPrint('[UploadService] ❌ Non-JSON response '
            '(HTTP ${streamed.statusCode}):\n'
            '${body.length > 500 ? body.substring(0, 500) : body}');
        return null;
      }

      final json = jsonDecode(body) as Map<String, dynamic>;

      if (json['success'] == true) {
        final url = json['data']?['url'] as String?;
        debugPrint('[UploadService] ✅ Uploaded → $url');
        return url;
      }

      debugPrint('[UploadService] ❌ API error: ${json['message']}');
      return null;
    } on SocketException catch (e) {
      debugPrint('[UploadService] ❌ Network error: $e');
      return null;
    } catch (e) {
      debugPrint('[UploadService] ❌ Unexpected error: $e');
      return null;
    }
  }
}