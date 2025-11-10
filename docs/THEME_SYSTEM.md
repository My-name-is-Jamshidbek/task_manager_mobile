# 🎨 Multi-Theme System Documentation

## 📋 Overview

The Flutter Task Manager app includes a comprehensive multi-theme system that allows users to:

- ✅ **Switch between Light/Dark/System themes**
- ✅ **Choose from 7 different color schemes**
- ✅ **Persistent theme preferences**
- ✅ **Consistent design tokens**
- ✅ **Live theme switching without restart**

## 📁 File Structure

```
lib/core/
├── constants/
│   └── theme_constants.dart        # All theme constants and design tokens
└── theme/
    └── theme_service.dart          # Theme management service

lib/presentation/screens/
└── theme_settings_screen.dart      # Theme settings UI

lib/
├── theme_demo.dart                 # Demo app to showcase themes
└── main.dart                       # Main app with theme integration
```

## 🎯 Theme Constants (`theme_constants.dart`)

### **Colors**

```dart
// Primary Colors (7 different themes)
static const Color primaryBlue = Color(0xFF2196F3);
static const Color primaryPurple = Color(0xFF9C27B0);
static const Color primaryGreen = Color(0xFF4CAF50);
static const Color primaryOrange = Color(0xFFFF9800);
static const Color primaryRed = Color(0xFFE91E63);
static const Color primaryTeal = Color(0xFF009688);
static const Color primaryIndigo = Color(0xFF3F51B5);

// Status Colors for Tasks
static const Color priorityLow = Color(0xFF4CAF50);      // Green
static const Color priorityMedium = Color(0xFFFF9800);   // Orange
static const Color priorityHigh = Color(0xFFF44336);     // Red
static const Color priorityUrgent = Color(0xFF9C27B0);   // Purple
```

### **Typography**

```dart
// Font Sizes
static const double fontSizeXS = 10.0;
static const double fontSizeSM = 12.0;
static const double fontSizeMD = 14.0;
static const double fontSizeLG = 16.0;
static const double fontSizeXL = 18.0;
static const double fontSize2XL = 20.0;
static const double fontSize3XL = 24.0;
static const double fontSize4XL = 32.0;
static const double fontSize5XL = 48.0;

// Font Weights
static const FontWeight fontWeightLight = FontWeight.w300;
static const FontWeight fontWeightRegular = FontWeight.w400;
static const FontWeight fontWeightMedium = FontWeight.w500;
static const FontWeight fontWeightSemiBold = FontWeight.w600;
static const FontWeight fontWeightBold = FontWeight.w700;
```

### **Spacing System**

```dart
static const double spaceXS = 4.0;
static const double spaceSM = 8.0;
static const double spaceMD = 12.0;
static const double spaceLG = 16.0;
static const double spaceXL = 20.0;
static const double space2XL = 24.0;
static const double space3XL = 32.0;
static const double space4XL = 40.0;
```

### **Border Radius**

```dart
static const double radiusXS = 4.0;
static const double radiusSM = 6.0;
static const double radiusMD = 8.0;
static const double radiusLG = 12.0;
static const double radiusXL = 16.0;
static const double radius2XL = 20.0;
```

### **Component Sizes**

```dart
// Button Heights
static const double buttonHeightSM = 32.0;
static const double buttonHeightMD = 40.0;
static const double buttonHeightLG = 48.0;
static const double buttonHeightXL = 56.0;

// Icon Sizes
static const double iconSizeSM = 16.0;
static const double iconSizeMD = 20.0;
static const double iconSizeLG = 24.0;
static const double iconSizeXL = 32.0;
```

## 🔧 Theme Service (`theme_service.dart`)

### **Theme Modes**

```dart
enum AppThemeMode {
  light,    // Always light theme
  dark,     // Always dark theme
  system,   // Follow system setting
}
```

### **Theme Colors**

```dart
enum AppThemeColor {
  blue,     // Default blue theme
  purple,   // Purple theme
  green,    // Green theme
  orange,   // Orange theme
  red,      // Red theme
  teal,     // Teal theme
  indigo,   // Indigo theme
}
```

### **Key Methods**

```dart
// Initialize theme service (call in main())
await themeService.initialize();

// Change theme mode
await themeService.setThemeMode(AppThemeMode.dark);

// Change theme color
await themeService.setThemeColor(AppThemeColor.purple);

// Get current themes
ThemeData lightTheme = themeService.lightTheme;
ThemeData darkTheme = themeService.darkTheme;
```

## 🎨 Usage Examples

### **1. Basic Setup in main.dart**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme service
  final themeService = ThemeService();
  await themeService.initialize();

  runApp(MyApp(themeService: themeService));
}

class MyApp extends StatelessWidget {
  final ThemeService themeService;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: themeService,
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.flutterThemeMode,
            home: HomeScreen(),
          );
        },
      ),
    );
  }
}
```

### **2. Using Theme Constants in Widgets**

```dart
// Spacing
Padding(
  padding: EdgeInsets.all(AppThemeConstants.spaceLG),
  child: Text('Hello'),
)

// Colors
Container(
  color: AppThemeConstants.primaryBlue,
  child: Text('Themed Container'),
)

// Border Radius
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppThemeConstants.radiusLG),
  ),
)

// Typography
Text(
  'Custom Text',
  style: TextStyle(
    fontSize: AppThemeConstants.fontSizeLG,
    fontWeight: AppThemeConstants.fontWeightSemiBold,
  ),
)
```

### **3. Changing Themes Programmatically**

```dart
// In any widget with access to context
ElevatedButton(
  onPressed: () {
    // Switch to dark mode
    context.read<ThemeService>().setThemeMode(AppThemeMode.dark);
  },
  child: Text('Switch to Dark'),
)

ElevatedButton(
  onPressed: () {
    // Switch to purple theme
    context.read<ThemeService>().setThemeColor(AppThemeColor.purple);
  },
  child: Text('Switch to Purple'),
)
```

### **4. Creating Theme-Aware Widgets**

```dart
class ThemedCard extends StatelessWidget {
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppThemeConstants.spaceLG),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppThemeConstants.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: AppThemeConstants.elevationMD,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
```

### **5. Responsive Design with Theme Constants**

```dart
// Get responsive font size
double fontSize = AppThemeConstants.getResponsiveFontSize(
  MediaQuery.of(context).size.width,
  AppThemeConstants.fontSizeLG,
);

// Get responsive spacing
double spacing = AppThemeConstants.getResponsiveSpacing(
  MediaQuery.of(context).size.width,
  AppThemeConstants.spaceLG,
);
```

## 🔄 Theme Persistence

Themes are automatically saved to device storage using `SharedPreferences`:

- **Theme Mode**: Saved as string ('light', 'dark', 'system')
- **Theme Color**: Saved as string ('blue', 'purple', 'green', etc.)
- **Auto-restore**: Themes are restored when app starts

## 🎯 Custom Theme Implementation

### **Adding New Theme Colors**

1. **Add color to `AppThemeConstants`**:

```dart
static const Color primaryYellow = Color(0xFFFFC107);
```

2. **Add to enum in `ThemeService`**:

```dart
enum AppThemeColor {
  // ... existing colors
  yellow,
}
```

3. **Update color getter methods**:

```dart
Color get primaryColor {
  switch (_themeColor) {
    // ... existing cases
    case AppThemeColor.yellow:
      return AppThemeConstants.primaryYellow;
  }
}
```

4. **Update available colors list**:

```dart
List<Map<String, dynamic>> get availableThemeColors {
  return [
    // ... existing colors
    {'name': 'Yellow', 'color': AppThemeConstants.primaryYellow, 'value': AppThemeColor.yellow},
  ];
}
```

### **Customizing Component Themes**

You can customize individual component themes in the `ThemeService`:

```dart
// Custom Button Theme
elevatedButtonTheme: ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: AppThemeConstants.white,
    elevation: AppThemeConstants.elevationMD,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppThemeConstants.radiusLG),
    ),
    minimumSize: Size(0, AppThemeConstants.buttonHeightLG),
  ),
),
```

## 🧪 Testing Theme System

### **Run Theme Demo**

1. Use the theme demo app:

```bash
flutter run lib/theme_demo.dart
```

2. Test features:
   - ✅ Switch between light/dark modes
   - ✅ Try all 7 color themes
   - ✅ Check theme persistence (restart app)
   - ✅ View component showcase

### **Manual Testing Checklist**

- [ ] Theme switching works instantly
- [ ] Themes persist after app restart
- [ ] All components use theme colors
- [ ] System theme changes are detected
- [ ] Settings screen functions properly
- [ ] No visual glitches during theme switch

## 📱 Design System Benefits

### **✅ Consistency**

- All spacing, colors, and typography use constants
- Consistent component appearance across app
- Easy to maintain design coherence

### **✅ Accessibility**

- Proper contrast ratios in both light and dark themes
- System theme support for user preferences
- Semantic color usage (success, warning, error)

### **✅ Maintainability**

- Central theme management
- Easy to add new themes
- Consistent naming conventions

### **✅ Performance**

- Themes cached in memory
- Efficient theme switching
- Minimal rebuilds during theme changes

## 🚀 Next Steps

1. **Add more theme colors** (pink, cyan, etc.)
2. **Implement seasonal themes** (Christmas, Halloween, etc.)
3. **Add theme animations** for smooth transitions
4. **Create theme presets** for different user types
5. **Add custom accent colors** for power users

The multi-theme system provides a solid foundation for creating beautiful, consistent, and user-customizable interfaces! 🎨✨
