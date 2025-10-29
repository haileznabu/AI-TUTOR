# 🔑 Gemini API Key Setup

## Why do I need this?

The AI Tutor app uses Google's Gemini AI to generate personalized learning content. You need an API key to enable this feature.

## Quick Setup (2 minutes)

### Step 1: Get Your Free API Key

1. Visit: **https://makersuite.google.com/app/apikey**
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated key (starts with `AIza...`)

### Step 2: Add to Your Project

Open the `.env` file in the project root and replace:

```env
GEMINI_API_KEY=your_gemini_api_key_here
```

With your actual key:

```env
GEMINI_API_KEY=AIzaSyC...your_actual_key_here
```

### Step 3: Restart the App

If the app is running, restart it to load the new API key.

## What happens without an API key?

- ❌ Red error screen when clicking on topics
- ❌ Error message: "Gemini API key is not configured"
- ✅ Solution: Follow the steps above!

## Is my API key secure?

- ✓ The `.env` file is included in `.gitignore` (not committed to Git)
- ✓ Your key stays on your local machine
- ✓ For production, use environment variables or secure key management

## Alternative Setup Methods

### For Web Deployment (Firestore)

Store your API key in Firebase Firestore:
- Collection: `config`
- Document: `api_keys`
- Field: `gemini_api_key` = `your_key_here`

The app will automatically fetch it from there for web builds.

### For Production Builds

Use dart-define flag:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
flutter build apk --dart-define=GEMINI_API_KEY=your_key_here
```

## Need Help?

- **API Key Issues:** Check that you copied the full key including "AIza..."
- **Still Not Working:** Make sure you restarted the app after adding the key
- **More Details:** See `README.md` and `QUICK_START.md`
