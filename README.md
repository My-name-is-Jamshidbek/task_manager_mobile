# 📱 Task Manager Mobile

A comprehensive Flutter task management application with advanced features including Firebase integration, multi-language support, and a robust theme system.

## 🎯 Project Overview

Task Manager Mobile is a feature-rich, cross-platform task management application built with Flutter. It provides a professional-grade solution for managing tasks, projects, and teams with modern UI/UX design and enterprise-level architecture.

### ✨ Key Features

- 🔥 **Firebase Integration** - Cloud messaging, notifications, and analytics
- 🌍 **Multi-Language Support** - English, Uzbek, and Russian translations
- 🎨 **Advanced Theme System** - Light/dark themes with customizable colors
- 📱 **Cross-Platform** - Android, iOS, and Web support
- 🏗️ **Clean Architecture** - Modular, scalable, and maintainable codebase
- 🔐 **Authentication** - Secure user authentication and authorization
- 📊 **Project Management** - Comprehensive project and task organization
- 🔔 **Push Notifications** - Real-time notifications for task updates
- 📈 **Analytics** - Firebase Analytics and Crashlytics integration
- 🎯 **Platform-Specific Versions** - Optimized for each platform

### 📱 Application Screens

- **🏠 Home Screen** - Dashboard with overview and quick actions
- **📋 Tasks Screen** - Complete task management with filtering and sorting
- **📁 Projects Screen** - Project organization and team collaboration
- **👤 Profile Screen** - User profile management and settings
- **⚙️ Settings Screen** - App preferences, theme selection, and language settings
- **🔐 Authentication** - Secure login and registration flow
- **🔧 Debug/Dev Screens** - Firebase testing and development tools

## 🏗️ Architecture

The application follows Clean Architecture principles with a widget-based approach:

```
lib/
├── core/                    # Core functionality
│   ├── api/                # HTTP client and API integration
│   ├── constants/          # App constants and configurations
│   ├── localization/       # Multi-language support
│   ├── services/           # Firebase and other services
│   ├── theme/             # Theme system and styling
│   └── utils/             # Utilities and helpers
├── data/                   # Data layer
│   ├── datasources/       # Remote data sources
│   ├── models/            # Data models
│   └── repositories/      # Repository implementations
└── presentation/          # UI layer
    ├── providers/         # State management
    ├── screens/           # Application screens
    └── widgets/           # Reusable UI components
```

## 🚀 Quick Start

### Prerequisites

- Flutter SDK (>= 3.8.1)
- Dart SDK (>= 3.8.1)
- Android Studio / VS Code
- Firebase project (for notifications and analytics)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/My-name-is-Jamshidbek/task_manager_mobile.git
   cd task_manager_mobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase** (See [Firebase Setup Guide](FIREBASE_SETUP.md))
   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase
   flutterfire configure
   ```

4. **Run the application**
   ```bash
   # Development mode
   flutter run
   
   # Release mode
   flutter run --release
   ```

## 🔥 Firebase Configuration

This app integrates with Firebase for:
- **Cloud Messaging** - Push notifications with foreground, background, and terminated state handling
- **Analytics** - User behavior tracking and app performance monitoring
- **Crashlytics** - Comprehensive error reporting and crash analysis

### Firebase Features Implemented

- ✅ **FCM Token Management** - Automatic token generation and refresh
- ✅ **Backend Integration** - Token registration/deactivation with your API
- ✅ **Topic Subscriptions** - Organized notification channels
- ✅ **Device Information** - Platform-specific device data collection
- ✅ **Message Handling** - Complete lifecycle notification processing
- ✅ **Testing Interface** - Built-in Firebase testing screen for developers

### Setup Steps

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Cloud Messaging, Analytics, and Crashlytics
3. Follow the detailed [Firebase Setup Guide](FIREBASE_SETUP.md)
4. Run `flutterfire configure` to generate configuration files
5. Update your backend API to handle Firebase token endpoints

**Important Notes:**
- iOS push notifications require physical devices (not simulators)
- Users must grant notification permissions
- Your backend must implement the provided API endpoints

For complete implementation details, see [Firebase Implementation Summary](FIREBASE_IMPLEMENTATION_SUMMARY.md).

## 🌍 Multi-Language Support

The app supports three languages with complete translations:

- 🇺🇸 **English** - Default language
- 🇺🇿 **Uzbek** - Full localization
- 🇷🇺 **Russian** - Complete translation

### Adding New Languages

1. Create a new JSON file in `assets/translations/`
2. Add translations following the existing structure
3. Update `LocalizationService` to include the new locale
4. Add the locale to `supportedLocales` in `AppLocalizations`

See [Multilingual API Documentation](MULTILINGUAL_API.md) for implementation details.

## 🎨 Theme System

Advanced multi-theme system with professional design patterns:

### Available Themes
- **Light Themes** - Blue, Green, Purple, Orange variants
- **Dark Themes** - Corresponding dark mode versions
- **System Theme** - Automatic light/dark based on device settings

### Design System Components
- **Standardized Spacing** - 8-point grid system (4px to 40px)
- **Typography Scale** - Consistent text sizing and weights
- **Color Semantics** - Success, warning, error, and info colors
- **Border Radius** - Consistent corner radius values (4px to 20px)
- **Component Sizes** - Standardized button heights, input fields, and containers

### Theme Configuration

```dart
// Access theme service
final themeService = Provider.of<ThemeService>(context);

// Change theme
themeService.setTheme(AppTheme.darkBlue);

// Use theme constants
Container(
  padding: EdgeInsets.all(ThemeConstants.spaceLG),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(ThemeConstants.radiusMD),
    color: Theme.of(context).colorScheme.primary,
  ),
)
```

### Benefits
- ✅ **Consistency** - Unified design language across the app
- ✅ **Accessibility** - Proper contrast ratios and readable text
- ✅ **Maintainability** - Centralized theme management
- ✅ **Performance** - Efficient theme switching with minimal rebuilds

See [Theme System Documentation](THEME_SYSTEM.md) and [Theme Quick Reference](THEME_QUICK_REFERENCE.md) for complete implementation details.

## 📱 Platform Support

### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: Latest
- Firebase Cloud Messaging support
- Material Design 3 components

### iOS
- Minimum iOS: 12.0
- Cupertino design components
- APNs integration for notifications
- App Store ready

### Web
- Progressive Web App capabilities
- Responsive design
- Firebase web SDK integration

## 🔧 Development

### Project Structure

The codebase follows a modular, widget-based architecture:

- **Core Layer** - Foundation services and utilities
- **Data Layer** - Models, repositories, and data sources
- **Presentation Layer** - UI components and state management

### State Management

The app uses Provider for state management with dedicated providers for:

- **AuthProvider** - Authentication state
- **FirebaseProvider** - Firebase services
- **ProjectsProvider** - Project management
- **TasksApiProvider** - Task operations
- **ThemeService** - Theme management
- **LocalizationService** - Language settings

### API Integration

Complete HTTP client with:

- Authentication handling
- Error management
- Request/response logging
- Retry mechanisms

See [API Integration Documentation](MULTILINGUAL_API.md) for details.

## 🧪 Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter drive --target=test_driver/app.dart
```

### Test Structure

- **Unit Tests** - Core logic and services
- **Widget Tests** - UI component testing
- **Integration Tests** - End-to-end scenarios

### Firebase Testing

The app includes a dedicated Firebase Test Screen for comprehensive testing:

1. Navigate to the Firebase Test Screen (dev tools)
2. Test Firebase initialization and token generation
3. Verify backend integration with auth tokens
4. Monitor real-time logs and status updates

## ❓ Troubleshooting

### Common Issues

**Firebase Setup Issues:**
```bash
# Re-configure Firebase if needed
flutterfire configure

# Clean and rebuild
flutter clean && flutter pub get
```

**Build Issues:**
```bash
# Check Flutter environment
flutter doctor

# Fix dependency conflicts
flutter pub deps
```

**Notification Issues:**
- Ensure notification permissions are granted
- Test on physical devices (not simulators for iOS)
- Verify Firebase project configuration
- Check backend API endpoints

### Debug Commands

```bash
# Check Firebase project
firebase projects:list

# Verify current project
firebase use

# Check Flutter installation
flutter doctor -v
```

## 📦 Build & Deployment

### Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release
```

### iOS

```bash
# Build for iOS
flutter build ios --release

# Build IPA
flutter build ipa --release
```

### Web

```bash
# Build for web
flutter build web --release
```

## 📋 Dependencies

### Core Dependencies

- **flutter** - Framework
- **provider** - State management
- **http** - HTTP client
- **shared_preferences** - Local storage
- **go_router** - Navigation

### Firebase

- **firebase_core** - Firebase foundation
- **firebase_messaging** - Push notifications
- **firebase_analytics** - Analytics
- **firebase_crashlytics** - Error reporting

### UI & UX

- **flutter_localizations** - Internationalization
- **cached_network_image** - Image caching
- **lottie** - Animations
- **flutter_svg** - SVG support

See [pubspec.yaml](pubspec.yaml) for complete dependency list.

## 📚 Documentation

Comprehensive documentation is available:

- [**Architecture Overview**](ARCHITECTURE.md) - System design and patterns
- [**Theme System**](THEME_SYSTEM.md) - Complete theming guide
- [**Firebase Setup**](FIREBASE_SETUP.md) - Firebase configuration
- [**Widget Architecture**](WIDGET_ARCHITECTURE.md) - UI component system
- [**Platform Versions**](PLATFORM_VERSIONS_SUMMARY.md) - Version management
- [**Project Summary**](SUMMARY.md) - Complete feature overview

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Flutter/Dart style guidelines
- Write tests for new features
- Update documentation as needed
- Ensure all tests pass before submitting
- Use meaningful commit messages

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Community contributors and testers

## 📧 Contact

**Developer:** Jamshidbek  
**Repository:** [task_manager_mobile](https://github.com/My-name-is-Jamshidbek/task_manager_mobile)

---

**Built with ❤️ using Flutter**
