# Quick Fix Checklist

## ✅ Completed Automatically
- [x] Updated `firebase_options.dart` with correct project credentials
- [x] Added better error handling in `main.dart`
- [x] Added detailed error messages in `onboarding_screen.dart`
- [x] Verified `google-services.json` has correct configuration

## 🔧 You Need to Do (CRITICAL)

### 1. Enable Anonymous Authentication (REQUIRED)
⚠️ **The Skip button will NOT work without this!**

1. Open [Firebase Console](https://console.firebase.google.com)
2. Select project: **plp-ai-tutor**
3. Go to **Authentication** → **Sign-in method**
4. Click on **Anonymous**
5. Toggle **Enable** → Click **Save**

### 2. Clean and Rebuild
```bash
flutter clean
flutter pub get
flutter run
```

### 3. Test
- Click "Skip" on onboarding screen
- Should authenticate anonymously and go to HomeScreen
- Check console for any error messages

## 🐛 If Still Having Issues

### Mobile shows only logo:
- Check debug console for Firebase errors
- Verify `google-services.json` is in `android/app/`
- Try: `flutter clean && flutter pub get`

### Web shows "Operation Not Allowed":
- Anonymous auth is not enabled (see Step 1 above)

### Other errors:
- Read error message carefully (now more detailed)
- Check `FIREBASE_FIX_GUIDE.md` for detailed troubleshooting
- Verify internet connection

## 📱 Quick Command Reference

```bash
# Clean build
flutter clean && flutter pub get

# Run on web
flutter run -d chrome

# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios

# Check for errors
flutter doctor
```

## ✨ What Changed

**Before**:
- `firebase_options.dart` had old project: `ai-tutor-cedad`
- `google-services.json` had new project: `plp-ai-tutor`
- ❌ Mismatch caused initialization failure

**After**:
- ✅ Both files now use: `plp-ai-tutor`
- ✅ Better error messages
- ✅ Detailed logging for debugging
