# Setting up Gemini API Key in Firestore

## Option 1: Using Firebase Console (Recommended)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database**
4. Click **Start collection**
5. Enter collection ID: `config`
6. Click **Next**
7. For Document ID, enter: `api_keys`
8. Add a field:
   - Field name: `gemini_api_key`
   - Type: `string`
   - Value: `YOUR_ACTUAL_GEMINI_API_KEY`
9. Click **Save**

## Option 2: Using Firebase Admin SDK or Script

You can also add it programmatically if you have Firebase Admin access.

## Security Note

Make sure to set up Firestore Security Rules to protect this API key:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /config/api_keys {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
```

This ensures:
- Only authenticated users can read the API key
- No one can modify it through the client

## How It Works Now

- **Web Platform**: Fetches the API key from Firestore (works in production builds)
- **Mobile/Desktop Platforms**: Uses the `.env` file (as before)
- The API key is cached after first fetch for better performance
