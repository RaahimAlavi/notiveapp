import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:notiveapp/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notiveapp/pages/splash_page.dart';
import 'package:provider/provider.dart';
import 'package:notiveapp/util/theme_provider.dart';

Future<void> main() async {
  // 1. Ensure bindings are ready *before* loading anything
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load *only* the theme preferences
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? false;
  final int seed = prefs.getInt('colorSeed') ?? Colors.deepPurple.value;

  // 3. Pass the loaded theme data into MyApp
  runApp(MyApp(isDark: isDark, seed: seed));
}

// 4. MyApp can now be a StatelessWidget
class MyApp extends StatelessWidget {
  final bool isDark;
  final int seed;

  const MyApp({super.key, required this.isDark, required this.seed});

  @override
  Widget build(BuildContext context) {
    // 5. We create the provider *immediately* with the loaded data
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(isDark: isDark, seed: seed),
      child: DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
          // 6. Consume the provider to build the MaterialApp
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
                // 7. The *home* is now the SplashPage.
                home: const SplashPage(),
              );
            },
          );
        },
      ),
    );
  }
}
