import 'package:field_work/features/auth/model/organization_model.dart';

class UserModel {
  final String? id;
  final OrganizationModel? organization;
  final String? username;
  final String? mobile;
  final String? role;
  final String? fullName;
  final String? email;
  final String? profilePicture;
  final String? employeeId;
  final String? managerId;
  final UserLocation? currentLocation;
  final bool? isOnline;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? department;
  final String? designation;

  UserModel({
    this.id,
    this.organization,
    this.username,
    this.mobile,
    this.role,
    this.fullName,
    this.email,
    this.profilePicture,
    this.employeeId,
    this.managerId,
    this.currentLocation,
    this.isOnline,
    this.createdAt,
    this.updatedAt,
    this.department,
    this.designation,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    OrganizationModel? org;
    if (json['organization'] is Map<String, dynamic>) {
      org = OrganizationModel.fromJson(json['organization']);
    } else if (json['organization'] is String) {
      org = OrganizationModel(id: json['organization']);
    }

    return UserModel(
      id: json['_id'],
      organization: org,
      username: json['username'],
      mobile: json['mobile'],
      role: json['role'],
      fullName: json['fullName'],
      email: json['email'],
      profilePicture: json['profilePicture'],
      employeeId: json['employeeId'],
      managerId: json['managerId'],
      currentLocation: json['currentLocation'] != null
          ? UserLocation.fromJson(json['currentLocation'])
          : null,
      isOnline: json['isOnline'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
      department: json['department'],
      designation: json['designation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'organization': organization?.toJson(),
      'username': username,
      'mobile': mobile,
      'role': role,
      'fullName': fullName,
      'email': email,
      'profilePicture': profilePicture,
      'employeeId': employeeId,
      'managerId': managerId,
      'currentLocation': currentLocation?.toJson(),
      'isOnline': isOnline,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'department': department,
      'designation': designation,
    };
  }
}

class UserLocation {
  final List<double>? coordinates;
  final String? address;
  final DateTime? lastUpdated;

  UserLocation({
    this.coordinates,
    this.address,
    this.lastUpdated,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      coordinates: json['coordinates'] != null
          ? List<double>.from(
        json['coordinates'].map((e) => (e as num).toDouble()),
      )
          : null,
      address: json['address'],
      lastUpdated: DateTime.tryParse(json['lastUpdated'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coordinates': coordinates,
      'address': address,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }
}