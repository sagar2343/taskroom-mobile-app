import 'package:field_work/config/data/local/app_data.dart';
import 'package:field_work/services/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/theme/theme.dart';
import 'config/theme/theme_notifier.dart';
import 'features/location_tracking/service/location_background_service.dart';
import 'features/splash/view/screen/splash_screen.dart';

final ThemeNotifier themeNotifier = ThemeNotifier();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await NotificationHelper.initialize();

  await AppData().restoreInstance();

  await LocationBackgroundService.initialize();

  runApp(const MyApp());
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
          home: const Splashscreen(),
        );
      },
    );
  }
}
