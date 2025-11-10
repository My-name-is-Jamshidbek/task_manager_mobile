# Task Manager Flutter Project Architecture

## 📁 Project Structure

```
lib/
├── core/                           # Core functionality and shared utilities
│   ├── api/                        # API related code
│   │   └── api_client.dart         # HTTP client wrapper
│   ├── constants/                  # App constants
│   │   └── api_constants.dart      # API endpoints and configuration
│   ├── localization/               # Multi-language support
│   │   ├── app_localizations.dart  # Localization delegate and helper
│   │   └── localization_service.dart # Language management service
│   └── utils/                      # Utility classes
│       └── logger.dart             # Logging utility
├── data/                           # Data layer
│   ├── datasources/                # Data sources (API, local storage)
│   │   └── task_remote_datasource.dart # Remote API data source
│   ├── models/                     # Data models
│   │   ├── task.dart               # Task model
│   │   ├── user.dart               # User model
│   │   └── category.dart           # Category model
│   └── repositories/               # Repository pattern implementation
│       └── task_repository.dart    # Task repository
├── presentation/                   # Presentation layer
│   ├── providers/                  # State management (Provider/Bloc)
│   │   └── task_provider.dart      # Task state management
│   ├── screens/                    # UI screens
│   └── widgets/                    # Reusable UI components
│       ├── custom_button.dart      # Custom button widget
│       ├── custom_text_field.dart  # Custom text field widget
│       └── task_card.dart          # Task card widget
└── main.dart                       # App entry point

assets/
└── translations/                   # Multi-language JSON files
    ├── en.json                     # English translations
    ├── uz.json                     # Uzbek translations
    └── ru.json                     # Russian translations
```

## 🏗️ Architecture Overview

### 1. **Clean Architecture Pattern**

- **Presentation Layer**: UI components, state management
- **Data Layer**: Models, repositories, data sources
- **Core Layer**: Shared utilities, constants, services

### 2. **Widget-Based Architecture**

- Reusable UI components in `presentation/widgets/`
- Custom widgets for consistent design
- Modular and testable widget structure

### 3. **API Integration**

- Centralized HTTP client (`core/api/api_client.dart`)
- Repository pattern for data management
- Remote data sources for API communication
- Error handling and response parsing

### 4. **Multi-Language Support**

- Translation files in `assets/translations/`
- Localization service for language management
- Support for English, Uzbek, and Russian
- Easy to add new languages

## 🌐 Multi-Language Implementation

### Translation Files Location

```
assets/translations/
├── en.json     # English (default)
├── uz.json     # Uzbek
└── ru.json     # Russian
```

### Translation Functions Location

```
lib/core/localization/
├── app_localizations.dart      # Main localization logic
└── localization_service.dart   # Language switching service
```

### How to Use Translations

#### In Widgets:

```dart
// Using context extension
Text(context.tr('tasks.title'))

// Using AppLocalizations directly
Text(AppLocalizations.of(context).translate('tasks.title'))
```

#### Adding New Languages:

1. Create new JSON file in `assets/translations/`
2. Add locale to `supportedLocales` in `app_localizations.dart`
3. Update `localization_service.dart` with new language info

## 📱 Key Features

### 1. **Task Management**

- Create, read, update, delete tasks
- Task status management (pending, in-progress, completed)
- Priority levels (low, medium, high, urgent)
- Due date tracking
- Category organization

### 2. **API Integration**

- RESTful API communication
- Authentication support (Bearer token)
- Error handling and logging
- Response caching capabilities

### 3. **State Management**

- Provider pattern implementation
- Reactive UI updates
- Loading states management
- Error state handling

### 4. **UI Components**

- Custom button with multiple variants
- Custom text field with validation
- Task card with interactive elements
- Responsive design

## 🔧 Dependencies

### Core Dependencies

- `flutter_localizations`: Multi-language support
- `http`: HTTP client for API calls
- `provider`: State management
- `shared_preferences`: Local storage

### UI Dependencies

- `cupertino_icons`: iOS style icons
- `flutter_svg`: SVG image support
- `cached_network_image`: Image caching

### Development Dependencies

- `flutter_lints`: Code linting
- `build_runner`: Code generation
- `json_serializable`: JSON serialization

## 🚀 Getting Started

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Generate Code (if needed)

```bash
flutter packages pub run build_runner build
```

### 3. Run the Application

```bash
flutter run
```

## 📝 Code Guidelines

### 1. **File Naming**

- Use snake_case for file names
- Descriptive names that reflect functionality

### 2. **Widget Organization**

- Separate stateful and stateless widgets
- Keep widgets focused and single-purpose
- Use composition over inheritance

### 3. **State Management**

- Use Provider for reactive state management
- Separate business logic from UI logic
- Handle loading and error states properly

### 4. **API Integration**

- Use repository pattern for data access
- Handle network errors gracefully
- Implement proper error logging

### 5. **Localization**

- Keep all user-facing strings in translation files
- Use consistent key naming conventions
- Provide fallback for missing translations

## 🧪 Testing Strategy

### Unit Tests

- Test business logic in providers
- Test utility functions
- Test model serialization/deserialization

### Widget Tests

- Test custom widget behavior
- Test user interactions
- Test state changes

### Integration Tests

- Test API integration
- Test complete user flows
- Test multi-language functionality

## 📈 Scalability Considerations

### 1. **Adding New Features**

- Follow the established architecture pattern
- Create new providers for complex state
- Add corresponding repository and data source

### 2. **Adding New Languages**

- Create translation file in `assets/translations/`
- Update supported locales list
- Test with different language scripts

### 3. **API Expansion**

- Add new endpoints to `api_constants.dart`
- Create new data sources for different domains
- Implement proper error handling

## 🔐 Security Best Practices

### 1. **API Security**

- Use HTTPS for all API calls
- Implement proper authentication
- Handle tokens securely

### 2. **Data Validation**

- Validate user inputs
- Sanitize data before API calls
- Handle edge cases gracefully

## 📚 Additional Resources

- [APP_FLOW_DIAGRAM.md](APP_FLOW_DIAGRAM.md) - Complete application flow diagrams and user journey
- [Flutter Documentation](https://docs.flutter.dev/)
- [Provider Package](https://pub.dev/packages/provider)
- [Internationalization Guide](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [Clean Architecture in Flutter](https://resocoder.com/2019/08/27/flutter-tdd-clean-architecture-course-1-explanation-project-structure/)
