import 'package:field_work/config/data/local/app_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/theme/theme.dart';
import 'features/splash/view/screen/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await AppData().restoreInstance();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    bool isDark = AppData().getIsDarkTheme() ?? false;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Room',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const Splashscreen(),
    );
  }
}
