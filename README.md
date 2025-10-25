# AI Learning Tutor App

A comprehensive Flutter mobile application that provides personalized AI-powered learning experiences with Firebase Authentication and Firestore database integration.

## Features

- **Onboarding Flow**: Beautiful onboarding screens introducing the app features
- **Firebase Authentication**:
  - Email/Password authentication
  - Anonymous authentication (for quick access)
  - Seamless authentication state management
- **Firestore Database**:
  - User progress tracking
  - Visited topics storage
  - Tutorial caching to avoid regeneration
  - Quiz results tracking
- **AI-Powered Learning**:
  - AI-generated tutorials for various topics
  - Interactive quizzes
  - Personalized learning paths
- **Topic Explorer**: Browse and search through various learning topics
- **Progress Tracking**: Track your learning progress across different topics
- **Chat Interface**: Interactive AI tutor chat

## Project Structure

```
lib/
├── constants/        # App-wide constants
├── models/          # Data models (Topic, Quiz, Tutorial, etc.)
├── providers/       # Riverpod state management providers
├── screens/         # UI screens (Home, Auth, Onboarding, etc.)
├── services/        # Business logic services
│   ├── ai_service.dart           # AI integration
│   ├── firebase_auth_service.dart # Firebase authentication
│   ├── firestore_service.dart    # Firestore database operations
│   ├── learning_repository.dart  # Main repository
│   └── supabase_service.dart     # Supabase integration
└── widgets/         # Reusable UI components
```

## Prerequisites

- Flutter SDK (3.9.2 or higher)
- Firebase project with:
  - Authentication enabled (Email/Password and Anonymous)
  - Firestore database created
  - Android/iOS apps configured
- Gemini AI API key for AI features
- Supabase project (optional, for additional features)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd ai_tutor
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Environment Variables

Create a `.env` file in the project root:

```env
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 4. Configure Gemini API Key

Provide your Gemini API key at run/build time using a dart-define:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

For release builds:

```bash
flutter build apk --dart-define=GEMINI_API_KEY=your_key_here
flutter build ios --dart-define=GEMINI_API_KEY=your_key_here
```

### 5. Firebase Configuration

The project includes Firebase configuration files:
- `android/app/google-services.json` (Android)
- `lib/firebase_options.dart` (All platforms)

Ensure your Firebase project has:

- **Authentication** enabled with:
  - Email/Password provider
  - Anonymous authentication
- **Firestore Database** created with the following collections structure:
  ```
  users/{userId}/
    ├── progress/{topicId}
    ├── visitedTopics/{topicId}
    ├── tutorials/{topicId}
    ├── quizzes/{topicId}
    └── quizResults/
  ```

### 6. Run the App

```bash
# For Android
flutter run -d android --dart-define=GEMINI_API_KEY=your_key

# For iOS
flutter run -d ios --dart-define=GEMINI_API_KEY=your_key

# For Web
flutter run -d chrome --dart-define=GEMINI_API_KEY=your_key
```

## App Flow

1. **Launch**: App checks authentication state and onboarding completion
2. **Onboarding** (first time only):
   - Shows 3 screens explaining app features
   - User can **Skip** to use anonymous auth or click **Get Started** to proceed to sign up/sign in
3. **Authentication Screen** (if not authenticated):
   - Sign up with email/password
   - Sign in with email/password
   - **Skip** button to continue with anonymous authentication
4. **Home Screen** (authenticated):
   - Browse topics by category
   - Search for specific topics
   - View recently visited topics
   - Access AI tutor chat
5. **Topic Details**:
   - AI-generated tutorial (cached in Firestore)
   - Interactive quiz
   - Progress tracking

## Authentication Flow Diagram

```
App Launch
    ↓
Check if user is authenticated
    ↓
    ├─ YES → Home Screen
    │
    └─ NO → Check onboarding completion
              ↓
              ├─ NOT COMPLETE → Onboarding Screen
              │                      ↓
              │                 [Get Started] or [Skip]
              │                      ↓
              │                 ├─ Skip → Anonymous Auth → Home
              │                 └─ Get Started → Auth Screen
              │
              └─ COMPLETE → Auth Screen
                                 ↓
                            [Sign In/Sign Up] or [Skip]
                                 ↓
                            Home Screen
```

## Key Technologies

- **Flutter & Dart**: Cross-platform mobile development
- **Firebase**:
  - Firebase Core
  - Firebase Auth (v5.3.0)
  - Cloud Firestore (v5.4.4)
- **Riverpod**: State management
- **Google Fonts**: Typography
- **Supabase**: Additional backend features
- **Gemini AI**: Content generation

## Data Persistence Strategy

### Firestore Collections

1. **User Progress** (`users/{userId}/progress/{topicId}`):
   - Tracks completion percentage per topic
   - Last updated timestamp

2. **Visited Topics** (`users/{userId}/visitedTopics/{topicId}`):
   - Records topics user has viewed
   - Visited timestamp for sorting

3. **Tutorials** (`users/{userId}/tutorials/{topicId}`):
   - Caches AI-generated tutorials
   - Prevents regeneration on revisit
   - Includes steps, summary, and generation timestamp

4. **Quizzes** (`users/{userId}/quizzes/{topicId}`):
   - Stores quiz questions per topic
   - Cached to maintain consistency

5. **Quiz Results** (`users/{userId}/quizResults/`):
   - Score and completion data
   - Historical performance tracking

### Why This Approach?

- **Efficiency**: AI-generated content is cached, preventing unnecessary API calls
- **User Experience**: Instant loading of previously visited topics
- **Cost Optimization**: Reduces API usage by storing generated content
- **Offline Support**: Cached content available when offline
- **Progress Tracking**: Complete history of user's learning journey

## Anonymous to Permanent Account

Users who start with anonymous authentication can later link their account to email/password credentials without losing their progress:

```dart
// This functionality is built into FirebaseAuthService
await authService.linkWithEmailAndPassword(
  email: email,
  password: password,
);
```

## Firestore Security Rules

Ensure you have proper security rules in Firestore:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Troubleshooting

### Issue: Infinite loading on app launch

**Solution**: Ensure Firebase is properly initialized in `main.dart` with the correct configuration.

### Issue: Anonymous authentication not working

**Solution**:
1. Check Firebase console to ensure Anonymous authentication is enabled
2. Verify `google-services.json` is properly configured

### Issue: Firestore permission errors

**Solution**: Update Firestore security rules to allow authenticated users to read/write their own data.

### Issue: AI content not generating

**Solution**: Verify your Gemini API key is correctly passed via `--dart-define=GEMINI_API_KEY=your_key`.

## License

This project is licensed under the MIT License.

## Support

For issues, questions, or contributions, please open an issue in the GitHub repository.
