import 'package:flutter/material.dart';
import 'dart:convert';
import '../../core/utils/multilingual_message.dart';
import '../../core/localization/localization_service.dart';

/// Example demonstrating how to use the new multilingual API response system
class MultilingualMessageExample extends StatefulWidget {
  const MultilingualMessageExample({super.key});

  @override
  State<MultilingualMessageExample> createState() =>
      _MultilingualMessageExampleState();
}

class _MultilingualMessageExampleState
    extends State<MultilingualMessageExample> {
  String? _currentMessage;
  String _currentLanguage = 'en';

  // Simulate API response with multilingual message
  final Map<String, dynamic> _mockApiResponse = {
    'success': true,
    'message': {
      'uz': 'Tizimga kirish muvaffaqiyatli',
      'ru': 'Вход в систему выполнен успешно',
      'en': 'Login successful',
    },
    'token': '1|ExGr2OBHU0HPyZ3Wjs12FSwPEivKA04MkbfjcHPi13a202db',
    'user': {'id': 1, 'name': 'admin', 'phone': '998901234567'},
  };

  @override
  void initState() {
    super.initState();
    _updateMessage();
  }

  void _updateMessage() {
    final multilingualMessage = MultilingualMessage.fromJson(
      _mockApiResponse['message'],
    );
    setState(() {
      _currentMessage = multilingualMessage.getMessage();
    });
  }

  void _changeLanguage(String languageCode) {
    setState(() {
      _currentLanguage = languageCode;
    });

    // Simulate changing app language
    final localizationService = LocalizationService();
    localizationService.changeLanguage(languageCode).then((_) {
      _updateMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multilingual API Messages'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API Response Message:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _currentMessage ?? 'Loading...',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Language:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildLanguageButton('en', 'English'),
                const SizedBox(width: 8),
                _buildLanguageButton('uz', 'O\'zbekcha'),
                const SizedBox(width: 8),
                _buildLanguageButton('ru', 'Русский'),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Raw API Response:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _formatJson(_mockApiResponse),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildUsageExample(),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(String code, String name) {
    final isSelected = _currentLanguage == code;
    return ElevatedButton(
      onPressed: () => _changeLanguage(code),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primary
            : null,
        foregroundColor: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : null,
      ),
      child: Text(name),
    );
  }

  Widget _buildUsageExample() {
    return ExpansionTile(
      title: const Text('Usage Example'),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '''// Create from API response
final message = MultilingualMessage.fromJson(response['message']);

// Get in current app language
String localizedMessage = message.getMessage();

// Get in specific language
String uzbekMessage = message.getMessageInLanguage('uz');
String russianMessage = message.getMessageInLanguage('ru');
String englishMessage = message.getMessageInLanguage('en');

// Check available languages
List<String> languages = message.availableLanguages;

// Check if message exists
bool hasMessage = message.hasMessage;''',
            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }

  String _formatJson(Map<String, dynamic> json) {
    final jsonEncoder = JsonEncoder.withIndent('  ');
    return jsonEncoder.convert(json);
  }
}
