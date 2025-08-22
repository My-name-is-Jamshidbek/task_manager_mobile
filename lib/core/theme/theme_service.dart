import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/theme_constants.dart';

enum AppThemeMode { light, dark, system }

/// CoreUI Theme Color Variants
enum AppThemeColor {
  primary, // CoreUI Primary (#5856d6)
  secondary, // CoreUI Secondary (#6b7785)
  success, // CoreUI Success (#1b9e3e)
  danger, // CoreUI Danger (#e55353)
  warning, // CoreUI Warning (#f9b115)
  info, // CoreUI Info (#3399ff)
}

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _themeModeKey = 'theme_mode';
  static const String _themeColorKey = 'theme_color';

  AppThemeMode _themeMode = AppThemeMode.system;
  AppThemeColor _themeColor = AppThemeColor.primary;

  AppThemeMode get themeMode => _themeMode;
  AppThemeColor get themeColor => _themeColor;

  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// Check if current theme is dark mode
  bool get isDarkMode {
    switch (_themeMode) {
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.light:
        return false;
      case AppThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    }
  }

  // Initialize theme service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme mode
    final themeModeString = prefs.getString(_themeModeKey);
    if (themeModeString != null) {
      _themeMode = AppThemeMode.values.firstWhere(
        (mode) => mode.name == themeModeString,
        orElse: () => AppThemeMode.system,
      );
    }

    // Load theme color
    final themeColorString = prefs.getString(_themeColorKey);
    if (themeColorString != null) {
      _themeColor = AppThemeColor.values.firstWhere(
        (color) => color.name == themeColorString,
        orElse: () => AppThemeColor.primary,
      );
    }

    notifyListeners();
  }

  // Change theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
    notifyListeners();
  }

  // Change theme color
  Future<void> setThemeColor(AppThemeColor color) async {
    _themeColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeColorKey, color.name);
    notifyListeners();
  }

  // Get primary color based on selected CoreUI theme color
  Color get primaryColor {
    switch (_themeColor) {
      case AppThemeColor.primary:
        return AppThemeConstants.primary;
      case AppThemeColor.secondary:
        return AppThemeConstants.secondary;
      case AppThemeColor.success:
        return AppThemeConstants.success;
      case AppThemeColor.danger:
        return AppThemeConstants.danger;
      case AppThemeColor.warning:
        return AppThemeConstants.warning;
      case AppThemeColor.info:
        return AppThemeConstants.info;
    }
  }

  // Get secondary color based on selected CoreUI theme color
  Color get secondaryColor {
    switch (_themeColor) {
      case AppThemeColor.primary:
        return AppThemeConstants.primaryLight;
      case AppThemeColor.secondary:
        return AppThemeConstants.secondaryLight;
      case AppThemeColor.success:
        return AppThemeConstants.successLight;
      case AppThemeColor.danger:
        return AppThemeConstants.dangerLight;
      case AppThemeColor.warning:
        return AppThemeConstants.warningLight;
      case AppThemeColor.info:
        return AppThemeConstants.infoLight;
    }
  }

  // Generate CoreUI light theme
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: AppThemeConstants.lightSurface,
        surfaceVariant: AppThemeConstants.lightSurfaceVariant,
        background: AppThemeConstants.lightBackground,
        onSurface: AppThemeConstants.lightOnSurface,
        onSurfaceVariant: AppThemeConstants.lightOnSurfaceVariant,
        onBackground: AppThemeConstants.lightOnBackground,
        error: AppThemeConstants.danger,
        onError: AppThemeConstants.white,
      ),

      // CoreUI App Bar Theme
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: AppThemeConstants.elevationSM,
        backgroundColor: AppThemeConstants.lightSurface,
        foregroundColor: AppThemeConstants.lightOnSurface,
        surfaceTintColor: primaryColor,
        toolbarHeight: AppThemeConstants.appBarHeight,
        titleTextStyle: TextStyle(
          fontSize: AppThemeConstants.fontSizeLG,
          fontWeight: AppThemeConstants.fontWeightSemiBold,
          color: AppThemeConstants.lightOnSurface,
          fontFamily: AppThemeConstants.primaryFontFamily,
          inherit: true,
        ),
        iconTheme: IconThemeData(
          color: AppThemeConstants.lightOnSurface,
          size: AppThemeConstants.iconSizeLG,
        ),
      ),

      // CoreUI Card Theme
      cardTheme: CardThemeData(
        elevation: AppThemeConstants.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppThemeConstants.cardBorderRadius,
          ),
        ),
        color: AppThemeConstants.lightSurface,
        surfaceTintColor: primaryColor,
        shadowColor: AppThemeConstants.gray300,
      ),

      // CoreUI Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: AppThemeConstants.elevationSM,
          backgroundColor: primaryColor,
          foregroundColor: AppThemeConstants.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeConstants.radiusLG),
          ),
          minimumSize: Size(0, AppThemeConstants.buttonHeightMD),
          padding: EdgeInsets.symmetric(
            horizontal: AppThemeConstants.spaceLG,
            vertical: AppThemeConstants.spaceMD,
          ),
          textStyle: TextStyle(
            fontSize: AppThemeConstants.fontSizeMD,
            fontWeight: AppThemeConstants.fontWeightSemiBold,
            fontFamily: AppThemeConstants.primaryFontFamily,
            inherit: true,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeConstants.radiusLG),
          ),
          minimumSize: Size(0, AppThemeConstants.buttonHeightMD),
          padding: EdgeInsets.symmetric(
            horizontal: AppThemeConstants.spaceLG,
            vertical: AppThemeConstants.spaceMD,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeConstants.radiusLG),
          ),
          minimumSize: Size(0, AppThemeConstants.buttonHeightMD),
          padding: EdgeInsets.symmetric(
            horizontal: AppThemeConstants.spaceLG,
            vertical: AppThemeConstants.spaceMD,
          ),
        ),
      ),

      // CoreUI Input Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeConstants.radiusLG),
          borderSide: BorderSide(color: AppThemeConstants.gray300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeConstants.radiusLG),
          borderSide: BorderSide(color: AppThemeConstants.gray300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeConstants.radiusLG),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeConstants.radiusLG),
          borderSide: BorderSide(color: AppThemeConstants.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeConstants.radiusLG),
          borderSide: BorderSide(color: AppThemeConstants.danger, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppThemeConstants.spaceLG,
          vertical: AppThemeConstants.spaceMD,
        ),
        filled: true,
        fillColor: AppThemeConstants.lightSurface,
        hintStyle: TextStyle(
          color: AppThemeConstants.gray500,
          fontSize: AppThemeConstants.fontSizeMD,
        ),
        labelStyle: TextStyle(
          color: AppThemeConstants.gray600,
          fontSize: AppThemeConstants.fontSizeMD,
        ),
      ),

      // CoreUI FAB Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: AppThemeConstants.white,
        elevation: AppThemeConstants.elevationMD,
        focusElevation: AppThemeConstants.elevationLG,
        hoverElevation: AppThemeConstants.elevationLG,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeConstants.radiusXL),
        ),
      ),

      // CoreUI Bottom Navigation Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppThemeConstants.lightSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: AppThemeConstants.gray600,
        type: BottomNavigationBarType.fixed,
        elevation: AppThemeConstants.elevationLG,
        selectedLabelStyle: TextStyle(
          fontSize: AppThemeConstants.fontSizeSM,
          fontWeight: AppThemeConstants.fontWeightMedium,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: AppThemeConstants.fontSizeSM,
          fontWeight: AppThemeConstants.fontWeightRegular,
        ),
      ),

      // CoreUI Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppThemeConstants.lightSurface,
        elevation: AppThemeConstants.dialogElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppThemeConstants.dialogBorderRadius,
          ),
        ),
        titleTextStyle: TextStyle(
          fontSize: AppThemeConstants.fontSizeH5,
          fontWeight: AppThemeConstants.fontWeightSemiBold,
          color: AppThemeConstants.lightOnSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: AppThemeConstants.fontSizeMD,
          color: AppThemeConstants.lightOnSurface,
        ),
      ),

      // CoreUI Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppThemeConstants.dark,
        contentTextStyle: TextStyle(
          color: AppThemeConstants.white,
          fontSize: AppThemeConstants.fontSizeMD,
          fontFamily: AppThemeConstants.primaryFontFamily,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppThemeConstants.snackBarBorderRadius,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: AppThemeConstants.elevationMD,
      ),

      // CoreUI Divider Theme
      dividerTheme: DividerThemeData(
        thickness: AppThemeConstants.dividerThickness,
        indent: AppThemeConstants.dividerIndent,
        endIndent: AppThemeConstants.dividerIndent,
        color: AppThemeConstants.gray300,
        space: AppThemeConstants.spaceLG,
      ),

      // CoreUI Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: AppThemeConstants.fontSizeH1,
          fontWeight: AppThemeConstants.fontWeightBold,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.lightOnSurface,
          height: AppThemeConstants.lineHeightSM,
          inherit: true,
        ),
        displayMedium: TextStyle(
          fontSize: AppThemeConstants.fontSizeH2,
          fontWeight: AppThemeConstants.fontWeightBold,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.lightOnSurface,
          height: AppThemeConstants.lineHeightSM,
          inherit: true,
        ),
        displaySmall: TextStyle(
          fontSize: AppThemeConstants.fontSizeH3,
          fontWeight: AppThemeConstants.fontWeightBold,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.lightOnSurface,
          height: AppThemeConstants.lineHeightSM,
          inherit: true,
        ),
        headlineLarge: TextStyle(
          fontSize: AppThemeConstants.fontSizeH4,
          fontWeight: AppThemeConstants.fontWeightSemiBold,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.lightOnSurface,
          height: AppThemeConstants.lineHeightMD,
          inherit: true,
        ),
        headlineMedium: TextStyle(
          fontSize: AppThemeConstants.fontSizeH5,
          fontWeight: AppThemeConstants.fontWeightSemiBold,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.lightOnSurface,
          height: AppThemeConstants.lineHeightMD,
          inherit: true,
        ),
        headlineSmall: TextStyle(
          fontSize: AppThemeConstants.fontSizeH6,
          fontWeight: AppThemeConstants.fontWeightSemiBold,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.lightOnSurface,
          height: AppThemeConstants.lineHeightMD,
          inherit: true,
        ),
        titleLarge: TextStyle(
          fontSize: AppThemeConstants.fontSizeLG,
          fontWeight: AppThemeConstants.fontWeightMedium,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.lightOnSurface,
          height: AppThemeConstants.lineHeightMD,
          inherit: true,
        ),
        titleMedium: TextStyle(
          fontSize: AppThemeConstants.fontSizeMD,
          fontWeight: AppThemeConstants.fontWeightMedium,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.lightOnSurface,
          height: AppThemeConstants.lineHeightMD,
          inherit: true,
        ),
        titleSmall: TextStyle(
          fontSize: AppThemeConstants.fontSizeSM,
          fontWeight: AppThemeConstants.fontWeightMedium,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.lightOnSurface,
          height: AppThemeConstants.lineHeightMD,
          inherit: true,
        ),
        bodyLarge: TextStyle(
          fontSize: AppThemeConstants.fontSizeLG,
          fontWeight: AppThemeConstants.fontWeightRegular,
          fontFamily: AppThemeConstants.secondaryFontFamily,
          color: AppThemeConstants.lightOnSurface,
          height: AppThemeConstants.lineHeightMD,
          inherit: true,
        ),
        bodyMedium: TextStyle(
          fontSize: AppThemeConstants.fontSizeMD,
          fontWeight: AppThemeConstants.fontWeightRegular,
          fontFamily: AppThemeConstants.secondaryFontFamily,
          color: AppThemeConstants.lightOnSurface,
          height: AppThemeConstants.lineHeightMD,
          inherit: true,
        ),
        bodySmall: TextStyle(
          fontSize: AppThemeConstants.fontSizeSM,
          fontWeight: AppThemeConstants.fontWeightRegular,
          fontFamily: AppThemeConstants.secondaryFontFamily,
          color: AppThemeConstants.lightOnSurfaceVariant,
          height: AppThemeConstants.lineHeightMD,
          inherit: true,
        ),
        labelLarge: TextStyle(
          fontSize: AppThemeConstants.fontSizeMD,
          fontWeight: AppThemeConstants.fontWeightMedium,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.lightOnSurface,
          height: AppThemeConstants.lineHeightSM,
          inherit: true,
        ),
        labelMedium: TextStyle(
          fontSize: AppThemeConstants.fontSizeSM,
          fontWeight: AppThemeConstants.fontWeightMedium,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.lightOnSurfaceVariant,
          height: AppThemeConstants.lineHeightSM,
          inherit: true,
        ),
        labelSmall: TextStyle(
          fontSize: AppThemeConstants.fontSizeXS,
          fontWeight: AppThemeConstants.fontWeightMedium,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.lightOnSurfaceVariant,
          height: AppThemeConstants.lineHeightSM,
          inherit: true,
        ),
      ),

      // CoreUI Icon Theme
      iconTheme: IconThemeData(
        color: AppThemeConstants.lightOnSurface,
        size: AppThemeConstants.iconSizeLG,
      ),

      // CoreUI Primary Icon Theme
      primaryIconTheme: IconThemeData(
        color: primaryColor,
        size: AppThemeConstants.iconSizeLG,
      ),
    );
  }

  // Generate CoreUI dark theme
  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: AppThemeConstants.darkSurface,
        surfaceVariant: AppThemeConstants.darkSurfaceVariant,
        background: AppThemeConstants.darkBackground,
        onSurface: AppThemeConstants.darkOnSurface,
        onSurfaceVariant: AppThemeConstants.darkOnSurfaceVariant,
        onBackground: AppThemeConstants.darkOnBackground,
        error: AppThemeConstants.danger,
        onError: AppThemeConstants.white,
      ),

      // CoreUI App Bar Theme (Dark)
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: AppThemeConstants.elevationSM,
        backgroundColor: AppThemeConstants.darkSurface,
        foregroundColor: AppThemeConstants.darkOnSurface,
        surfaceTintColor: primaryColor,
        toolbarHeight: AppThemeConstants.appBarHeight,
        titleTextStyle: TextStyle(
          fontSize: AppThemeConstants.fontSizeLG,
          fontWeight: AppThemeConstants.fontWeightSemiBold,
          color: AppThemeConstants.darkOnSurface,
          fontFamily: AppThemeConstants.primaryFontFamily,
          inherit: true,
        ),
        iconTheme: IconThemeData(
          color: AppThemeConstants.darkOnSurface,
          size: AppThemeConstants.iconSizeLG,
        ),
      ),

      // CoreUI Card Theme (Dark)
      cardTheme: CardThemeData(
        elevation: AppThemeConstants.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppThemeConstants.cardBorderRadius,
          ),
        ),
        color: AppThemeConstants.darkSurface,
        surfaceTintColor: primaryColor,
        shadowColor: AppThemeConstants.black.withOpacity(0.3),
      ),

      // CoreUI Button Themes (Dark)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: AppThemeConstants.elevationSM,
          backgroundColor: primaryColor,
          foregroundColor: AppThemeConstants.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeConstants.radiusLG),
          ),
          minimumSize: Size(0, AppThemeConstants.buttonHeightMD),
          padding: EdgeInsets.symmetric(
            horizontal: AppThemeConstants.spaceLG,
            vertical: AppThemeConstants.spaceMD,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeConstants.radiusLG),
          ),
          minimumSize: Size(0, AppThemeConstants.buttonHeightMD),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeConstants.radiusLG),
          ),
          minimumSize: Size(0, AppThemeConstants.buttonHeightMD),
        ),
      ),

      // CoreUI Input Theme (Dark)
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeConstants.radiusLG),
          borderSide: BorderSide(color: AppThemeConstants.gray600, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeConstants.radiusLG),
          borderSide: BorderSide(color: AppThemeConstants.gray600, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeConstants.radiusLG),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeConstants.radiusLG),
          borderSide: BorderSide(color: AppThemeConstants.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeConstants.radiusLG),
          borderSide: BorderSide(color: AppThemeConstants.danger, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppThemeConstants.spaceLG,
          vertical: AppThemeConstants.spaceMD,
        ),
        filled: true,
        fillColor: AppThemeConstants.darkSurface,
        hintStyle: TextStyle(
          color: AppThemeConstants.gray400,
          fontSize: AppThemeConstants.fontSizeMD,
          inherit: true,
        ),
        labelStyle: TextStyle(
          color: AppThemeConstants.gray300,
          fontSize: AppThemeConstants.fontSizeMD,
          inherit: true,
        ),
      ),

      // CoreUI Text Theme (Dark)
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: AppThemeConstants.fontSizeH1,
          fontWeight: AppThemeConstants.fontWeightBold,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.darkOnSurface,
          height: AppThemeConstants.lineHeightSM,
          inherit: true,
        ),
        displayMedium: TextStyle(
          fontSize: AppThemeConstants.fontSizeH2,
          fontWeight: AppThemeConstants.fontWeightBold,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.darkOnSurface,
          height: AppThemeConstants.lineHeightSM,
          inherit: true,
        ),
        displaySmall: TextStyle(
          fontSize: AppThemeConstants.fontSizeH3,
          fontWeight: AppThemeConstants.fontWeightBold,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.darkOnSurface,
          height: AppThemeConstants.lineHeightSM,
          inherit: true,
        ),
        headlineLarge: TextStyle(
          fontSize: AppThemeConstants.fontSizeH4,
          fontWeight: AppThemeConstants.fontWeightSemiBold,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.darkOnSurface,
          height: AppThemeConstants.lineHeightMD,
          inherit: true,
        ),
        headlineMedium: TextStyle(
          fontSize: AppThemeConstants.fontSizeH5,
          fontWeight: AppThemeConstants.fontWeightSemiBold,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.darkOnSurface,
          height: AppThemeConstants.lineHeightMD,
          inherit: true,
        ),
        headlineSmall: TextStyle(
          fontSize: AppThemeConstants.fontSizeH6,
          fontWeight: AppThemeConstants.fontWeightSemiBold,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.darkOnSurface,
          height: AppThemeConstants.lineHeightMD,
          inherit: true,
        ),
        titleLarge: TextStyle(
          fontSize: AppThemeConstants.fontSizeLG,
          fontWeight: AppThemeConstants.fontWeightMedium,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.darkOnSurface,
          height: AppThemeConstants.lineHeightMD,
          inherit: true,
        ),
        titleMedium: TextStyle(
          fontSize: AppThemeConstants.fontSizeMD,
          fontWeight: AppThemeConstants.fontWeightMedium,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.darkOnSurface,
          height: AppThemeConstants.lineHeightMD,
          inherit: true,
        ),
        titleSmall: TextStyle(
          fontSize: AppThemeConstants.fontSizeSM,
          fontWeight: AppThemeConstants.fontWeightMedium,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.darkOnSurface,
          height: AppThemeConstants.lineHeightMD,
          inherit: true,
        ),
        bodyLarge: TextStyle(
          fontSize: AppThemeConstants.fontSizeLG,
          fontWeight: AppThemeConstants.fontWeightRegular,
          fontFamily: AppThemeConstants.secondaryFontFamily,
          color: AppThemeConstants.darkOnSurface,
          height: AppThemeConstants.lineHeightMD,
          inherit: true,
        ),
        bodyMedium: TextStyle(
          fontSize: AppThemeConstants.fontSizeMD,
          fontWeight: AppThemeConstants.fontWeightRegular,
          fontFamily: AppThemeConstants.secondaryFontFamily,
          color: AppThemeConstants.darkOnSurface,
          height: AppThemeConstants.lineHeightMD,
          inherit: true,
        ),
        bodySmall: TextStyle(
          fontSize: AppThemeConstants.fontSizeSM,
          fontWeight: AppThemeConstants.fontWeightRegular,
          fontFamily: AppThemeConstants.secondaryFontFamily,
          color: AppThemeConstants.darkOnSurfaceVariant,
          height: AppThemeConstants.lineHeightMD,
          inherit: true,
        ),
        labelLarge: TextStyle(
          fontSize: AppThemeConstants.fontSizeMD,
          fontWeight: AppThemeConstants.fontWeightMedium,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.darkOnSurface,
          height: AppThemeConstants.lineHeightSM,
          inherit: true,
        ),
        labelMedium: TextStyle(
          fontSize: AppThemeConstants.fontSizeSM,
          fontWeight: AppThemeConstants.fontWeightMedium,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.darkOnSurfaceVariant,
          height: AppThemeConstants.lineHeightSM,
          inherit: true,
        ),
        labelSmall: TextStyle(
          fontSize: AppThemeConstants.fontSizeXS,
          fontWeight: AppThemeConstants.fontWeightMedium,
          fontFamily: AppThemeConstants.primaryFontFamily,
          color: AppThemeConstants.darkOnSurfaceVariant,
          height: AppThemeConstants.lineHeightSM,
          inherit: true,
        ),
      ),

      // CoreUI FAB Theme (Dark)
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: AppThemeConstants.white,
        elevation: AppThemeConstants.elevationMD,
        focusElevation: AppThemeConstants.elevationLG,
        hoverElevation: AppThemeConstants.elevationLG,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeConstants.radiusXL),
        ),
      ),

      // CoreUI Bottom Navigation Theme (Dark)
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppThemeConstants.darkSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: AppThemeConstants.gray400,
        type: BottomNavigationBarType.fixed,
        elevation: AppThemeConstants.elevationLG,
      ),

      // CoreUI Dialog Theme (Dark)
      dialogTheme: DialogThemeData(
        backgroundColor: AppThemeConstants.darkSurface,
        elevation: AppThemeConstants.dialogElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppThemeConstants.dialogBorderRadius,
          ),
        ),
      ),

      // CoreUI Snack Bar Theme (Dark)
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppThemeConstants.gray900,
        contentTextStyle: TextStyle(
          color: AppThemeConstants.white,
          fontSize: AppThemeConstants.fontSizeMD,
          inherit: true,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppThemeConstants.snackBarBorderRadius,
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // CoreUI Divider Theme (Dark)
      dividerTheme: DividerThemeData(
        thickness: AppThemeConstants.dividerThickness,
        color: AppThemeConstants.gray600,
      ),

      // CoreUI Icon Theme (Dark)
      iconTheme: IconThemeData(
        color: AppThemeConstants.darkOnSurface,
        size: AppThemeConstants.iconSizeLG,
      ),

      primaryIconTheme: IconThemeData(
        color: primaryColor,
        size: AppThemeConstants.iconSizeLG,
      ),
    );
  }

  // Get available CoreUI theme colors for UI
  List<Map<String, dynamic>> get availableThemeColors {
    return [
      {
        'name': 'Primary',
        'color': AppThemeConstants.primary,
        'value': AppThemeColor.primary,
        'description': 'CoreUI Primary Purple',
      },
      {
        'name': 'Secondary',
        'color': AppThemeConstants.secondary,
        'value': AppThemeColor.secondary,
        'description': 'CoreUI Secondary Gray',
      },
      {
        'name': 'Success',
        'color': AppThemeConstants.success,
        'value': AppThemeColor.success,
        'description': 'CoreUI Success Green',
      },
      {
        'name': 'Danger',
        'color': AppThemeConstants.danger,
        'value': AppThemeColor.danger,
        'description': 'CoreUI Danger Red',
      },
      {
        'name': 'Warning',
        'color': AppThemeConstants.warning,
        'value': AppThemeColor.warning,
        'description': 'CoreUI Warning Yellow',
      },
      {
        'name': 'Info',
        'color': AppThemeConstants.info,
        'value': AppThemeColor.info,
        'description': 'CoreUI Info Blue',
      },
    ];
  }

  // Get available theme modes for UI
  List<Map<String, dynamic>> get availableThemeModes {
    return [
      {
        'name': 'Light',
        'icon': Icons.light_mode,
        'value': AppThemeMode.light,
        'description': 'Always use light theme',
      },
      {
        'name': 'Dark',
        'icon': Icons.dark_mode,
        'value': AppThemeMode.dark,
        'description': 'Always use dark theme',
      },
      {
        'name': 'System',
        'icon': Icons.brightness_auto,
        'value': AppThemeMode.system,
        'description': 'Follow system setting',
      },
    ];
  }

  /// Get current theme name for display
  String get currentThemeName {
    switch (_themeColor) {
      case AppThemeColor.primary:
        return 'Primary';
      case AppThemeColor.secondary:
        return 'Secondary';
      case AppThemeColor.success:
        return 'Success';
      case AppThemeColor.danger:
        return 'Danger';
      case AppThemeColor.warning:
        return 'Warning';
      case AppThemeColor.info:
        return 'Info';
    }
  }

  /// Get current theme mode name for display
  String get currentThemeModeName {
    switch (_themeMode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }
}
