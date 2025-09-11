import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

/// Service for managing platform-specific version information
class VersionService {
  static const String _androidVersion = '1.2.0';
  static const String _iosVersion = '1.1.5';
  static const String _webVersion = '1.0.8';
  static const String _defaultVersion = '1.0.0';

  static const int _androidBuildNumber = 12;
  static const int _iosBuildNumber = 15;
  static const int _webBuildNumber = 8;
  static const int _defaultBuildNumber = 1;

  /// Get the current platform name
  static String getPlatformName() {
    if (kIsWeb) {
      return 'Web';
    } else if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    } else if (Platform.isMacOS) {
      return 'macOS';
    } else if (Platform.isWindows) {
      return 'Windows';
    } else if (Platform.isLinux) {
      return 'Linux';
    } else {
      return 'Unknown';
    }
  }

  /// Get platform-specific version number
  static String getVersionNumber() {
    if (kIsWeb) {
      return _webVersion;
    } else if (Platform.isAndroid) {
      return _androidVersion;
    } else if (Platform.isIOS) {
      return _iosVersion;
    } else {
      return _defaultVersion;
    }
  }

  /// Get platform-specific build number
  static int getBuildNumber() {
    if (kIsWeb) {
      return _webBuildNumber;
    } else if (Platform.isAndroid) {
      return _androidBuildNumber;
    } else if (Platform.isIOS) {
      return _iosBuildNumber;
    } else {
      return _defaultBuildNumber;
    }
  }

  /// Get full version string with platform
  static String getFullVersionString() {
    final platform = getPlatformName();
    final version = getVersionNumber();
    final build = getBuildNumber();
    return '$platform v$version ($build)';
  }

  /// Get version string for display
  static String getDisplayVersion() {
    final version = getVersionNumber();
    final build = getBuildNumber();
    return 'v$version ($build)';
  }

  /// Get platform icon based on current platform
  static String getPlatformIcon() {
    if (kIsWeb) {
      return '🌐';
    } else if (Platform.isAndroid) {
      return '🤖';
    } else if (Platform.isIOS) {
      return '📱';
    } else if (Platform.isMacOS) {
      return '💻';
    } else if (Platform.isWindows) {
      return '🖥️';
    } else if (Platform.isLinux) {
      return '🐧';
    } else {
      return '❓';
    }
  }

  /// Get detailed platform information
  static Future<Map<String, dynamic>> getPlatformInfo() async {
    final info = <String, dynamic>{
      'platform': getPlatformName(),
      'version': getVersionNumber(),
      'buildNumber': getBuildNumber(),
      'fullVersion': getFullVersionString(),
      'displayVersion': getDisplayVersion(),
      'icon': getPlatformIcon(),
    };

    try {
      // Try to get additional platform-specific info
      if (Platform.isAndroid) {
        info['androidSdkInt'] = await _getAndroidSdkVersion();
      } else if (Platform.isIOS) {
        info['iosVersion'] = await _getIosVersion();
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ VersionService: Failed to get additional platform info',
        'VersionService',
        e,
        stackTrace,
      );
    }

    Logger.info('📱 VersionService: Platform info - ${info['fullVersion']}');
    return info;
  }

  /// Get Android SDK version (if available)
  static Future<int?> _getAndroidSdkVersion() async {
    try {
      if (Platform.isAndroid) {
        const platform = MethodChannel('platform_info');
        final int? sdkInt = await platform.invokeMethod('getAndroidSdkVersion');
        return sdkInt;
      }
    } catch (e) {
      Logger.warning(
        '⚠️ VersionService: Could not get Android SDK version: $e',
      );
    }
    return null;
  }

  /// Get iOS version (if available)
  static Future<String?> _getIosVersion() async {
    try {
      if (Platform.isIOS) {
        const platform = MethodChannel('platform_info');
        final String? iosVersion = await platform.invokeMethod('getIosVersion');
        return iosVersion;
      }
    } catch (e) {
      Logger.warning('⚠️ VersionService: Could not get iOS version: $e');
    }
    return null;
  }

  /// Check if this is a debug build
  static bool isDebugBuild() {
    return kDebugMode;
  }

  /// Check if this is a release build
  static bool isReleaseBuild() {
    return kReleaseMode;
  }

  /// Get build mode string
  static String getBuildMode() {
    if (kDebugMode) return 'Debug';
    if (kReleaseMode) return 'Release';
    if (kProfileMode) return 'Profile';
    return 'Unknown';
  }

  /// Get complete version info for debugging
  static Future<String> getDebugVersionInfo() async {
    final info = await getPlatformInfo();
    final buildMode = getBuildMode();

    return '''
${info['fullVersion']}
Build Mode: $buildMode
Platform: ${info['platform']}
Version: ${info['version']}
Build: ${info['buildNumber']}
${kIsWeb ? 'Web Application' : 'Native Application'}
''';
  }
}
