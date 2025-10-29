# Manual Upload Guide for Topics to Firebase Firestore

Since the `upload_topics.dart` script isn't working in this environment, here are **three alternative methods** to upload your topics data to Firebase Firestore:

## Method 1: Using Firebase Console (Easiest - No Coding Required)

### Step 1: Access Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `plp-ai-tutor`
3. Click on "Firestore Database" in the left sidebar

### Step 2: Create the Topics Collection
1. Click "Start collection"
2. Collection ID: `topics`
3. Click "Next"

### Step 3: Add Documents One by One
For each topic in `topics_data.json`, create a new document:

1. Click "Add document"
2. Set Document ID to the topic's `id` (e.g., "1", "2", "3", etc.)
3. Add the following fields for each topic:
   - `id` (string): The topic ID
   - `title` (string): Topic title
   - `description` (string): Topic description
   - `category` (string): Topic category
   - `iconCodePoint` (number): Icon code point
   - `iconFontFamily` (string): "MaterialIcons"
   - `estimatedMinutes` (number): Estimated minutes
   - `difficulty` (string): Difficulty level
   - `createdAt` (timestamp): Click "Use current timestamp"

**Note**: This method is tedious for 55 topics but guaranteed to work.

---

## Method 2: Using Firebase Admin SDK with Node.js (Recommended)

### Prerequisites
- Node.js installed on your machine
- Firebase Admin SDK credentials

### Step 1: Get Firebase Service Account Key
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click the gear icon ⚙️ > Project settings
3. Go to "Service accounts" tab
4. Click "Generate new private key"
5. Download the JSON file (save it as `serviceAccountKey.json`)

### Step 2: Install Dependencies
```bash
npm install firebase-admin
```

### Step 3: Update the Script
1. Open `upload_topics_node.js`
2. Replace the `serviceAccount` object with your downloaded service account key contents
3. Save the file

### Step 4: Run the Script
```bash
node upload_topics_node.js
```

This will upload all 55 topics to your Firestore database automatically.

---

## Method 3: Using Firebase REST API with curl

You can upload each document using the Firebase REST API. Here's an example for the first topic:

```bash
curl -X PATCH \
  'https://firestore.googleapis.com/v1/projects/plp-ai-tutor/databases/(default)/documents/topics/1?key=AIzaSyBUK7Tqltu29luyvRM9s-rxLXrfg6pSloA' \
  -H 'Content-Type: application/json' \
  -d '{
    "fields": {
      "id": {"stringValue": "1"},
      "title": {"stringValue": "Flutter Basics"},
      "description": {"stringValue": "Learn the fundamentals of Flutter development"},
      "category": {"stringValue": "Programming"},
      "iconCodePoint": {"integerValue": "58156"},
      "iconFontFamily": {"stringValue": "MaterialIcons"},
      "estimatedMinutes": {"integerValue": "30"},
      "difficulty": {"stringValue": "Beginner"}
    }
  }'
```

Repeat this for each topic in `topics_data.json`, changing the document ID and field values.

---

## Method 4: Import via Firebase CLI (Advanced)

### Prerequisites
- Firebase CLI installed: `npm install -g firebase-tools`
- Logged in: `firebase login`

### Steps
1. Create a backup/export format file
2. Use `firebase firestore:delete` and `firebase firestore:import` commands

**Note**: This method requires creating a properly formatted backup file, which is more complex.

---

## Recommended Approach

For the best experience:
1. **If you have Node.js**: Use Method 2 (Node.js script)
2. **If you don't have Node.js**: Use Method 1 (Firebase Console manually)
3. **For bulk operations**: Consider Method 3 (REST API with a bash script)

---

## Verification

After uploading, verify the data:
1. Go to Firebase Console
2. Navigate to Firestore Database
3. Check that the `topics` collection exists
4. Verify that all 55 documents are present
5. Open a few documents to ensure all fields are correct

---

## Troubleshooting

### "Permission denied" errors
- Check your Firebase Security Rules
- Make sure you're authenticated with the correct account
- Verify your service account has the necessary permissions

### Missing fields
- Double-check field names match exactly
- Ensure field types are correct (string, number, timestamp)

### Topics not appearing in app
- Restart your Flutter app
- Check the app's Firestore query logic
- Verify the collection name is "topics"

---

## Support

If you encounter issues:
1. Check the Firebase Console for error messages
2. Review Firebase Security Rules
3. Verify your API keys and credentials
4. Check the browser console for errors in web apps
