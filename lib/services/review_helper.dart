import 'package:in_app_review/in_app_review.dart';

class ReviewHelper {
  static final InAppReview _inAppReview = InAppReview.instance;

  /// Requests Google's native review prompt. Safe to call often — Google
  /// silently no-ops it if the user was already prompted recently or the
  /// quota is used up.
  static Future<void> requestReview() async {
    if (await _inAppReview.isAvailable()) {
      await _inAppReview.requestReview();
    }
  }

  /// Fallback: opens the Play Store listing directly. Use this only if you
  /// need a guaranteed action (e.g. a "Rate us" button in Settings) — since
  /// requestReview() above may silently do nothing due to Google's quota.
  static Future<void> openStoreListing() async {
    await _inAppReview.openStoreListing(appStoreId: 'com.taskroom.app');
  }
}