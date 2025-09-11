import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/logger.dart';
import 'version_service.dart';

/// Model for version information from API
class VersionInfo {
  final String platform;
  final String currentVersion;
  final LatestVersion latest;
  final bool updateRequired;

  VersionInfo({
    required this.platform,
    required this.currentVersion,
    required this.latest,
    required this.updateRequired,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      platform: json['platform'] ?? '',
      currentVersion: json['current_version'] ?? '',
      latest: LatestVersion.fromJson(json['latest'] ?? {}),
      updateRequired: json['update_required'] ?? false,
    );
  }
}

/// Model for latest version details
class LatestVersion {
  final int id;
  final String name;
  final String nameEn;
  final String nameRu;
  final String nameUz;
  final String description;
  final String descriptionEn;
  final String descriptionRu;
  final String descriptionUz;
  final String type;
  final String code;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  LatestVersion({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.nameRu,
    required this.nameUz,
    required this.description,
    required this.descriptionEn,
    required this.descriptionRu,
    required this.descriptionUz,
    required this.type,
    required this.code,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LatestVersion.fromJson(Map<String, dynamic> json) {
    return LatestVersion(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      nameEn: json['name_en'] ?? json['name'] ?? '',
      nameRu: json['name_ru'] ?? json['name'] ?? '',
      nameUz: json['name_uz'] ?? json['name'] ?? '',
      description: json['desc'] ?? '',
      descriptionEn: json['desc_en'] ?? json['desc'] ?? '',
      descriptionRu: json['desc_ru'] ?? json['desc'] ?? '',
      descriptionUz: json['desc_uz'] ?? json['desc'] ?? '',
      type: json['type'] ?? '',
      code: json['code'] ?? '',
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  /// Get localized name based on locale
  String getLocalizedName(String locale) {
    switch (locale.toLowerCase()) {
      case 'ru':
        return nameRu.isNotEmpty ? nameRu : name;
      case 'uz':
        return nameUz.isNotEmpty ? nameUz : name;
      case 'en':
      default:
        return nameEn.isNotEmpty ? nameEn : name;
    }
  }

  /// Get localized description based on locale
  String getLocalizedDescription(String locale) {
    switch (locale.toLowerCase()) {
      case 'ru':
        return descriptionRu.isNotEmpty ? descriptionRu : description;
      case 'uz':
        return descriptionUz.isNotEmpty ? descriptionUz : description;
      case 'en':
      default:
        return descriptionEn.isNotEmpty ? descriptionEn : description;
    }
  }
}

/// Service for checking app updates and managing version updates
class UpdateService {
  static const String _baseUrl = 'https://tms.amusoft.uz/api';
  static const String _versionCheckEndpoint = '/mobile-version/check';

  /// Check for app updates
  static Future<VersionInfo?> checkForUpdates() async {
    try {
      final currentVersion = VersionService.getVersionNumber();
      final platform = _getPlatformForAPI();

      if (platform == null) {
        Logger.warning(
          '⚠️ UpdateService: Unsupported platform for update check',
        );
        return null;
      }

      Logger.info(
        '🔄 UpdateService: Checking for updates - $platform v$currentVersion',
      );

      final uri = Uri.parse('$_baseUrl$_versionCheckEndpoint').replace(
        queryParameters: {
          'platform': platform,
          'current_version': currentVersion,
        },
      );

      Logger.info('📤 UpdateService: Sending request to ${uri.toString()}');

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      Logger.info('📥 UpdateService: Response status: ${response.statusCode}');
      Logger.info('📥 UpdateService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          final versionInfo = VersionInfo.fromJson(jsonData['data']);
          Logger.info('✅ UpdateService: Version check successful');
          Logger.info(
            '🔍 UpdateService: Update required: ${versionInfo.updateRequired}',
          );
          Logger.info(
            '🔍 UpdateService: Latest version: ${versionInfo.latest.code}',
          );
          return versionInfo;
        } else {
          Logger.warning('⚠️ UpdateService: Invalid response format');
          return null;
        }
      } else if (response.statusCode == 404) {
        Logger.info('📱 UpdateService: No active version found for platform');
        return null;
      } else if (response.statusCode == 422) {
        Logger.warning('⚠️ UpdateService: Validation error in request');
        return null;
      } else {
        Logger.error(
          '❌ UpdateService: Unexpected response status: ${response.statusCode}',
          'UpdateService',
          response.body,
          null,
        );
        return null;
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ UpdateService: Failed to check for updates',
        'UpdateService',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// Get platform string for API (android or ios)
  static String? _getPlatformForAPI() {
    if (kIsWeb) {
      return null; // Web doesn't support updates via this API
    } else if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else {
      return null; // Unsupported platform
    }
  }

  /// Check if update is available (without requiring update)
  static Future<bool> hasUpdateAvailable() async {
    try {
      final versionInfo = await checkForUpdates();
      return versionInfo != null &&
          !versionInfo.updateRequired &&
          versionInfo.latest.code != VersionService.getVersionNumber();
    } catch (e) {
      Logger.warning(
        '⚠️ UpdateService: Error checking for available updates: $e',
      );
      return false;
    }
  }

  /// Check if update is required (mandatory)
  static Future<bool> isUpdateRequired() async {
    try {
      final versionInfo = await checkForUpdates();
      return versionInfo?.updateRequired ?? false;
    } catch (e) {
      Logger.warning(
        '⚠️ UpdateService: Error checking for required updates: $e',
      );
      return false;
    }
  }

  /// Get update information for display with localization support
  static Future<Map<String, dynamic>?> getUpdateInfo([String? locale]) async {
    try {
      final versionInfo = await checkForUpdates();
      if (versionInfo == null) return null;

      // Default to English if no locale provided
      final targetLocale = locale ?? 'en';

      return {
        'hasUpdate':
            versionInfo.latest.code != VersionService.getVersionNumber(),
        'isRequired': versionInfo.updateRequired,
        'currentVersion': versionInfo.currentVersion,
        'latestVersion': versionInfo.latest.code,
        'updateTitle': versionInfo.latest.getLocalizedName(targetLocale),
        'updateDescription': versionInfo.latest.getLocalizedDescription(targetLocale),
        'platform': versionInfo.platform,
        // Include all language variants for flexibility
        'titleEn': versionInfo.latest.nameEn,
        'titleRu': versionInfo.latest.nameRu,
        'titleUz': versionInfo.latest.nameUz,
        'descriptionEn': versionInfo.latest.descriptionEn,
        'descriptionRu': versionInfo.latest.descriptionRu,
        'descriptionUz': versionInfo.latest.descriptionUz,
      };
    } catch (e) {
      Logger.warning('⚠️ UpdateService: Error getting update info: $e');
      return null;
    }
  }

  /// Open app store for update (platform-specific)
  static Future<void> openAppStore() async {
    try {
      if (Platform.isAndroid) {
        // Android - open Play Store
        Logger.info('📱 UpdateService: Opening Google Play Store');
        // TODO: Implement opening Play Store with package URL scheme
        // Example: market://details?id=com.yourcompany.taskmanager
      } else if (Platform.isIOS) {
        // iOS - open App Store
        Logger.info('📱 UpdateService: Opening Apple App Store');
        // TODO: Implement opening App Store with app ID URL scheme
        // Example: https://apps.apple.com/app/idYOUR_APP_ID
      } else {
        Logger.warning(
          '⚠️ UpdateService: App store not supported on this platform',
        );
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ UpdateService: Failed to open app store',
        'UpdateService',
        e,
        stackTrace,
      );
    }
  }

  /// Check if platform supports updates
  static bool isPlatformSupported() {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Get platform-specific update instructions
  static String getUpdateInstructions() {
    if (Platform.isAndroid) {
      return 'Please update the app from Google Play Store to continue using the latest features.';
    } else if (Platform.isIOS) {
      return 'Please update the app from App Store to continue using the latest features.';
    } else {
      return 'Please check for updates manually.';
    }
  }
}
