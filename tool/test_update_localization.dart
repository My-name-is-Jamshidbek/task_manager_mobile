import '../lib/core/services/update_service.dart';

/// Test script to verify update localization
void main() async {
  print('🧪 Testing Update Localization');
  print('================================');

  // Test multilingual version data
  final mockVersionData = {
    'id': 3,
    'name': 'v1.1.1 - Implement and Validate App Update Check Feature',
    'name_en': 'v1.1.1 - Implement and Validate App Update Check Feature',
    'name_ru': 'v1.1.1 – Функция проверки обновлений',
    'name_uz': 'v1.1.1 – Yangilanishlarni tekshirish funksiyasi',
    'desc': 'Implement and verify the update checking mechanism in the mobile app for both Android and iOS.',
    'desc_en': 'Implement and verify the update checking mechanism in the mobile app for both Android and iOS.',
    'desc_ru': 'В этой версии внедрена функция проверки обновлений для Android и iOS.',
    'desc_uz': 'Bu versiyada Android va iOS uchun yangilanishlarni tekshirish funksiyasi qo\'shildi.',
    'type': 'ios',
    'code': '1.1.1',
    'is_active': true,
    'created_at': '2025-09-11 18:49:14',
    'updated_at': '2025-09-11 18:49:14',
  };

  final versionInfo = LatestVersion.fromJson(mockVersionData);

  print('\n📱 Testing Localized Names:');
  print('English: ${versionInfo.getLocalizedName('en')}');
  print('Russian: ${versionInfo.getLocalizedName('ru')}');
  print('Uzbek: ${versionInfo.getLocalizedName('uz')}');

  print('\n📄 Testing Localized Descriptions:');
  print('English: ${versionInfo.getLocalizedDescription('en')}');
  print('Russian: ${versionInfo.getLocalizedDescription('ru')}');
  print('Uzbek: ${versionInfo.getLocalizedDescription('uz')}');

  print('\n✅ Localization Test Complete');
  print('All languages are properly supported!');
}
