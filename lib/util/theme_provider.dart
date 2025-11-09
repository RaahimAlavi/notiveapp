import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dynamic_color/dynamic_color.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode;
  int _seedColor;

  bool get isDarkMode => _isDarkMode;
  Color get seedColor => Color(_seedColor);

  ThemeProvider({required bool isDark, required int seed})
    : _isDarkMode = isDark,
      _seedColor = seed;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setSeedColor(int colorValue) async {
    _seedColor = colorValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('colorSeed', colorValue);
    notifyListeners();
  }

  ThemeData getThemeData(ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
    final bool useSystemPalette = _seedColor == Colors.deepPurple.value;

    final ColorScheme lightScheme = (useSystemPalette && lightDynamic != null)
        ? lightDynamic
        : ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.light,
          );

    // This is the light theme
    return ThemeData(
      colorScheme: lightScheme,
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: lightScheme.surface,
        foregroundColor: lightScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lightScheme.primaryContainer,
        foregroundColor: lightScheme.onPrimaryContainer,
      ),
    );
  }

  ThemeData getDarkThemeData(
    ColorScheme? lightDynamic,
    ColorScheme? darkDynamic,
  ) {
    final bool useSystemPalette = _seedColor == Colors.deepPurple.value;

    final ColorScheme darkScheme = (useSystemPalette && darkDynamic != null)
        ? darkDynamic
        : ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.dark,
          );

    // This is the dark theme
    return ThemeData(
      colorScheme: darkScheme,
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkScheme.surface,
        foregroundColor: darkScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkScheme.primaryContainer,
        foregroundColor: darkScheme.onPrimaryContainer,
      ),
    );
  }
}
