# 🎨 CoreUI Theme System Documentation

## 📋 Overview

The Flutter Task Manager now uses **CoreUI v5.3 Design System** - a professional, Bootstrap-based design system that provides:

- ✅ **6 CoreUI semantic color themes** (Primary, Secondary, Success, Danger, Warning, Info)
- ✅ **Light/Dark/System theme modes**
- ✅ **CoreUI-compliant spacing and typography**
- ✅ **Bootstrap 5 responsive breakpoints**
- ✅ **Professional component design**
- ✅ **Persistent theme preferences**

## 🌈 CoreUI Brand Colors

### **Primary Brand Colors**

```dart
// CoreUI Official Brand Colors
static const Color primary = Color(0xFF5856D6);     // #5856d6 - Brand Primary
static const Color secondary = Color(0xFF6B7785);   // #6b7785 - Brand Secondary
static const Color success = Color(0xFF1B9E3E);     // #1b9e3e - Brand Success
static const Color danger = Color(0xFFE55353);      // #e55353 - Brand Danger
static const Color warning = Color(0xFFF9B115);     // #f9b115 - Brand Warning
static const Color info = Color(0xFF3399FF);        // #3399ff - Brand Info
static const Color light = Color(0xFFF3F4F7);       // #f3f4f7 - Brand Light
static const Color dark = Color(0xFF212631);        // #212631 - Brand Dark
```

### **CoreUI Gray Scale**

```dart
// Bootstrap 5 compatible gray scale
static const Color gray100 = Color(0xFFF8F9FA);     // #f8f9fa
static const Color gray200 = Color(0xFFE9ECEF);     // #e9ecef
static const Color gray300 = Color(0xFFDEE2E6);     // #dee2e6
static const Color gray400 = Color(0xFFCED4DA);     // #ced4da
static const Color gray500 = Color(0xFFADB5BD);     // #adb5bd
static const Color gray600 = Color(0xFF6C757D);     // #6c757d
static const Color gray700 = Color(0xFF495057);     // #495057
static const Color gray800 = Color(0xFF343A40);     // #343a40
static const Color gray900 = Color(0xFF212529);     // #212529
```

## 📐 CoreUI Design Tokens

### **Bootstrap 5 Spacing System**

```dart
// Based on 0.25rem (4px) increments
static const double space1 = 4.0;    // 0.25rem
static const double space2 = 8.0;    // 0.5rem
static const double space3 = 12.0;   // 0.75rem
static const double space4 = 16.0;   // 1rem
static const double space5 = 20.0;   // 1.25rem
static const double space6 = 24.0;   // 1.5rem
static const double space8 = 32.0;   // 2rem
static const double space10 = 40.0;  // 2.5rem
static const double space12 = 48.0;  // 3rem
```

### **Bootstrap 5 Typography**

```dart
// CoreUI/Bootstrap heading scale
static const double fontSizeH1 = 40.0;  // 2.5rem
static const double fontSizeH2 = 32.0;  // 2rem
static const double fontSizeH3 = 28.0;  // 1.75rem
static const double fontSizeH4 = 24.0;  // 1.5rem
static const double fontSizeH5 = 20.0;  // 1.25rem
static const double fontSizeH6 = 16.0;  // 1rem
```

### **Bootstrap 5 Border Radius**

```dart
static const double radiusSM = 2.0;   // 0.125rem
static const double radiusMD = 4.0;   // 0.25rem
static const double radiusLG = 6.0;   // 0.375rem
static const double radiusXL = 8.0;   // 0.5rem
```

### **Bootstrap 5 Breakpoints**

```dart
static const double breakpointSM = 576.0;   // ≥576px
static const double breakpointMD = 768.0;   // ≥768px
static const double breakpointLG = 992.0;   // ≥992px
static const double breakpointXL = 1200.0;  // ≥1200px
static const double breakpoint2XL = 1400.0; // ≥1400px
```

## 🎨 Theme Configuration

### **Theme Colors (Updated for CoreUI)**

```dart
enum AppThemeColor {
  primary,   // CoreUI Primary Purple (#5856d6)
  secondary, // CoreUI Secondary Gray (#6b7785)
  success,   // CoreUI Success Green (#1b9e3e)
  danger,    // CoreUI Danger Red (#e55353)
  warning,   // CoreUI Warning Yellow (#f9b115)
  info,      // CoreUI Info Blue (#3399ff)
}
```

### **Theme Modes**

```dart
enum AppThemeMode {
  light,    // Always light theme
  dark,     // Always dark theme
  system,   // Follow system setting
}
```

## 🎯 Usage Examples

### **1. Using CoreUI Colors**

```dart
// Primary brand colors
Container(
  color: AppThemeConstants.primary,        // CoreUI Primary Purple
  child: Text('Primary Action'),
)

// Status colors
Container(
  color: AppThemeConstants.success,        // CoreUI Success Green
  child: Text('Success Message'),
)

// Gray scale
Container(
  color: AppThemeConstants.gray100,        // Light gray background
  child: Text('Content'),
)
```

### **2. Using CoreUI Spacing**

```dart
// Bootstrap-compatible spacing
Padding(
  padding: EdgeInsets.all(AppThemeConstants.space4),     // 1rem (16px)
  child: Column(
    children: [
      Text('Title'),
      SizedBox(height: AppThemeConstants.space2),        // 0.5rem (8px)
      Text('Content'),
    ],
  ),
)
```

### **3. Using CoreUI Typography**

```dart
// CoreUI heading styles
Text(
  'Main Title',
  style: TextStyle(
    fontSize: AppThemeConstants.fontSizeH1,              // 2.5rem (40px)
    fontWeight: AppThemeConstants.fontWeightBold,
  ),
)

Text(
  'Subtitle',
  style: TextStyle(
    fontSize: AppThemeConstants.fontSizeH4,              // 1.5rem (24px)
    fontWeight: AppThemeConstants.fontWeightSemiBold,
  ),
)
```

### **4. Responsive Design with CoreUI Breakpoints**

```dart
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;

  // Use CoreUI breakpoints
  if (AppThemeConstants.isMobile(screenWidth)) {
    return MobileLayout();
  } else if (AppThemeConstants.isTablet(screenWidth)) {
    return TabletLayout();
  } else {
    return DesktopLayout();
  }
}
```

### **5. Theme Switching**

```dart
// Switch to CoreUI success theme
context.read<ThemeService>().setThemeColor(AppThemeColor.success);

// Switch to dark mode
context.read<ThemeService>().setThemeMode(AppThemeMode.dark);

// Get current theme info
final themeService = context.read<ThemeService>();
print('Current theme: ${themeService.currentThemeName}');
print('Current mode: ${themeService.currentThemeModeName}');
```

## 🧪 Testing CoreUI Theme

### **Run CoreUI Demo**

```bash
# Run the CoreUI demo app
flutter run lib/coreui_demo.dart
```

### **Demo Features**

- ✅ **Colors Page**: View all CoreUI brand colors and gray scale
- ✅ **Components Page**: See CoreUI-styled buttons, cards, forms, lists
- ✅ **Typography Page**: Browse CoreUI heading and text styles
- ✅ **Theme Settings**: Switch between 6 color themes and 3 modes
- ✅ **Live Preview**: See changes instantly without restart

## 🎨 CoreUI Component Examples

### **CoreUI Button Styles**

```dart
// Primary button (CoreUI styled)
ElevatedButton(
  onPressed: () {},
  child: Text('Primary Action'),
)

// Outline button
OutlinedButton(
  onPressed: () {},
  child: Text('Secondary Action'),
)

// Text button
TextButton(
  onPressed: () {},
  child: Text('Tertiary Action'),
)
```

### **CoreUI Card Component**

```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(AppThemeConstants.space4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Title',
          style: TextStyle(
            fontSize: AppThemeConstants.fontSizeH5,
            fontWeight: AppThemeConstants.fontWeightSemiBold,
          ),
        ),
        SizedBox(height: AppThemeConstants.space2),
        Text('Card content with proper CoreUI spacing and typography.'),
        SizedBox(height: AppThemeConstants.space3),
        Row(
          children: [
            TextButton(onPressed: () {}, child: Text('Action')),
            TextButton(onPressed: () {}, child: Text('Cancel')),
          ],
        ),
      ],
    ),
  ),
)
```

### **CoreUI Form Elements**

```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Email Address',
    hintText: 'Enter your email',
    prefixIcon: Icon(Icons.email),
    // CoreUI styling automatically applied
  ),
)
```

### **CoreUI Status Chips**

```dart
// Success status
Chip(
  label: Text('Completed'),
  backgroundColor: AppThemeConstants.success.withOpacity(0.1),
  labelStyle: TextStyle(color: AppThemeConstants.success),
)

// Warning status
Chip(
  label: Text('Pending'),
  backgroundColor: AppThemeConstants.warning.withOpacity(0.1),
  labelStyle: TextStyle(color: AppThemeConstants.warning),
)

// Danger status
Chip(
  label: Text('Overdue'),
  backgroundColor: AppThemeConstants.danger.withOpacity(0.1),
  labelStyle: TextStyle(color: AppThemeConstants.danger),
)
```

## 📊 Color Variations

### **Automatic Color Variations**

```dart
// Get lighter/darker variations
Color primaryLight = AppThemeConstants.getColorVariation(
  AppThemeConstants.primary,
  'light'
);

Color primaryDark = AppThemeConstants.getColorVariation(
  AppThemeConstants.primary,
  'dark'
);
```

### **Available Variations**

- ✅ **light**: 20% lighter version
- ✅ **dark**: 20% darker version
- ✅ **lighter**: 40% lighter version
- ✅ **darker**: 40% darker version

## 🎯 CoreUI Benefits

### **✅ Professional Design**

- Industry-standard CoreUI design system
- Bootstrap 5 compatibility
- Consistent with web CoreUI themes

### **✅ Accessibility**

- WCAG-compliant color contrasts
- Semantic color usage
- Screen reader friendly

### **✅ Developer Experience**

- Easy to implement and customize
- Consistent naming conventions
- Comprehensive documentation

### **✅ Responsive Design**

- Bootstrap 5 breakpoint system
- Mobile-first approach
- Adaptive components

## 🚀 Next Steps

1. **Add CoreUI Icons**: Integrate CoreUI icon library
2. **Advanced Components**: Implement CoreUI tables, modals, etc.
3. **Dark Theme Refinement**: Perfect dark mode variations
4. **Custom Themes**: Create branded theme variants
5. **Animation System**: Add CoreUI-style transitions

The CoreUI theme system provides a solid foundation for creating professional, enterprise-grade Flutter applications! 🎨✨

## 📱 Quick Reference

### **Most Used Colors**

```dart
AppThemeConstants.primary    // #5856d6 - Main brand color
AppThemeConstants.success    // #1b9e3e - Success/completed
AppThemeConstants.warning    // #f9b115 - Warning/pending
AppThemeConstants.danger     // #e55353 - Error/urgent
AppThemeConstants.info       // #3399ff - Information
AppThemeConstants.gray600    // #6c757d - Text secondary
```

### **Most Used Spacing**

```dart
AppThemeConstants.space2     // 8px  - Small gaps
AppThemeConstants.space3     // 12px - Medium gaps
AppThemeConstants.space4     // 16px - Large gaps (most common)
AppThemeConstants.space6     // 24px - Section spacing
```

### **Most Used Typography**

```dart
AppThemeConstants.fontSizeH4     // 24px - Page titles
AppThemeConstants.fontSizeH5     // 20px - Section titles
AppThemeConstants.fontSizeLG     // 16px - Body text
AppThemeConstants.fontSizeMD     // 14px - Secondary text
```

Happy coding with CoreUI! 🎉
