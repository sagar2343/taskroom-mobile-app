class OrgAvailabilityResponse {
  final bool success;
  final bool exists;
  final bool move;
  final String message;
  final OrganizationPreview? organization;

  OrgAvailabilityResponse({
    required this.success,
    required this.exists,
    required this.move,
    required this.message,
    this.organization,
  });

  factory OrgAvailabilityResponse.fromJson(Map<String, dynamic> json) {
    return OrgAvailabilityResponse(
      success: json['success'] ?? false,
      exists: json['exists'] ?? false,
      move: json['move'] ?? false,
      message: json['message'] ?? '',
      organization: json['organization'] != null
          ? OrganizationPreview.fromJson(json['organization'])
          : null,
    );
  }
}

class OrganizationPreview {
  final String id;
  final String name;
  final String code;
  final String logo;
  final bool isActive;
  final bool isSuspended;

  OrganizationPreview({
    required this.id,
    required this.name,
    required this.code,
    required this.logo,
    required this.isActive,
    required this.isSuspended,
  });

  factory OrganizationPreview.fromJson(Map<String, dynamic> json) {
    return OrganizationPreview(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      logo: json['logo'] ?? '',
      isActive: json['isActive'] ?? false,
      isSuspended: json['isSuspended'] ?? false,
    );
  }
}
