import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class TaskFormStep {
  final String localId;
  String title;
  String description;
  DateTime? startDatetime;
  DateTime? endDatetime;
  bool isFieldWorkStep;
  double? latitude;
  double? longitude;
  String? address;
  int locationRadiusMeters;
  bool requirePhoto;
  bool requireSignature;
  String? signatureFrom;
  bool requireLocationCheck;
  bool requireLocationTrace;

  TaskFormStep({
    String? localId,
    this.title = '',
    this.description = '',
    this.startDatetime,
    this.endDatetime,
    this.isFieldWorkStep = false,
    this.latitude,
    this.longitude,
    this.address,
    this.locationRadiusMeters = 100,
    this.requirePhoto = false,
    this.requireSignature = false,
    this.signatureFrom,
    this.requireLocationCheck = false,
    this.requireLocationTrace = false,
  }) : localId = localId ?? _uuid.v4();

  bool get hasLocation => latitude != null && longitude != null;

  bool get isValid {
    if (title.trim().isEmpty) return false;
    if (startDatetime == null || endDatetime == null) return false;
    if (endDatetime!.isBefore(startDatetime!)) return false;
    if (isFieldWorkStep && !hasLocation) return false;
    if (requireSignature && (signatureFrom == null || signatureFrom!.isEmpty)) return false;
    return true;
  }

  String? get validationError {
    if (title.trim().isEmpty) return 'Step title is required';
    if (startDatetime == null) return 'Start time is required';
    if (endDatetime == null) return 'End time is required';
    if (endDatetime!.isBefore(startDatetime!)) return 'End must be after start';
    if (isFieldWorkStep && !hasLocation) return 'Destination location required for field work';
    if (requireSignature && (signatureFrom == null || signatureFrom!.isEmpty)) {
      return 'Select who will sign';
    }
    return null;
  }

  Map<String, dynamic> toApiJson() => {
    'title': title.trim(),
    'description': description.trim().isEmpty ? null : description.trim(),
    'startDatetime': startDatetime!.toIso8601String(),
    'endDatetime': endDatetime!.toIso8601String(),
    'isFieldWorkStep': isFieldWorkStep,
    if (isFieldWorkStep && hasLocation)
      'destinationLocation': {
        'coordinates': [longitude!, latitude!],
        'address': address,
      },
    'locationRadiusMeters': locationRadiusMeters,
    'validations': {
      'requirePhoto': requirePhoto,
      'requireSignature': requireSignature,
      'signatureFrom': requireSignature ? signatureFrom : null,
      'requireLocationCheck': isFieldWorkStep && requireLocationCheck,
      'requireLocationTrace': isFieldWorkStep && requireLocationTrace,
    },
  };

  TaskFormStep copyWith({
    String? title,
    String? description,
    DateTime? startDatetime,
    DateTime? endDatetime,
    bool? isFieldWorkStep,
    double? latitude,
    double? longitude,
    String? address,
    int? locationRadiusMeters,
    bool? requirePhoto,
    bool? requireSignature,
    String? signatureFrom,
    bool? requireLocationCheck,
    bool? requireLocationTrace,
    bool clearLocation = false,
  }) =>
      TaskFormStep(
        localId: localId,
        title: title ?? this.title,
        description: description ?? this.description,
        startDatetime: startDatetime ?? this.startDatetime,
        endDatetime: endDatetime ?? this.endDatetime,
        isFieldWorkStep: isFieldWorkStep ?? this.isFieldWorkStep,
        latitude: clearLocation ? null : (latitude ?? this.latitude),
        longitude: clearLocation ? null : (longitude ?? this.longitude),
        address: clearLocation ? null : (address ?? this.address),
        locationRadiusMeters: locationRadiusMeters ?? this.locationRadiusMeters,
        requirePhoto: requirePhoto ?? this.requirePhoto,
        requireSignature: requireSignature ?? this.requireSignature,
        signatureFrom:
        requireSignature == false ? null : (signatureFrom ?? this.signatureFrom),
        requireLocationCheck: requireLocationCheck ?? this.requireLocationCheck,
        requireLocationTrace: requireLocationTrace ?? this.requireLocationTrace,
      );
}

class PickedLocation {
  final double latitude;
  final double longitude;
  final String? address;
  const PickedLocation({required this.latitude, required this.longitude, this.address});
}