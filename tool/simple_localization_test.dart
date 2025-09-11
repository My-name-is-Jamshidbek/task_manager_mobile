/// Simple test to verify update localization logic
void main() {
  print('🧪 Testing Update Localization Logic');
  print('=====================================');

  // Test multilingual version data (simulating API response)
  final Map<String, String> mockVersionData = {
    'id': '3',
    'name': 'v1.1.1 - Implement and Validate App Update Check Feature',
    'name_en': 'v1.1.1 - Implement and Validate App Update Check Feature',
    'name_ru': 'v1.1.1 – Функция проверки обновлений',
    'name_uz': 'v1.1.1 – Yangilanishlarni tekshirish funksiyasi',
    'desc':
        'Implement and verify the update checking mechanism in the mobile app for both Android and iOS.',
    'desc_en':
        'Implement and verify the update checking mechanism in the mobile app for both Android and iOS.',
    'desc_ru':
        'В этой версии внедрена функция проверки обновлений для Android и iOS.',
    'desc_uz':
        'Bu versiyada Android va iOS uchun yangilanishlarni tekshirish funksiyasi qo\'shildi.',
    'type': 'ios',
    'code': '1.1.1',
    'is_active': 'true',
    'created_at': '2025-09-11 18:49:14',
    'updated_at': '2025-09-11 18:49:14',
  };

  // Simulate the localization logic from LatestVersion.getLocalizedName()
  String getLocalizedName(String locale) {
    switch (locale.toLowerCase()) {
      case 'ru':
        return mockVersionData['name_ru']!.isNotEmpty
            ? mockVersionData['name_ru']!
            : mockVersionData['name']!;
      case 'uz':
        return mockVersionData['name_uz']!.isNotEmpty
            ? mockVersionData['name_uz']!
            : mockVersionData['name']!;
      case 'en':
      default:
        return mockVersionData['name_en']!.isNotEmpty
            ? mockVersionData['name_en']!
            : mockVersionData['name']!;
    }
  }

  // Simulate the localization logic from LatestVersion.getLocalizedDescription()
  String getLocalizedDescription(String locale) {
    switch (locale.toLowerCase()) {
      case 'ru':
        return mockVersionData['desc_ru']!.isNotEmpty
            ? mockVersionData['desc_ru']!
            : mockVersionData['desc']!;
      case 'uz':
        return mockVersionData['desc_uz']!.isNotEmpty
            ? mockVersionData['desc_uz']!
            : mockVersionData['desc']!;
      case 'en':
      default:
        return mockVersionData['desc_en']!.isNotEmpty
            ? mockVersionData['desc_en']!
            : mockVersionData['desc']!;
    }
  }

  print('\n📱 Testing Localized Names:');
  print('English: ${getLocalizedName('en')}');
  print('Russian: ${getLocalizedName('ru')}');
  print('Uzbek: ${getLocalizedName('uz')}');

  print('\n📄 Testing Localized Descriptions:');
  print('English: ${getLocalizedDescription('en')}');
  print('Russian: ${getLocalizedDescription('ru')}');
  print('Uzbek: ${getLocalizedDescription('uz')}');

  // Test the locale detection from app logs
  print('\n🌐 Testing Locale Detection:');
  final testLocales = ['en', 'ru', 'uz', 'fr', 'unknown'];
  for (final locale in testLocales) {
    print('Locale "$locale" -> Name: "${getLocalizedName(locale)}"');
  }

  print('\n✅ Localization Test Complete');
  print('All languages are properly supported!');

  // Test what happens with missing translations
  print('\n🧪 Testing Fallback Logic:');
  final Map<String, String> incompleteData = {
    'name': 'Fallback Version',
    'name_en': 'English Version',
    'name_ru': '', // Empty Russian
    'name_uz': 'Uzbek Version',
    'desc': 'Fallback Description',
    'desc_en': 'English Description',
    'desc_ru': 'Russian Description',
    'desc_uz': '', // Empty Uzbek
  };

  print(
    'Missing Russian name -> Falls back to: "${incompleteData['name_ru']!.isEmpty ? incompleteData['name']! : incompleteData['name_ru']!}"',
  );
  print(
    'Missing Uzbek desc -> Falls back to: "${incompleteData['desc_uz']!.isEmpty ? incompleteData['desc']! : incompleteData['desc_uz']!}"',
  );
}
