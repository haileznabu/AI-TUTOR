# Firebase Configuration Fix Guide

## Problem Summary
Your Firebase configuration was mismatched between `google-services.json` and `firebase_options.dart`, causing the app to freeze on mobile and authentication to fail on web.

## What Was Fixed

### 1. Updated `firebase_options.dart`
Updated all platform configurations to match your new Firebase project:
- **Project ID**: `plp-ai-tutor`
- **Project Number**: `1056660119849`
- **API Key**: `AIzaSyBUK7Tqltu29luyvRM9s-rxLXrfg6pSloA`

### 2. Enhanced Error Handling
- Added detailed error messages for Firebase initialization in `main.dart`
- Added specific error handling for anonymous authentication in `onboarding_screen.dart`
- Now shows user-friendly error messages for common issues

## Critical Next Steps

### Step 1: Enable Anonymous Authentication in Firebase Console
**This is MANDATORY for the Skip button to work!**

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **plp-ai-tutor**
3. Click on **Authentication** in the left sidebar
4. Click on **Sign-in method** tab
5. Find **Anonymous** in the list of providers
6. Click on it and toggle **Enable**
7. Click **Save**

### Step 2: Download iOS Configuration (If Using iOS)
1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll down to **Your apps**
3. Find your iOS app or click **Add app** → **iOS**
4. Download the `GoogleService-Info.plist` file
5. Place it in: `ios/Runner/GoogleService-Info.plist`

### Step 3: Clean Build
Run these commands to clean and rebuild:

```bash
# Clean the project
flutter clean

# Get dependencies
flutter pub get

# For Android
flutter build apk --debug

# For iOS (on macOS)
flutter build ios --debug

# For Web
flutter build web
```

### Step 4: Test the App
1. **On Web**: Run `flutter run -d chrome` and click Skip - it should authenticate anonymously
2. **On Mobile**: The app should now proceed past the logo screen

## Troubleshooting

### If Mobile App Still Freezes
- Check the debug console for Firebase initialization errors
- Ensure `google-services.json` is in `android/app/` directory
- For iOS, ensure `GoogleService-Info.plist` is properly added to Xcode project

### If "Operation Not Allowed" Error Appears
- You haven't enabled Anonymous Authentication in Firebase Console (see Step 1)

### If "Network Request Failed" Error Appears
- Check your internet connection
- Verify Firebase project is active (not deleted or disabled)

### If Authentication Works But App Doesn't Navigate
- Check console logs for navigation errors
- Verify HomeScreen is properly configured

## What to Check in Firebase Console

1. **Authentication → Sign-in method**
   - Anonymous: Should be **Enabled**
   - Email/Password: Enable if you plan to use it

2. **Authentication → Users**
   - After clicking Skip, you should see anonymous users appear here

3. **Project Settings → General**
   - Verify your app IDs match:
     - Android: `com.example.ai_tutor`
     - iOS: `com.example.aiTutor`

## Additional Notes

- The configuration now uses debug prints to log Firebase initialization
- Error messages are more descriptive and user-friendly
- Both platforms (web and mobile) now use the same Firebase project
