import 'package:field_work/core/utils/helpers.dart';
import 'package:field_work/features/profile/data/profile_datasource.dart';
import 'package:field_work/features/profile/screen/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import '../../auth/model/user_model.dart';

class ProfileController {
  final BuildContext context;
  final VoidCallback reloadData;

  bool isLoading = false;
  UserModel? userData;

  ProfileController({required this.context, required this.reloadData});

  void init() async {
    await getProfileDetail();
  }

  Future<void> getProfileDetail() async {
    isLoading = true;
    reloadData();
    try {
      final response = await ProfileDatasource().geUserProfile();
      if (response == null) {
        Helpers.showSnackBar(
          context,
          'Something went wrong!',
          type: SnackType.error,
        );
        return;
      }

      if (response.success ?? false) {
        userData = response.data?.user;
      } else {
        Helpers.showSnackBar(
          context,
          response.message ?? 'Something went wrong',
          type: SnackType.error,
        );
      }


    } catch (e) {
      debugPrint(e.toString());
    } finally {
      isLoading = false;
      reloadData();
    }
  }

  void navigateToEditScreen() {
    if (userData == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) =>
    EditProfileScreen(userData: userData!))).then((_)=> init());
  }

}