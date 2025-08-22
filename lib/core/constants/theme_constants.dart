import 'package:flutter/material.dart';

/// CoreUI Design System Constants
/// Based on CoreUI v5.3 Free Bootstrap theme
/// https://coreui.io/demos/bootstrap/5.3/free/typography.html
class AppThemeConstants {
  // Private constructor to prevent instantiation
  AppThemeConstants._();

  // ===== COREUI BRAND COLORS =====

  /// Brand Primary Color - CoreUI Primary
  /// HEX: #5856d6 | RGB: rgb(88, 86, 214)
  static const Color primary = Color(0xFF5856D6);

  /// Brand Secondary Color - CoreUI Secondary  
  /// HEX: #6b7785 | RGB: rgb(107, 119, 133)
  static const Color secondary = Color(0xFF6B7785);

  /// Brand Success Color - CoreUI Success
  /// HEX: #1b9e3e | RGB: rgb(27, 158, 62)
  static const Color success = Color(0xFF1B9E3E);

  /// Brand Danger Color - CoreUI Danger
  /// HEX: #e55353 | RGB: rgb(229, 83, 83)
  static const Color danger = Color(0xFFE55353);

  /// Brand Warning Color - CoreUI Warning
  /// HEX: #f9b115 | RGB: rgb(249, 177, 21)
  static const Color warning = Color(0xFFF9B115);

  /// Brand Info Color - CoreUI Info
  /// HEX: #3399ff | RGB: rgb(51, 153, 255)
  static const Color info = Color(0xFF3399FF);

  /// Brand Light Color - CoreUI Light
  /// HEX: #f3f4f7 | RGB: rgb(243, 244, 247)
  static const Color light = Color(0xFFF3F4F7);

  /// Brand Dark Color - CoreUI Dark
  /// HEX: #212631 | RGB: rgb(33, 38, 49)
  static const Color dark = Color(0xFF212631);

  // ===== COREUI SEMANTIC COLORS =====

  // Aliases for better semantic understanding
  static const Color error = danger;
  static const Color positive = success;
  static const Color negative = danger;
  static const Color neutral = secondary;

  // ===== COREUI VARIATIONS =====

  // Primary variations
  static const Color primaryLight = Color(0xFF7E7AEC);
  static const Color primaryDark = Color(0xFF4340C0);
  static const Color primaryLighter = Color(0xFF9B98F2);
  static const Color primaryDarker = Color(0xFF322FAA);

  // Secondary variations
  static const Color secondaryLight = Color(0xFF8A949F);
  static const Color secondaryDark = Color(0xFF565E6B);
  static const Color secondaryLighter = Color(0xFFA9B1B9);
  static const Color secondaryDarker = Color(0xFF414551);

  // Success variations
  static const Color successLight = Color(0xFF4AB565);
  static const Color successDark = Color(0xFF168731);
  static const Color successLighter = Color(0xFF6BC481);
  static const Color successDarker = Color(0xFF117024);

  // Danger variations
  static const Color dangerLight = Color(0xFFE97575);
  static const Color dangerDark = Color(0xFFE03131);
  static const Color dangerLighter = Color(0xFFEE9797);
  static const Color dangerDarker = Color(0xFFDB0F0F);

  // Warning variations
  static const Color warningLight = Color(0xFFFAC441);
  static const Color warningDark = Color(0xFFF79E00);
  static const Color warningLighter = Color(0xFFFBD16D);
  static const Color warningDarker = Color(0xFFF58C00);

  // Info variations
  static const Color infoLight = Color(0xFF5CB3FF);
  static const Color infoDark = Color(0xFF1A7FE6);
  static const Color infoLighter = Color(0xFF85CCFF);
  static const Color infoDarker = Color(0xFF0066CC);

  // ===== NEUTRAL PALETTE =====

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // CoreUI Gray Scale
  static const Color gray100 = Color(0xFFF8F9FA);
  static const Color gray200 = Color(0xFFE9ECEF);
  static const Color gray300 = Color(0xFFDEE2E6);
  static const Color gray400 = Color(0xFFCED4DA);
  static const Color gray500 = Color(0xFFADB5BD);
  static const Color gray600 = Color(0xFF6C757D);
  static const Color gray700 = Color(0xFF495057);
  static const Color gray800 = Color(0xFF343A40);
  static const Color gray900 = Color(0xFF212529);

  // Aliases for compatibility
  static const Color grey100 = gray100;
  static const Color grey200 = gray200;
  static const Color grey300 = gray300;
  static const Color grey400 = gray400;
  static const Color grey500 = gray500;
  static const Color grey600 = gray600;
  static const Color grey700 = gray700;
  static const Color grey800 = gray800;
  static const Color grey900 = gray900;

  // ===== TASK-SPECIFIC COLORS =====

  // Task Priority Colors using CoreUI palette
  static const Color priorityLow = success; // Green
  static const Color priorityMedium = warning; // Orange/Yellow
  static const Color priorityHigh = danger; // Red
  static const Color priorityUrgent = primary; // Purple

  // Task Status Colors using CoreUI palette
  static const Color statusPending = secondary; // Gray
  static const Color statusInProgress = info; // Blue
  static const Color statusCompleted = success; // Green
  static const Color statusCancelled = danger; // Red

  // ===== COREUI GRADIENTS =====

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, successDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [warning, warningDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [danger, dangerDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient infoGradient = LinearGradient(
    colors: [info, infoDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Alias for error gradient
  static const LinearGradient errorGradient = dangerGradient;

  // ===== COREUI TYPOGRAPHY =====

  // CoreUI uses system fonts with fallbacks
  static const String primaryFontFamily = 'SF Pro Display'; // iOS
  static const String secondaryFontFamily = 'Roboto'; // Android
  static const String monospaceFontFamily = 'SF Mono'; // Code/Monospace

  // CoreUI Font Weights
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w800;

  // CoreUI Font Sizes (Bootstrap-based scale)
  static const double fontSizeXS = 11.0; // .75rem
  static const double fontSizeSM = 13.0; // .875rem
  static const double fontSizeMD = 14.0; // 1rem (base)
  static const double fontSizeLG = 16.0; // 1.125rem
  static const double fontSizeXL = 18.0; // 1.25rem
  static const double fontSize2XL = 20.0; // 1.5rem
  static const double fontSize3XL = 24.0; // 1.75rem
  static const double fontSize4XL = 32.0; // 2.25rem
  static const double fontSize5XL = 48.0; // 3rem

  // CoreUI Heading Sizes
  static const double fontSizeH1 = 40.0; // 2.5rem
  static const double fontSizeH2 = 32.0; // 2rem
  static const double fontSizeH3 = 28.0; // 1.75rem
  static const double fontSizeH4 = 24.0; // 1.5rem
  static const double fontSizeH5 = 20.0; // 1.25rem
  static const double fontSizeH6 = 16.0; // 1rem

  // CoreUI Line Heights
  static const double lineHeightSM = 1.25;
  static const double lineHeightMD = 1.5;
  static const double lineHeightLG = 1.75;
  static const double lineHeightXL = 2.0;

  // ===== COREUI SPACING SYSTEM =====
  // Based on Bootstrap 5 spacing scale (0.25rem increments)

  static const double space0 = 0.0; // 0rem
  static const double space1 = 4.0; // 0.25rem
  static const double space2 = 8.0; // 0.5rem
  static const double space3 = 12.0; // 0.75rem
  static const double space4 = 16.0; // 1rem
  static const double space5 = 20.0; // 1.25rem
  static const double space6 = 24.0; // 1.5rem
  static const double space8 = 32.0; // 2rem
  static const double space10 = 40.0; // 2.5rem
  static const double space12 = 48.0; // 3rem
  static const double space16 = 64.0; // 4rem
  static const double space20 = 80.0; // 5rem
  static const double space24 = 96.0; // 6rem

  // Semantic spacing aliases
  static const double spaceXS = space1; // 4.0
  static const double spaceSM = space2; // 8.0
  static const double spaceMD = space3; // 12.0
  static const double spaceLG = space4; // 16.0
  static const double spaceXL = space6; // 24.0
  static const double space2XL = space8; // 32.0
  static const double space3XL = space12; // 48.0
  static const double space4XL = space16; // 64.0

  // ===== COREUI BORDER RADIUS =====
  // Bootstrap 5 border radius system

  static const double radiusNone = 0.0;
  static const double radiusSM = 2.0; // 0.125rem
  static const double radiusMD = 4.0; // 0.25rem
  static const double radiusLG = 6.0; // 0.375rem
  static const double radiusXL = 8.0; // 0.5rem
  static const double radius2XL = 12.0; // 0.75rem
  static const double radius3XL = 16.0; // 1rem
  static const double radiusFull = 9999.0; // pill shape

  // Semantic radius aliases
  static const double radiusXS = radiusSM;

  // ===== COREUI SHADOWS =====
  // Bootstrap 5 box-shadow system

  static const double elevationNone = 0.0;
  static const double elevationSM = 1.0; // Small shadow
  static const double elevationMD = 3.0; // Regular shadow
  static const double elevationLG = 6.0; // Large shadow
  static const double elevationXL = 10.0; // Extra large shadow
  static const double elevation2XL = 15.0; // 2x large shadow
  static const double elevation3XL = 25.0; // 3x large shadow

  // Semantic elevation aliases
  static const double elevationXS = elevationSM;

  // ===== COREUI COMPONENT SIZES =====

  // Button Heights (Bootstrap-based)
  static const double buttonHeightSM = 31.0; // .btn-sm
  static const double buttonHeightMD = 38.0; // .btn
  static const double buttonHeightLG = 48.0; // .btn-lg

  // Input Field Heights (Form control sizes)
  static const double inputHeightSM = 31.0; // .form-control-sm
  static const double inputHeightMD = 38.0; // .form-control
  static const double inputHeightLG = 48.0; // .form-control-lg

  // Icon Sizes (CoreUI icon system)
  static const double iconSizeXS = 12.0;
  static const double iconSizeSM = 16.0;
  static const double iconSizeMD = 20.0;
  static const double iconSizeLG = 24.0;
  static const double iconSizeXL = 32.0;
  static const double iconSize2XL = 40.0;
  static const double iconSize3XL = 48.0;

  // Avatar Sizes (User profile pictures)
  static const double avatarSizeSM = 24.0;
  static const double avatarSizeMD = 32.0;
  static const double avatarSizeLG = 40.0;
  static const double avatarSizeXL = 48.0;
  static const double avatarSize2XL = 64.0;
  static const double avatarSize3XL = 96.0;

  // ===== COREUI ANIMATION SYSTEM =====

  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationSlower = Duration(milliseconds: 750);

  // ===== COREUI BREAKPOINTS =====
  // Bootstrap 5 responsive breakpoints

  static const double breakpointXS = 0.0; // <576px
  static const double breakpointSM = 576.0; // ≥576px
  static const double breakpointMD = 768.0; // ≥768px
  static const double breakpointLG = 992.0; // ≥992px
  static const double breakpointXL = 1200.0; // ≥1200px
  static const double breakpoint2XL = 1400.0; // ≥1400px

  // ===== COREUI OPACITY SYSTEM =====

  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.6;
  static const double opacityHigh = 0.87;
  static const double opacityFull = 1.0;

  // ===== COREUI COMPONENT CONSTANTS =====

  // App Bar / Header
  static const double appBarHeight = 56.0;
  static const double appBarHeightLarge = 64.0;

  // Navigation
  static const double bottomNavHeight = 60.0;
  static const double sidebarWidth = 256.0;
  static const double sidebarWidthCollapsed = 56.0;

  // Floating Action Button
  static const double fabSize = 56.0;
  static const double fabSizeSmall = 40.0;
  static const double fabSizeLarge = 96.0;

  // Card Component
  static const double cardElevation = elevationSM;
  static const double cardBorderRadius = radiusLG;

  // Dialog Component
  static const double dialogBorderRadius = radiusXL;
  static const double dialogElevation = elevation2XL;

  // Snack Bar
  static const double snackBarBorderRadius = radiusMD;

  // Divider
  static const double dividerThickness = 1.0;
  static const double dividerIndent = spaceLG;

  // ===== COREUI SURFACE COLORS =====

  // Light Theme Surface Colors
  static const Color lightSurface = white;
  static const Color lightSurfaceVariant = gray100;
  static const Color lightBackground = gray100;
  static const Color lightOnSurface = gray900;
  static const Color lightOnSurfaceVariant = gray600;
  static const Color lightOnBackground = gray900;

  // Dark Theme Surface Colors  
  static const Color darkSurface = gray800;
  static const Color darkSurfaceVariant = gray700;
  static const Color darkBackground = gray900;
  static const Color darkOnSurface = gray100;
  static const Color darkOnSurfaceVariant = gray300;
  static const Color darkOnBackground = gray100;

  // ===== COREUI THEME VARIANTS =====
  // Updated theme colors map to use CoreUI semantic colors

  static const Map<String, Color> themeColors = {
    'primary': primary,
    'secondary': secondary,
    'success': success,
    'danger': danger,
    'warning': warning,
    'info': info,
    'light': light,
    'dark': dark,
  };

  // ===== COREUI HELPER METHODS =====

  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Get responsive font size based on CoreUI breakpoints
  static double getResponsiveFontSize(double screenWidth, double baseFontSize) {
    if (screenWidth < breakpointSM) {
      return baseFontSize * 0.9; // Small screens
    } else if (screenWidth < breakpointMD) {
      return baseFontSize; // Medium screens
    } else if (screenWidth < breakpointLG) {
      return baseFontSize * 1.1; // Large screens
    } else {
      return baseFontSize * 1.2; // Extra large screens
    }
  }

  /// Get responsive spacing based on CoreUI breakpoints
  static double getResponsiveSpacing(double screenWidth, double baseSpacing) {
    if (screenWidth < breakpointSM) {
      return baseSpacing * 0.8; // Smaller spacing on mobile
    } else if (screenWidth < breakpointMD) {
      return baseSpacing; // Base spacing on tablets
    } else if (screenWidth < breakpointLG) {
      return baseSpacing * 1.2; // Larger spacing on desktop
    } else {
      return baseSpacing * 1.4; // Extra large spacing on wide screens
    }
  }

  /// Get CoreUI semantic color by name
  static Color getSemanticColor(String semanticName) {
    switch (semanticName.toLowerCase()) {
      case 'primary':
        return primary;
      case 'secondary':
        return secondary;
      case 'success':
        return success;
      case 'danger':
      case 'error':
        return danger;
      case 'warning':
        return warning;
      case 'info':
        return info;
      case 'light':
        return light;
      case 'dark':
        return dark;
      default:
        return primary;
    }
  }

  /// Get CoreUI color variation (light/dark)
  static Color getColorVariation(Color baseColor, String variation) {
    if (baseColor == primary) {
      switch (variation) {
        case 'light':
          return primaryLight;
        case 'dark':
          return primaryDark;
        case 'lighter':
          return primaryLighter;
        case 'darker':
          return primaryDarker;
        default:
          return baseColor;
      }
    } else if (baseColor == success) {
      switch (variation) {
        case 'light':
          return successLight;
        case 'dark':
          return successDark;
        case 'lighter':
          return successLighter;
        case 'darker':
          return successDarker;
        default:
          return baseColor;
      }
    } else if (baseColor == danger) {
      switch (variation) {
        case 'light':
          return dangerLight;
        case 'dark':
          return dangerDark;
        case 'lighter':
          return dangerLighter;
        case 'darker':
          return dangerDarker;
        default:
          return baseColor;
      }
    } else if (baseColor == warning) {
      switch (variation) {
        case 'light':
          return warningLight;
        case 'dark':
          return warningDark;
        case 'lighter':
          return warningLighter;
        case 'darker':
          return warningDarker;
        default:
          return baseColor;
      }
    } else if (baseColor == info) {
      switch (variation) {
        case 'light':
          return infoLight;
        case 'dark':
          return infoDark;
        case 'lighter':
          return infoLighter;
        case 'darker':
          return infoDarker;
        default:
          return baseColor;
      }
    }
    return baseColor;
  }

  /// Check if screen size is mobile
  static bool isMobile(double screenWidth) {
    return screenWidth < breakpointMD;
  }

  /// Check if screen size is tablet
  static bool isTablet(double screenWidth) {
    return screenWidth >= breakpointMD && screenWidth < breakpointLG;
  }

  /// Check if screen size is desktop
  static bool isDesktop(double screenWidth) {
    return screenWidth >= breakpointLG;
  }
}
