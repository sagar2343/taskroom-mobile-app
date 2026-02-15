class RoomModel {
  final String? id;
  final String? organization;
  final String? name;
  final String? description;
  final String? roomCode;
  final RoomCreator? createdBy;
  final String? category;
  final String? roomImage;
  final bool? isArchived;
  final DateTime? archivedAt;
  final RoomSettings? settings;
  final RoomStats? stats;
  final List<RoomMember>? members;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RoomModel({
    this.id,
    this.organization,
    this.name,
    this.description,
    this.roomCode,
    this.createdBy,
    this.category,
    this.roomImage,
    this.isArchived,
    this.archivedAt,
    this.settings,
    this.stats,
    this.members,
    this.createdAt,
    this.updatedAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['_id'] ?? json['id'], // 👈 FIX 1
      organization: json['organization'],
      name: json['name'],
      description: json['description'],
      roomCode: json['roomCode'],
      createdBy: json['createdBy'] is Map<String, dynamic> // 👈 FIX 2
          ? RoomCreator.fromJson(json['createdBy'])
          : null,
      category: json['category'],
      roomImage: json['roomImage'],
      isArchived: json['isArchived'],
      archivedAt: json['archivedAt'] != null
          ? DateTime.tryParse(json['archivedAt'])
          : null,
      settings: json['settings'] != null
          ? RoomSettings.fromJson(json['settings'])
          : null,
      stats: json['stats'] != null
          ? RoomStats.fromJson(json['stats'])
          : null,
      members: json['members'] != null
          ? List<RoomMember>.from(
        json['members'].map((e) => RoomMember.fromJson(e)),
      )
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }
}

class RoomCreator {
  final String? id;
  final String? username;
  final String? fullName;
  final String? email;
  final String? profilePicture;

  RoomCreator({
    this.id,
    this.username,
    this.fullName,
    this.email,
    this.profilePicture,
  });

  factory RoomCreator.fromJson(Map<String, dynamic> json) {
    return RoomCreator(
      id: json['_id'],
      username: json['username'],
      fullName: json['fullName'],
      email: json['email'],
      profilePicture: json['profilePicture'],
    );
  }
}

class RoomSettings {
  final bool? autoAcceptMembers;
  final bool? allowMembersToSeeEachOther;
  final int? maxMembers;
  final bool? isActive;

  RoomSettings({
    this.autoAcceptMembers,
    this.allowMembersToSeeEachOther,
    this.maxMembers,
    this.isActive,
  });

  factory RoomSettings.fromJson(Map<String, dynamic> json) {
    return RoomSettings(
      autoAcceptMembers: json['autoAcceptMembers'],
      allowMembersToSeeEachOther: json['allowMembersToSeeEachOther'],
      maxMembers: json['maxMembers'],
      isActive: json['isActive'],
    );
  }
}

class RoomStats {
  final int? totalMembers;
  final int? activeTasks;
  final int? completedTasks;
  final int? totalTasks;

  RoomStats({
    this.totalMembers,
    this.activeTasks,
    this.completedTasks,
    this.totalTasks,
  });

  factory RoomStats.fromJson(Map<String, dynamic> json) {
    return RoomStats(
      totalMembers: json['totalMembers'],
      activeTasks: json['activeTasks'],
      completedTasks: json['completedTasks'],
      totalTasks: json['totalTasks'],
    );
  }
}

class RoomMember {
  final RoomMemberUser? user;
  final String? userId;
  final String? status;
  final String? role;
  final String? id;
  final DateTime? joinedAt;

  RoomMember({
    this.user,
    this.userId,
    this.status,
    this.role,
    this.id,
    this.joinedAt,
  });

  factory RoomMember.fromJson(Map<String, dynamic> json) {
    RoomMemberUser? parsedUser;
    String? parsedUserId;

    if (json['user'] is Map<String, dynamic>) {
      parsedUser = RoomMemberUser.fromJson(json['user']);
    } else if (json['user'] is String) {
      parsedUserId = json['user'];
    }

    return RoomMember(
      user: parsedUser,
      userId: parsedUserId,
      status: json['status'],
      role: json['role'],
      id: json['_id'],
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'])
          : null,
    );
  }
}

class RoomMemberUser {
  final String? id;
  final String? username;
  final String? role;
  final String? fullName;
  final String? profilePicture;
  final bool? isOnline;

  RoomMemberUser({
    this.id,
    this.username,
    this.role,
    this.fullName,
    this.profilePicture,
    this.isOnline,
  });

  factory RoomMemberUser.fromJson(Map<String, dynamic> json) {
    return RoomMemberUser(
      id: json['_id'],
      username: json['username'],
      role: json['role'],
      fullName: json['fullName'],
      profilePicture: json['profilePicture'],
      isOnline: json['isOnline'],
    );
  }
}
