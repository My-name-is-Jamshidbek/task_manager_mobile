# Firebase Setup Instructions

This document provides step-by-step instructions to set up Firebase for your Flutter Task Manager app.

## Prerequisites

1. **Flutter development environment** is set up
2. **Firebase CLI** installed globally
3. **Google account** with access to Firebase Console

## Step 1: Install Firebase CLI

If you haven't installed Firebase CLI yet:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login
```

## Step 2: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `task-manager-mobile` (or your preferred name)
4. Enable Google Analytics (optional but recommended)
5. Wait for project creation to complete

## Step 3: Configure Firebase for Flutter

1. **Install FlutterFire CLI**:

```bash
dart pub global activate flutterfire_cli
```

2. **Configure Firebase for your Flutter project**:

```bash
# Navigate to your project directory
cd /Users/jamshidbek/FlutterProjects/task_manager_mobile

# Configure Firebase
flutterfire configure
```

3. **Select your Firebase project** when prompted
4. **Select platforms** you want to support:

   - ✅ Android
   - ✅ iOS
   - ⬜ Web (optional)
   - ⬜ macOS (optional)

5. **FlutterFire CLI will**:
   - Generate `firebase_options.dart` with your configuration
   - Download `google-services.json` for Android
   - Download `GoogleService-Info.plist` for iOS

## Step 4: Enable Firebase Cloud Messaging

1. In Firebase Console, go to your project
2. Navigate to **Project Settings** (gear icon)
3. Go to **Cloud Messaging** tab
4. **Android**:
   - Your `google-services.json` should already have FCM configured
5. **iOS**:
   - Upload your **APNs Authentication Key** or **APNs Certificates**
   - For development: Upload development certificate
   - For production: Upload production certificate

## Step 5: Configure Android (if targeting Android)

1. **Verify `google-services.json`** is in `android/app/`
2. **Update package name** in `android/app/build.gradle.kts`:
   ```kotlin
   defaultConfig {
       applicationId = "com.yourcompany.task_manager" // Update this
   }
   ```
3. **Update namespace** in `android/app/build.gradle.kts`:
   ```kotlin
   android {
       namespace = "com.yourcompany.task_manager" // Update this
   }
   ```

## Step 6: Configure iOS (if targeting iOS)

1. **Verify `GoogleService-Info.plist`** is in `ios/Runner/`
2. **Open iOS project** in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
3. **Add `GoogleService-Info.plist`** to Xcode project:
   - Right-click on `Runner` in Xcode
   - Select "Add Files to 'Runner'"
   - Choose `GoogleService-Info.plist`
   - ✅ Ensure "Add to target: Runner" is checked
4. **Enable Push Notifications** capability:
   - Select `Runner` project in Xcode
   - Go to "Signing & Capabilities" tab
   - Click "+ Capability"
   - Add "Push Notifications"
5. **Update Bundle Identifier** to match Firebase project:
   - In Xcode, select `Runner` target
   - Update Bundle Identifier in "General" tab

## Step 7: Replace Firebase Options

After running `flutterfire configure`, replace the content of `lib/firebase_options.dart` with the generated file.

## Step 8: Test Firebase Integration

1. **Run the app**:

   ```bash
   flutter run
   ```

2. **Check console logs** for Firebase initialization messages:

   - ✅ "Firebase initialized successfully"
   - ✅ "FCM Token obtained"
   - ✅ "Notification permissions granted"

3. **Test Firebase messaging**:
   - Use Firebase Console to send test messages
   - Or use the test screen in your app

## Step 9: Backend Integration

Update your backend API base URL in the app:

1. **In your AuthProvider or app config**, set:

   ```dart
   const String apiBaseUrl = 'https://your-api-domain.com/api';
   ```

2. **Test token registration** with your backend using the API endpoints:

   - `POST /firebase/tokens` - Register token
   - `DELETE /firebase/tokens` - Deactivate token (auth)
   - `DELETE /firebase/tokens/public` - Deactivate token (no auth)

   The app first tries the authenticated delete; if it receives a 401, it will automatically call the public endpoint.

## Testing Firebase Messaging

### Send Test Message from Firebase Console

1. Go to Firebase Console → **Cloud Messaging**
2. Click **"Send your first message"**
3. Enter:
   - **Notification title**: "Test Notification"
   - **Notification text**: "This is a test message"
4. Click **"Next"**
5. **Target**: Select your app
6. Click **"Review"** and **"Publish"**

### Send Custom Data Message

For testing with custom data (like navigation), use this JSON in Firebase Console's "Additional options" → "Custom data":

```json
{
  "screen": "task_detail",
  "task_id": "123"
}
```

## Troubleshooting

### Common Issues:

1. **"FirebaseOptions not configured"**

   - Run `flutterfire configure` again
   - Verify `firebase_options.dart` exists and has correct values

2. **Android build fails**

   - Check `google-services.json` is in `android/app/`
   - Verify Google Services plugin is applied in `build.gradle.kts`

3. **iOS build fails**

   - Check `GoogleService-Info.plist` is added to Xcode project
   - Verify Bundle ID matches Firebase project

4. **No FCM token received**

   - Check internet connection
   - Verify Firebase project is configured correctly
   - Check app permissions for notifications

5. **Notifications not appearing**
   - Check notification permissions are granted
   - Verify app is not in "Do Not Disturb" mode
   - Test on physical device (not simulator for iOS)

### Debug Commands:

```bash
# Check Firebase project list
firebase projects:list

# Check current Firebase project
firebase use

# Re-configure Firebase
flutterfire configure

# Clean and rebuild
flutter clean && flutter pub get

# Check dependencies
flutter doctor
```

## Production Checklist

Before releasing to production:

- ✅ Configure production APNs certificates (iOS)
- ✅ Test on physical devices
- ✅ Update API base URL to production
- ✅ Test token registration with production backend
- ✅ Test notification delivery
- ✅ Set up proper Firebase security rules
- ✅ Configure proper notification icons and sounds
- ✅ Test deep linking from notifications

---

For additional help, refer to:

- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
