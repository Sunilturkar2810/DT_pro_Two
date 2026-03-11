import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  static const Color primaryGreen = Color(0xFF20E19F);

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  ThemeData get themeData {
    return _isDarkMode ? _darkTheme : _lightTheme;
  }

  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.light,
      surface: Colors.white,
      onSurface: const Color(0xFF1A1A1A),
    ),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE9ECEF),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryGreen,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.black),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: primaryGreen,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black54,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: const Color(0xFFF8F9FA),
      filled: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen),
      ),
    ),
    extensions: const [AppColors.light],
  );

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.dark,
      surface: const Color(0xFF1E1E2E),
      onSurface: Colors.white,
    ),
    cardColor: const Color(0xFF1E1E2E),
    dividerColor: const Color(0xFF2A2D3E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E2E),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color(0xFF1E1E2E),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E2E),
      selectedItemColor: primaryGreen,
      unselectedItemColor: Colors.white54,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: const Color(0xFF2A2D3E),
      filled: true,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3A3D4E)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen),
      ),
    ),
    extensions: const [AppColors.dark],
  );
}

/// Custom color extension — theme-aware colors har jagah accessible
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color cardBackground;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color toolbarBackground;
  final Color inputBackground;
  final Color chipBackground;
  final Color tableHeaderBackground;
  final Color shadowColor;
  final Color divider;

  const AppColors({
    required this.cardBackground,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.toolbarBackground,
    required this.inputBackground,
    required this.chipBackground,
    required this.tableHeaderBackground,
    required this.shadowColor,
    required this.divider,
  });

  static const AppColors light = AppColors(
    cardBackground: Colors.white,
    cardBorder: Color(0xFFE9ECEF),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF495057),
    textMuted: Color(0xFF868E96),
    toolbarBackground: Colors.white,
    inputBackground: Color(0xFFF8F9FA),
    chipBackground: Colors.white,
    tableHeaderBackground: Color(0xFF1A1D1E),
    shadowColor: Color(0x0A000000),
    divider: Color(0xFFE9ECEF),
  );

  static const AppColors dark = AppColors(
    cardBackground: Color(0xFF1E1E2E),
    cardBorder: Color(0xFF2A2D3E),
    textPrimary: Color(0xFFE9ECEF),
    textSecondary: Color(0xFFADB5BD),
    textMuted: Color(0xFF6C757D),
    toolbarBackground: Color(0xFF252538),
    inputBackground: Color(0xFF2A2D3E),
    chipBackground: Color(0xFF252538),
    tableHeaderBackground: Color(0xFF0D0D1A),
    shadowColor: Color(0x1A000000),
    divider: Color(0xFF2A2D3E),
  );

  @override
  AppColors copyWith({
    Color? cardBackground,
    Color? cardBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? toolbarBackground,
    Color? inputBackground,
    Color? chipBackground,
    Color? tableHeaderBackground,
    Color? shadowColor,
    Color? divider,
  }) {
    return AppColors(
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      toolbarBackground: toolbarBackground ?? this.toolbarBackground,
      inputBackground: inputBackground ?? this.inputBackground,
      chipBackground: chipBackground ?? this.chipBackground,
      tableHeaderBackground: tableHeaderBackground ?? this.tableHeaderBackground,
      shadowColor: shadowColor ?? this.shadowColor,
      divider: divider ?? this.divider,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      toolbarBackground: Color.lerp(toolbarBackground, other.toolbarBackground, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      chipBackground: Color.lerp(chipBackground, other.chipBackground, t)!,
      tableHeaderBackground: Color.lerp(tableHeaderBackground, other.tableHeaderBackground, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}
