import 'package:google_maps_flutter/google_maps_flutter.dart';

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
      timestamp: DateTime.tryParse(data['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}