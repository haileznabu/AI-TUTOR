# Quick Start Guide

## Setup in 3 Steps

### 1. Copy and Configure Environment File
```bash
cp .env.example .env
```

Then edit `.env` and add your Gemini API key:
```
GEMINI_API_KEY=your_actual_key_here
```

Get your API key from: https://makersuite.google.com/app/apikey

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
```bash
# For web
flutter run -d chrome

# For Windows
flutter run -d windows

# For Android/iOS (with device connected)
flutter run
```

## What's New

### Environment Variables
- Gemini API key now loads from `.env` file
- No more compile-time configuration needed
- Works on all platforms (Web, Windows, Android, iOS, macOS)

### Topic Learning Improvements

#### 1. Summary Display
- "What you'll learn" section now only shows on the first page
- More space for content on subsequent pages

#### 2. Chat Feature
- Click the chat icon (💬) while learning any topic
- Ask questions about the current topic
- Get AI-powered answers with context about what you're learning
- Chat clears when closed for fresh conversations

## Platform Support

✅ **Web** - Works perfectly in Chrome, Firefox, Safari, Edge
✅ **Windows** - Full support with Firebase auth
✅ **Android** - Full support
✅ **iOS** - Full support
✅ **macOS** - Full support

## Need Help?

- See `SETUP.md` for detailed setup instructions
- See `CHANGES_SUMMARY.md` for technical details
- Check `.env.example` for required environment variables
