# AI Tutor App Setup Guide

## Environment Variables Configuration

This app now reads the Gemini API key from a `.env` file for better security and easier configuration.

### Setup Steps

1. **Copy the example environment file**:
   ```bash
   cp .env.example .env
   ```

2. **Edit the `.env` file** and add your actual API keys:
   ```
   VITE_SUPABASE_URL=https://your-project-id.supabase.co
   VITE_SUPABASE_SUPABASE_ANON_KEY=your_supabase_anon_key_here
   GEMINI_API_KEY=your_gemini_api_key_here
   ```

3. **Get your Gemini API Key**:
   - Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Sign in with your Google account
   - Create a new API key
   - Copy the key and paste it into your `.env` file

4. **Install dependencies**:
   ```bash
   flutter pub get
   ```

5. **Run the app**:
   ```bash
   flutter run
   ```

## Platform Support

This Flutter app supports multiple platforms:

### ✅ Fully Supported Platforms

1. **Android** - Full Firebase and all features work
2. **iOS** - Full Firebase and all features work
3. **macOS** - Full Firebase and all features work
4. **Web** - Full Firebase and all features work
5. **Windows** - Full Firebase and all features work

### Firebase Configuration

The app includes Firebase configuration for all supported platforms in `lib/firebase_options.dart`:
- Android
- iOS
- macOS
- Web
- Windows

### Platform-Specific Notes

#### Web
- Works in all modern browsers (Chrome, Firefox, Safari, Edge)
- Firebase Authentication works fully
- All AI features (tutorials, quizzes, chat) work perfectly
- Run with: `flutter run -d chrome` or `flutter run -d web-server`

#### Windows
- Firebase Authentication works via the web implementation
- All features work exactly like other platforms
- Run with: `flutter run -d windows`

#### Linux
- Currently not configured for Firebase
- To add Linux support, run: `flutterfire configure` and select Linux

## Testing Different Platforms

### Test on Web:
```bash
flutter run -d chrome
```

### Test on Windows (if on Windows):
```bash
flutter run -d windows
```

### Test on Android (with device/emulator):
```bash
flutter run -d android
```

### Test on iOS (Mac only with device/simulator):
```bash
flutter run -d ios
```

## Important Security Notes

- **Never commit your `.env` file** to version control (it's already in `.gitignore`)
- **Never share your API keys** publicly
- Each developer should have their own `.env` file with their own API keys
- The `.env.example` file is safe to commit as it only contains placeholder values

## Dependencies

The app uses `flutter_dotenv` package to load environment variables from the `.env` file. This is automatically installed when you run `flutter pub get`.

## Troubleshooting

### API Key Not Working
- Ensure your `.env` file is in the root directory of the project
- Make sure the file is named exactly `.env` (not `.env.txt`)
- Verify your API key is valid and not expired
- Check that there are no extra spaces in the `.env` file

### App Won't Build
- Run `flutter clean`
- Run `flutter pub get`
- Try building again

### Platform-Specific Issues
- Make sure you have the required SDKs installed for your target platform
- For Windows: Visual Studio 2022 with Desktop development with C++ workload
- For Web: Any modern browser
- For Android: Android Studio and Android SDK
- For iOS/macOS: Xcode (Mac only)
