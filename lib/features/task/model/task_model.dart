class TaskModel {
  final String? id;
  final String? organization;
  final TaskRoom? room;
  final String? createdBy;
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
      createdBy: json['createdBy'],
      assignedTo: json['assignedTo'] != null
          ? TaskAssignedUser.fromJson(json['assignedTo'])
          : null,
      title: json['title'],
      note: json['note'],
      priority: json['priority'],
      startDatetime: json['startDatetime'] != null
          ? DateTime.tryParse(json['startDatetime'])
          : null,
      endDatetime: json['endDatetime'] != null
          ? DateTime.tryParse(json['endDatetime'])
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
          ? DateTime.tryParse(json['employeeStartTime'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'])
          : null,
      cancelledBy: json['cancelledBy'],
      cancellationReason: json['cancellationReason'],
      lastEditedBy: json['lastEditedBy'],
      lastEditedAt: json['lastEditedAt'] != null
          ? DateTime.tryParse(json['lastEditedAt'])
          : null,
      editedWhileActive: json['editedWhileActive'],
      groupId: json['groupId'],
      isGroupTask: json['isGroupTask'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
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
  });

  factory TaskStep.fromJson(Map<String, dynamic> json) {
    return TaskStep(
      stepId: json['stepId'],
      order: json['order'],
      title: json['title'],
      description: json['description'],
      startDatetime: json['startDatetime'] != null
          ? DateTime.tryParse(json['startDatetime'])
          : null,
      endDatetime: json['endDatetime'] != null
          ? DateTime.tryParse(json['endDatetime'])
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
    );
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
}