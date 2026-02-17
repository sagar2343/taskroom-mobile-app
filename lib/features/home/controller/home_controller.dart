import 'dart:async';
import 'package:field_work/config/data/local/app_data.dart';
import 'package:field_work/features/auth/model/user_model.dart';
import 'package:field_work/features/home/data/home_datasource.dart';
import 'package:field_work/features/profile/screen/profile_screen.dart';
import 'package:field_work/features/room/view/screen/join_room_screen.dart';
import 'package:field_work/features/splash/view/screen/splash_screen.dart';
import 'package:flutter/material.dart';
import '../../../config/theme/app_pallete.dart';
import '../../../core/utils/helpers.dart';
import '../../room/view/screen/create_room_screen.dart';
import '../../room/view/screen/room_details_screen.dart';
import '../models/all_room_response.dart';
import '../models/room_model.dart';

class HomeController {
  final BuildContext context;
  final VoidCallback reloadData;

  UserModel? userData;
  bool isLoading = false;
  bool isLoadingMore = false;
  Timer? _searchDebounce;

  // Room list data
  List<RoomModel> rooms = [];
  PaginationModel? pagination;

  // Filter and search
  int page = 1;
  int limit = 10;
  String category = '';
  String search = '';

  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  HomeController({required this.context, required this.reloadData}){
   scrollController.addListener(_onScroll);
  }

  void init() async {
    userData = AppData().getUserData();
    await getMyRooms();
    reloadData();
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      loadMore();
    }
  }

  Future<void> getMyRooms({bool refresh = false}) async {
    if (refresh) {
      page = 1;
      rooms.clear();
    }

    isLoading = true;
    reloadData();

    try {
      final response = await HomeDataSource().getMyRoom(
        page: page,
        limit: limit,
        category: category,
        search: search,
      );

      if (response == null) {
        Helpers.showSnackBar(
          context,
          'Something went wrong!',
          type: SnackType.error,
        );
        return;
      }

      if (response.success ?? false) {
        rooms = response.data?.rooms ?? [];
        pagination = response.data?.pagination;
      } else {
        Helpers.showSnackBar(
          context,
          response.message ?? 'Something went wrong',
          type: SnackType.error,
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      Helpers.showSnackBar(
        context,
        'Failed to load rooms',
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

    isLoadingMore = true;
    reloadData();

    try {
      page++;

      final response = await HomeDataSource().getMyRoom(
        page: page,
        limit: limit,
        category: category,
        search: search,
      );

      if (response?.success ?? false) {
        final newRooms = response?.data?.rooms ?? [];
        rooms.addAll(newRooms);
        pagination = response?.data?.pagination;
      }

    } catch(e) {
      debugPrint('Load more error: $e');
      page--;
    } finally {
      isLoadingMore = false;
      reloadData();
    }
  }

  Future<void> onRefresh() async {
    await getMyRooms(refresh: true);
  }

  Future<void> onSearch(String query) async {
    if (search == query) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      search = query;
      getMyRooms(refresh: true);
    });
  }

  void onCreateRoom() {
    Navigator.push(context, MaterialPageRoute(builder: (context) =>
        CreateRoomScreen())).then((_)=>init());
  }

  void onJoinRoom() {
    Navigator.push(context, MaterialPageRoute(builder: (context) =>
        JoinRoomScreen())).then((_)=>init());
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    searchController.clear();
    search = '';
    getMyRooms(refresh: true);
    reloadData();
  }

  Future<void> onCategoryChanged(String newCategory) async {
    category = newCategory;
    await getMyRooms(refresh: true);
  }

  void onRoomTapped(RoomModel room) {
    if (room.id == null) return;
    if (userData?.role?.toLowerCase() != 'manager' && (room.isArchived ?? false)) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomDetailScreen(roomId: room.id!),
      ),
    ).then((result) {
      // Refresh if room was edited
      if (result == true) {
        getMyRooms(refresh: true);
      }
    });
  }

  void onLogoutTapped() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Pallete.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.logout,
                color: Pallete.errorColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout from your account?',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              AppData().clearAll();
              Navigator.pop(context);
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context, MaterialPageRoute(builder: (context)=> Splashscreen()),
                  (route)=> false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Pallete.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Logout',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onProfileTapped() {
    if (userData == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (context)=>
    const ProfileScreen()));
  }

  void dispose() {
    _searchDebounce?.cancel();
    scrollController.dispose();
    searchController.dispose();
  }

}