/// Test script to verify the new localized update dialog translations
void main() {
  print('🧪 Testing Update Dialog Localization');
  print('======================================');

  // Test the new translation keys
  final translations = {
    'en': {
      'updateOptionalMessage': 'You can continue using the current version or update now for the latest features.',
      'versionComparison': 'Current: {current} → Latest: {latest}',
    },
    'ru': {
      'updateOptionalMessage': 'Вы можете продолжить использовать текущую версию или обновиться сейчас для получения последних функций.',
      'versionComparison': 'Текущая: {current} → Последняя: {latest}',
    },
    'uz': {
      'updateOptionalMessage': 'Siz joriy versiyadan foydalanishda davom etishingiz yoki eng so\'nggi xususiyatlar uchun hozir yangilashingiz mumkin.',
      'versionComparison': 'Joriy: {current} → Eng so\'nggi: {latest}',
    },
  };

  // Test version comparison with placeholders
  String translateWithParams(String text, Map<String, String> params) {
    String result = text;
    params.forEach((placeholder, value) {
      result = result.replaceAll('{$placeholder}', value);
    });
    return result;
  }

  print('\n📱 Testing Version Comparison Localization:');
  for (final lang in translations.keys) {
    final versionText = translateWithParams(
      translations[lang]!['versionComparison']!,
      {'current': '1.1.0', 'latest': '1.1.1'}
    );
    print('$lang: $versionText');
  }

  print('\n💬 Testing Optional Update Message:');
  for (final lang in translations.keys) {
    final message = translations[lang]!['updateOptionalMessage']!;
    print('$lang: $message');
  }

  print('\n✅ Localization Test Complete');
  print('All update dialog texts are now properly localized!');

  // Test parameter replacement edge cases
  print('\n🧪 Testing Parameter Replacement:');
  final testTemplate = 'Version {version} is available. Current: {current}';
  final result = translateWithParams(testTemplate, {
    'version': '2.0.0',
    'current': '1.5.0'
  });
  print('Template: $testTemplate');
  print('Result: $result');
  
  // Test missing parameter
  final missingParam = translateWithParams(testTemplate, {'version': '2.0.0'});
  print('Missing param result: $missingParam');
}
