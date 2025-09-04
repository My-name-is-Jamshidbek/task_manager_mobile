# Multilingual API Response System

## Overview

The API response structure has been updated to support multilingual messages. Instead of receiving a single message string, the API now returns a message object with three language variants: `uz` (Uzbek), `ru` (Russian), and `en` (English).

## API Response Structure

### Old Format

```json
{
  "success": true,
  "message": "Login successful",
  "token": "...",
  "user": {...}
}
```

### New Format

```json
{
  "success": true,
  "message": {
    "uz": "Tizimga kirish muvaffaqiyatli",
    "ru": "Вход в систему выполнен успешно",
    "en": "Login successful"
  },
  "token": "...",
  "user": {...}
}
```

## Implementation

### 1. MultilingualMessage Class

The `MultilingualMessage` class handles the parsing and retrieval of localized messages:

```dart
import '../../core/utils/multilingual_message.dart';

// Create from API response
final message = MultilingualMessage.fromJson(responseData['message']);

// Get message in current app language
String localizedMessage = message.getMessage();

// Get message in specific language
String uzbekMessage = message.getMessageInLanguage('uz');
String russianMessage = message.getMessageInLanguage('ru');
String englishMessage = message.getMessageInLanguage('en');
```

### 2. Updated Response Models

Auth response models now use `MultilingualMessage`:

```dart
class LoginResponse {
  final bool success;
  final MultilingualMessage? message;
  final String? token;
  final User? user;

  // Get localized message
  String? getLocalizedMessage() {
    return message?.getMessage();
  }
}
```

### 3. API Client Error Handling

The API client automatically handles both old and new message formats:

```dart
// In API client error handling
if (errorData['message'] != null) {
  final multilingualMessage = MultilingualMessage.fromJson(errorData['message']);
  message = multilingualMessage.getMessage();
} else {
  message = 'Unknown error occurred';
}
```

### 4. Provider Updates

Auth provider prioritizes API messages over local translations:

```dart
// Try to get localized message from API response first
String? errorMessage = response.error;
if (response.data?.message != null) {
  errorMessage = response.data!.getLocalizedMessage();
}
_setError(errorMessage);
```

### 5. UI Error Display

Login and SMS verification screens show API messages when available:

```dart
String errorMessage;
if (authProvider.error != null && authProvider.error!.isNotEmpty) {
  // Use API message directly if available
  errorMessage = authProvider.error!;
} else {
  // Fallback to translation
  errorMessage = loc.translate(errorKey);
}
```

## Language Selection

The system automatically uses the current app language setting to display the appropriate message. Language selection works as follows:

1. **Current app language** - Uses the language set in `LocalizationService`
2. **Fallback language** - If current language message is not available
3. **English default** - If neither current nor fallback is available
4. **Any available** - Uses any available language as last resort

## Backward Compatibility

The system maintains backward compatibility with old API responses:

- If the API returns a string message, it uses that string for all languages
- If the API returns an object message, it uses the appropriate language
- No changes needed in existing code that doesn't use the new features

## Usage Examples

### Getting Localized Messages

```dart
// From API response
final response = await authService.login(phone, password);
if (response.data?.message != null) {
  final localizedMessage = response.data!.getLocalizedMessage();
  showSnackBar(localizedMessage);
}

// From error response
if (!response.isSuccess) {
  final errorMessage = response.error; // Already localized by API client
  showError(errorMessage);
}
```

### Working with Specific Languages

```dart
// Get message in all languages for debugging
final message = response.data?.message;
if (message != null) {
  print('Uzbek: ${message.getMessageInLanguage('uz')}');
  print('Russian: ${message.getMessageInLanguage('ru')}');
  print('English: ${message.getMessageInLanguage('en')}');
}
```

### Custom API Responses

For new API endpoints, use the base response classes:

```dart
class TaskResponse extends BaseApiResponse {
  final List<Task>? tasks;

  const TaskResponse({
    required bool success,
    MultilingualMessage? message,
    this.tasks,
  }) : super(success: success, message: message);

  factory TaskResponse.fromJson(Map<String, dynamic> json) {
    return TaskResponse(
      success: json['success'] ?? false,
      message: json['message'] != null
          ? MultilingualMessage.fromJson(json['message'])
          : null,
      tasks: json['tasks']?.map<Task>((e) => Task.fromJson(e)).toList(),
    );
  }
}
```

## Utility Extensions

Use the provided extensions for easier message handling:

```dart
import '../../core/utils/multilingual_api_extensions.dart';

// Extract localized message from any response
final localizedMessage = responseData.getLocalizedMessage();

// Get language headers for API requests
final headers = MultilingualApiUtils.getLanguageHeaders();
```

## Best Practices

1. **Always check for API messages first** before falling back to local translations
2. **Use the provided helper methods** instead of manually parsing message objects
3. **Maintain backward compatibility** when updating existing API integrations
4. **Test with different language settings** to ensure proper message display
5. **Handle null messages gracefully** with appropriate fallbacks

## Migration Guide

To migrate existing code:

1. Update response models to use `MultilingualMessage`
2. Add `getLocalizedMessage()` methods to response classes
3. Update providers to prioritize API messages
4. Update UI to display API messages when available
5. Test with different language settings

The migration is designed to be incremental - you can update one component at a time without breaking existing functionality.
