# 🎨 Theme Quick Reference

## 🚀 Quick Start

### Initialize Theme Service

```dart
// In main.dart
final themeService = ThemeService();
await themeService.initialize();
```

### Use in MaterialApp

```dart
MaterialApp(
  theme: themeService.lightTheme,
  darkTheme: themeService.darkTheme,
  themeMode: themeService.flutterThemeMode,
)
```

## 🎯 Common Usage

### Theme-Aware Colors

```dart
// Get theme-aware colors
Color primary = Theme.of(context).primaryColor;
Color background = Theme.of(context).scaffoldBackgroundColor;
Color surface = Theme.of(context).cardColor;
Color onSurface = Theme.of(context).colorScheme.onSurface;
```

### Spacing Constants

```dart
// Use consistent spacing
padding: EdgeInsets.all(AppThemeConstants.spaceLG),        // 16px
margin: EdgeInsets.symmetric(
  horizontal: AppThemeConstants.spaceXL,                   // 20px
  vertical: AppThemeConstants.spaceMD,                     // 12px
),
```

### Typography

```dart
// Use consistent text styles
Text(
  'Title',
  style: Theme.of(context).textTheme.headlineLarge,
)

// Or with constants
Text(
  'Custom',
  style: TextStyle(
    fontSize: AppThemeConstants.fontSizeLG,               // 16px
    fontWeight: AppThemeConstants.fontWeightSemiBold,     // 600
  ),
)
```

### Border Radius

```dart
// Consistent border radius
BorderRadius.circular(AppThemeConstants.radiusLG),       // 12px
BorderRadius.circular(AppThemeConstants.radiusXL),       // 16px
```

## 🔄 Change Themes

### Switch Theme Mode

```dart
// Dark mode
context.read<ThemeService>().setThemeMode(AppThemeMode.dark);

// Light mode
context.read<ThemeService>().setThemeMode(AppThemeMode.light);

// System mode
context.read<ThemeService>().setThemeMode(AppThemeMode.system);
```

### Switch Theme Color

```dart
// Purple theme
context.read<ThemeService>().setThemeColor(AppThemeColor.purple);

// Green theme
context.read<ThemeService>().setThemeColor(AppThemeColor.green);
```

## 📱 Common Components

### Themed Button

```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Theme.of(context).primaryColor,
    padding: EdgeInsets.symmetric(
      horizontal: AppThemeConstants.spaceXL,
      vertical: AppThemeConstants.spaceMD,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppThemeConstants.radiusLG),
    ),
  ),
  onPressed: () {},
  child: Text('Themed Button'),
)
```

### Themed Card

```dart
Card(
  margin: EdgeInsets.all(AppThemeConstants.spaceLG),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppThemeConstants.radiusLG),
  ),
  child: Padding(
    padding: EdgeInsets.all(AppThemeConstants.spaceLG),
    child: Column(children: [...]),
  ),
)
```

### Status Colors

```dart
// Task priority colors
Color priorityColor = AppThemeConstants.priorityHigh;      // Red
Color priorityColor = AppThemeConstants.priorityMedium;    // Orange
Color priorityColor = AppThemeConstants.priorityLow;       // Green
Color priorityColor = AppThemeConstants.priorityUrgent;    // Purple
```

## 📊 Available Themes

### Theme Modes

- ✅ `AppThemeMode.light` - Always light
- ✅ `AppThemeMode.dark` - Always dark
- ✅ `AppThemeMode.system` - Follow system

### Theme Colors

- 🔵 `AppThemeColor.blue` - Default blue
- 🟣 `AppThemeColor.purple` - Purple theme
- 🟢 `AppThemeColor.green` - Green theme
- 🟠 `AppThemeColor.orange` - Orange theme
- 🔴 `AppThemeColor.red` - Red theme
- 🟦 `AppThemeColor.teal` - Teal theme
- 🟫 `AppThemeColor.indigo` - Indigo theme

## 🛠️ Development Tips

### Listen to Theme Changes

```dart
Consumer<ThemeService>(
  builder: (context, themeService, child) {
    return Container(
      color: themeService.isDarkMode ? Colors.black : Colors.white,
      child: child,
    );
  },
)
```

### Check Current Theme

```dart
// Check if dark mode
bool isDark = Theme.of(context).brightness == Brightness.dark;

// Get current theme service
ThemeService themeService = context.read<ThemeService>();
bool isDarkMode = themeService.isDarkMode;
AppThemeColor currentColor = themeService.themeColor;
```

### Responsive Design

```dart
// Get screen size
Size screenSize = MediaQuery.of(context).size;

// Responsive spacing
double spacing = screenSize.width > 600
  ? AppThemeConstants.spaceXL
  : AppThemeConstants.spaceLG;
```

## 🎨 Color Palette

### Primary Colors

```dart
AppThemeConstants.primaryBlue     // #2196F3
AppThemeConstants.primaryPurple   // #9C27B0
AppThemeConstants.primaryGreen    // #4CAF50
AppThemeConstants.primaryOrange   // #FF9800
AppThemeConstants.primaryRed      // #E91E63
AppThemeConstants.primaryTeal     // #009688
AppThemeConstants.primaryIndigo   // #3F51B5
```

### Neutral Colors

```dart
AppThemeConstants.white           // #FFFFFF
AppThemeConstants.black           // #000000
AppThemeConstants.grey50          // #FAFAFA
AppThemeConstants.grey100         // #F5F5F5
AppThemeConstants.grey200         // #EEEEEE
AppThemeConstants.grey300         // #E0E0E0
AppThemeConstants.grey400         // #BDBDBD
AppThemeConstants.grey500         // #9E9E9E
AppThemeConstants.grey600         // #757575
AppThemeConstants.grey700         // #616161
AppThemeConstants.grey800         // #424242
AppThemeConstants.grey900         // #212121
```

## 🔥 Pro Tips

1. **Always use theme constants** instead of hardcoded values
2. **Test both light and dark themes** during development
3. **Use semantic colors** (primary, secondary, error, etc.)
4. **Keep consistent spacing** throughout the app
5. **Test theme switching** for performance and visual glitches

## 🧪 Testing

Run the theme demo:

```bash
flutter run lib/theme_demo.dart
```

The quick reference is your go-to guide for efficient theme development! 🚀
