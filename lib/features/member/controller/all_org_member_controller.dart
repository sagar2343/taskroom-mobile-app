import 'dart:async';
import 'package:field_work/features/member/model/org_member_response.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/helpers.dart';
import '../../auth/model/user_model.dart';
import '../data/member_datasource.dart';

class AllOrgMemberController {
  final BuildContext context;
  final VoidCallback reloadData;

  final MemberDatasource _datasource = MemberDatasource();

  bool isLoading = false;
  bool isLoadingMore = false;
  Timer? _searchDebounce;

  List<UserModel> members = [];
  MemberPaginationModel? pagination;

  // Pagination
  int page = 1;
  int limit = 20;
  int totalMembers = 0;
  int totalPages = 0;

  // Search and Filter
  String search = '';
  String selectedRole = '';

  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  AllOrgMemberController({required this.context, required this.reloadData}){
    scrollController.addListener(_onScroll);
  }

  void init() async {
    await getMembers();
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      loadMore();
    }
  }

  Future<void> getMembers({bool refresh = false}) async {
    if (refresh) {
      page = 1;
      members.clear();
    }

    isLoading = true;
    reloadData();

    try {
      final response = await _datasource.getOrgAllMembers(
        page: page,
        limit: limit,
        role: selectedRole,
        search: search,
      );

      if (response == null) {
        Helpers.showSnackBar(
          context,
          'Failed to load members',
          type: SnackType.error,
        );
        return;
      }

      if (response.success ?? false) {
        if (refresh) {
          members = response.data?.members ?? [];
        } else {
          members.addAll(response.data?.members ?? []);
        }

        pagination = response.data?.pagination;
        totalMembers = response.data?.pagination?.totalMembers ?? 0;
        totalPages = response.data?.pagination?.totalPages ?? 0;
        page = response.data?.pagination?.page ?? 1;
      } else {
        Helpers.showSnackBar(
          context,
          'Failed to load members',
          type: SnackType.error,
        );
      }
    } catch (e) {
      debugPrint('Get members error: $e');
      Helpers.showSnackBar(
        context,
        'Failed to load members',
        type: SnackType.error,
      );
    } finally {
      isLoading = false;
      reloadData();
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore) return;
    if (pagination == null) return;
    if (page >= (pagination!.totalPages ?? 1)) return;

    // if (isLoadingMore || page >= totalPages) return;

    isLoadingMore = true;
    reloadData();

    try {
      page++;

      final response = await _datasource.getOrgAllMembers(
        page: page,
        limit: limit,
        role: selectedRole,
        search: search,
      );

      if (response?.success ?? false) {
        members.addAll(response!.data?.members ?? []);
        pagination = response.data?.pagination;
      }
    } catch (e) {
      debugPrint('Load more error: $e');
      page--; // Revert page on error
    } finally {
      isLoadingMore = false;
      reloadData();
    }
  }

  Future<void> onRefresh() async {
    await getMembers(refresh: true);
  }

  void onSearch(String query) {
    if (search == query) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      search = query;
      getMembers(refresh: true);
    });
  }

  void onRoleFilter(String role) {
    selectedRole = selectedRole == role ? '' : role;
    getMembers(refresh: true);
  }

  void clearFilters() {
    search = '';
    selectedRole = '';
    searchController.clear();
    getMembers(refresh: true);
  }

  bool get hasActiveFilters => search.isNotEmpty || selectedRole.isNotEmpty;

  String getRoleDisplay(String? role) {
    if (role == null) return 'Employee';
    return role[0].toUpperCase() + role.substring(1).toLowerCase();
  }

  String getInitials(String? fullName) {
    if (fullName == null || fullName.isEmpty) return 'U';
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  void dispose() {
    searchController.dispose();
    scrollController.dispose();
  }
}