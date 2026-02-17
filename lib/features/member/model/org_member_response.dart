import '../../auth/model/user_model.dart';

class OrgAllMemberResponse {
  final bool? success;
  final OrgMemberData? data;

  OrgAllMemberResponse({
    this.success,
    this.data,
  });

  factory OrgAllMemberResponse.fromJson(Map<String, dynamic> json) {
    return OrgAllMemberResponse(
      success: json['success'],
      data: json['data'] != null
          ? OrgMemberData.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data?.toJson(),
    };
  }
}

class OrgMemberData {
  final List<UserModel>? members;
  final MemberPaginationModel? pagination;

  OrgMemberData({
    this.members,
    this.pagination,
  });

  factory OrgMemberData.fromJson(Map<String, dynamic> json) {
    return OrgMemberData(
      members: json['members'] != null
          ? List<UserModel>.from(
        json['members'].map((e) => UserModel.fromJson(e)),
      )
          : null,
      pagination: json['pagination'] != null
          ? MemberPaginationModel.fromJson(json['pagination'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'members': members?.map((e) => e.toJson()).toList(),
      'pagination': pagination?.toJson(),
    };
  }
}

class MemberPaginationModel {
  final int? page;
  final int? limit;
  final int? totalMembers;
  final int? totalPages;

  MemberPaginationModel({
    this.page,
    this.limit,
    this.totalMembers,
    this.totalPages,
  });

  factory MemberPaginationModel.fromJson(Map<String, dynamic> json) {
    return MemberPaginationModel(
      page: json['page'],
      limit: json['limit'],
      totalMembers: json['totalMembers'],
      totalPages: json['totalPages'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'totalMembers': totalMembers,
      'totalPages': totalPages,
    };
  }
}
