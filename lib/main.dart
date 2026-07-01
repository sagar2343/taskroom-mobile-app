import 'dart:async';
import 'package:field_work/config/data/local/app_data.dart';
import 'package:field_work/firebase_options.dart';
import 'package:field_work/services/fcm_service.dart';
import 'package:field_work/services/notification_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/theme/theme.dart';
import 'config/theme/theme_notifier.dart';
import 'features/location_tracking/service/location_background_service.dart';
import 'features/splash/view/screen/splash_screen.dart';

final ThemeNotifier themeNotifier = ThemeNotifier();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Catch Flutter framework errors
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // Catch async errors outside Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await NotificationHelper.initialize();
  await FcmService.initialize();
  await AppData().restoreInstance();
  await LocationBackgroundService.initialize();

  runZonedGuarded(
        () => runApp(const MyApp()),
        (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
  // runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // bool isDark = AppData().getIsDarkTheme() ?? false;
    return ValueListenableBuilder(
      valueListenable: themeNotifier,
      builder: (context, ThemeMode currentMode, child) {
        return  MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Task Room',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          navigatorKey: navigatorKey,
          home: const Splashscreen(),
        );
      },
    );
  }
}
