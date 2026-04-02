class TaskModel {
  final String? id;
  final String? organization;
  final TaskRoom? room;
  final TaskCreatedByUser? createdBy;
  final TaskAssignedUser? assignedTo;
  final String? title;
  final String? note;
  final String? priority;
  final DateTime? startDatetime;
  final DateTime? endDatetime;
  final bool? isFieldWork;
  final List<TaskStep>? steps;
  final int? currentStepIndex;
  final int? totalSteps;
  final int? completedSteps;
  final String? status;
  final DateTime? employeeStartTime;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancellationReason;
  final String? lastEditedBy;
  final DateTime? lastEditedAt;
  final bool? editedWhileActive;
  final String? groupId;
  final bool? isGroupTask;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TaskModel({
    this.id,
    this.organization,
    this.room,
    this.createdBy,
    this.assignedTo,
    this.title,
    this.note,
    this.priority,
    this.startDatetime,
    this.endDatetime,
    this.isFieldWork,
    this.steps,
    this.currentStepIndex,
    this.totalSteps,
    this.completedSteps,
    this.status,
    this.employeeStartTime,
    this.completedAt,
    this.cancelledAt,
    this.cancelledBy,
    this.cancellationReason,
    this.lastEditedBy,
    this.lastEditedAt,
    this.editedWhileActive,
    this.groupId,
    this.isGroupTask,
    this.createdAt,
    this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['_id'],
      organization: json['organization'],
      room: json['room'] != null
          ? TaskRoom.fromJson(json['room'])
          : null,
      createdBy: json['createdBy'] != null && json['createdBy'] is Map
          ? TaskCreatedByUser.fromJson(json['createdBy'])
          : null,
      assignedTo: json['assignedTo'] != null && json['assignedTo'] is Map
          ? TaskAssignedUser.fromJson(json['assignedTo'])
          : null,
      title: json['title'],
      note: json['note'],
      priority: json['priority'],
      startDatetime: json['startDatetime'] != null
          ? DateTime.tryParse(json['startDatetime'])?.toLocal()
          : null,
      endDatetime: json['endDatetime'] != null
          ? DateTime.tryParse(json['endDatetime'])?.toLocal()
          : null,
      isFieldWork: json['isFieldWork'],
      steps: json['steps'] != null
          ? List<TaskStep>.from(
        json['steps'].map((e) => TaskStep.fromJson(e)),
      )
          : [],
      currentStepIndex: json['currentStepIndex'],
      totalSteps: json['totalSteps'],
      completedSteps: json['completedSteps'],
      status: json['status'],
      employeeStartTime: json['employeeStartTime'] != null
          ? DateTime.tryParse(json['employeeStartTime'])?.toLocal()
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])?.toLocal()
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'])?.toLocal()
          : null,
      cancelledBy: json['cancelledBy'],
      cancellationReason: json['cancellationReason'],
      lastEditedBy: json['lastEditedBy'],
      lastEditedAt: json['lastEditedAt'] != null
          ? DateTime.tryParse(json['lastEditedAt'])?.toLocal()
          : null,
      editedWhileActive: json['editedWhileActive'],
      groupId: json['groupId'],
      isGroupTask: json['isGroupTask'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])?.toLocal()
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'organization': organization,
      'room': room?.toJson(),
      'createdBy': createdBy?.toJson(),
      'assignedTo': assignedTo?.toJson(),
      'title': title,
      'note': note,
      'priority': priority,
      'startDatetime': startDatetime?.toIso8601String(),
      'endDatetime': endDatetime?.toIso8601String(),
      'isFieldWork': isFieldWork,
      'steps': steps?.map((e) => e.toJson()).toList(),
      'currentStepIndex': currentStepIndex,
      'totalSteps': totalSteps,
      'completedSteps': completedSteps,
      'status': status,
      'employeeStartTime': employeeStartTime?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancelledBy': cancelledBy,
      'cancellationReason': cancellationReason,
      'lastEditedBy': lastEditedBy,
      'lastEditedAt': lastEditedAt?.toIso8601String(),
      'editedWhileActive': editedWhileActive,
      'groupId': groupId,
      'isGroupTask': isGroupTask,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class TaskRoom {
  final String? id;
  final String? name;
  final String? roomCode;

  TaskRoom({this.id, this.name, this.roomCode});

  factory TaskRoom.fromJson(Map<String, dynamic> json) {
    return TaskRoom(
      id: json['_id'],
      name: json['name'],
      roomCode: json['roomCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'roomCode': roomCode,
    };
  }
}

class TaskCreatedByUser {
  final String? id;
  final String? username;
  final String? fullName;
  final String? profilePicture;

  TaskCreatedByUser({
    this.id,
    this.username,
    this.fullName,
    this.profilePicture,
  });

  factory TaskCreatedByUser.fromJson(Map<String, dynamic> json) {
    return TaskCreatedByUser(
      id: json['_id'],
      username: json['username'],
      fullName: json['fullName'],
      profilePicture: json['profilePicture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'fullName': fullName,
      'profilePicture': profilePicture,
    };
  }
}

class TaskAssignedUser {
  final String? id;
  final String? username;
  final String? fullName;
  final String? profilePicture;
  final bool? isOnline;

  TaskAssignedUser({
    this.id,
    this.username,
    this.fullName,
    this.profilePicture,
    this.isOnline,
  });

  factory TaskAssignedUser.fromJson(Map<String, dynamic> json) {
    return TaskAssignedUser(
      id: json['_id'],
      username: json['username'],
      fullName: json['fullName'],
      profilePicture: json['profilePicture'],
      isOnline: json['isOnline'],
    );
  }

  bool get isPopulated => username != null || fullName != null;

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'fullName': fullName,
      'profilePicture': profilePicture,
      'isOnline': isOnline,
    };
  }
}

class TaskStep {
  final String? stepId;
  final int? order;
  final String? title;
  final String? description;
  final DateTime? startDatetime;
  final DateTime? endDatetime;
  final bool? isFieldWorkStep;
  final int? locationRadiusMeters;
  final TaskLocation? destinationLocation;
  final TaskLocation? submittedLocation;
  final TaskValidations? validations;
  final String? status;
  final bool? isOverdue;
  final DateTime? employeeStartTime;    // ← ADDED
  final DateTime? employeeReachTime;    // ← ADDED
  final DateTime? employeeCompleteTime; // ← ADDED

  final String? submittedPhotoUrl;
  final String? signatureSignedBy;
  final String? employeeNotes;
  final bool? signatureData;


  TaskStep({
    this.stepId,
    this.order,
    this.title,
    this.description,
    this.startDatetime,
    this.endDatetime,
    this.isFieldWorkStep,
    this.locationRadiusMeters,
    this.destinationLocation,
    this.submittedLocation,
    this.validations,
    this.status,
    this.isOverdue,
    this.employeeStartTime,
    this.employeeReachTime,
    this.employeeCompleteTime,

    this.submittedPhotoUrl,
    this.signatureSignedBy,
    this.signatureData,
    this.employeeNotes,
  });

  factory TaskStep.fromJson(Map<String, dynamic> json) {
    return TaskStep(
      stepId: json['stepId'],
      order: json['order'],
      title: json['title'],
      description: json['description'],
      startDatetime: json['startDatetime'] != null
          ? DateTime.tryParse(json['startDatetime'])?.toLocal()
          : null,
      endDatetime: json['endDatetime'] != null
          ? DateTime.tryParse(json['endDatetime'])?.toLocal()
          : null,
      isFieldWorkStep: json['isFieldWorkStep'],
      locationRadiusMeters: json['locationRadiusMeters'],
      destinationLocation: json['destinationLocation'] != null
          ? TaskLocation.fromJson(json['destinationLocation'])
          : null,
      submittedLocation: json['submittedLocation'] != null
          ? TaskLocation.fromJson(json['submittedLocation'])
          : null,
      validations: json['validations'] != null
          ? TaskValidations.fromJson(json['validations'])
          : null,
      status: json['status'],
      isOverdue: json['isOverdue'],
      employeeStartTime: json['employeeStartTime'] != null
          ? DateTime.tryParse(json['employeeStartTime'])?.toLocal()
          : null,
      employeeReachTime: json['employeeReachTime'] != null
          ? DateTime.tryParse(json['employeeReachTime'])?.toLocal()
          : null,
      employeeCompleteTime: json['employeeCompleteTime'] != null
          ? DateTime.tryParse(json['employeeCompleteTime'])?.toLocal()
          : null,

      submittedPhotoUrl : json['submittedPhotoUrl'],
      signatureSignedBy : json['signatureSignedBy'],
      signatureData : parseBool(json['signatureData']),
      employeeNotes : json['employeeNotes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stepId': stepId,
      'order': order,
      'title': title,
      'description': description,
      'startDatetime': startDatetime?.toIso8601String(),
      'endDatetime': endDatetime?.toIso8601String(),
      'isFieldWorkStep': isFieldWorkStep,
      'locationRadiusMeters': locationRadiusMeters,
      'destinationLocation': destinationLocation?.toJson(),
      'submittedLocation': submittedLocation?.toJson(),
      'validations': validations?.toJson(),
      'status': status,
      'isOverdue': isOverdue,
      'employeeStartTime': employeeStartTime?.toIso8601String(),
      'employeeReachTime': employeeReachTime?.toIso8601String(),
      'employeeCompleteTime': employeeCompleteTime?.toIso8601String(),

      'submittedPhotoUrl': submittedPhotoUrl.toString(),
      'signatureSignedBy': signatureSignedBy.toString(),
      'employeeNotes': employeeNotes.toString(),
      'signatureData': signatureData ?? false,
    };
  }
}

class TaskLocation {
  final String? type;
  final List<double>? coordinates;
  final String? address;
  final double? accuracyMeters;

  TaskLocation({
    this.type,
    this.coordinates,
    this.address,
    this.accuracyMeters,
  });

  factory TaskLocation.fromJson(Map<String, dynamic> json) {
    return TaskLocation(
      type: json['type'],
      coordinates: json['coordinates'] != null
          ? List<double>.from(json['coordinates'].map((e) => e.toDouble()))
          : null,
      address: json['address'],
      accuracyMeters: json['accuracyMeters'] != null
          ? (json['accuracyMeters'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
      'address': address,
      'accuracyMeters': accuracyMeters,
    };
  }
}

class TaskValidations {
  final bool? requireSignature;
  final String? signatureFrom;
  final bool? requirePhoto;
  final bool? requireLocationCheck;
  final bool? requireLocationTrace;

  TaskValidations({
    this.requireSignature,
    this.signatureFrom,
    this.requirePhoto,
    this.requireLocationCheck,
    this.requireLocationTrace,
  });

  factory TaskValidations.fromJson(Map<String, dynamic> json) {
    return TaskValidations(
      requireSignature: json['requireSignature'],
      signatureFrom: json['signatureFrom'],
      requirePhoto: json['requirePhoto'],
      requireLocationCheck: json['requireLocationCheck'],
      requireLocationTrace: json['requireLocationTrace'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requireSignature': requireSignature,
      'signatureFrom': signatureFrom,
      'requirePhoto': requirePhoto,
      'requireLocationCheck': requireLocationCheck,
      'requireLocationTrace': requireLocationTrace,
    };
  }
}

bool? parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return null;
}