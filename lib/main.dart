import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:notiveapp/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notiveapp/pages/splash_page.dart';
import 'package:provider/provider.dart';
import 'package:notiveapp/util/theme_provider.dart';
import 'package:notiveapp/services/notifications_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("🔔 Initializing Notification Service...");

  await NotificationService.init();
  print("✅ Notification Service Initialized!");

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? false;
  final int seed = prefs.getInt('colorSeed') ?? Colors.deepPurple.value;

  runApp(MyApp(isDark: isDark, seed: seed));
}

class MyApp extends StatelessWidget {
  final bool isDark;
  final int seed;

  const MyApp({super.key, required this.isDark, required this.seed});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(isDark: isDark, seed: seed),
      child: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          return Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              final lightTheme = themeProvider.getThemeData(
                lightDynamic,
                darkDynamic,
              );
              final darkTheme = themeProvider.getDarkThemeData(
                lightDynamic,
                darkDynamic,
              );

              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: "Notive",
                themeMode: themeProvider.themeMode,
                theme: lightTheme,
                darkTheme: darkTheme,
                home: const SplashPage(),
              );
            },
          );
        },
      ),
    );
  }
}
