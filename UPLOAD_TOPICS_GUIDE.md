# Upload Topics to Firestore Guide

This guide explains how to use the `upload_topics.dart` script to migrate your existing hard-coded topics to Firestore.

## Prerequisites

1. Ensure Firebase is properly configured in your project
2. Make sure you have Firestore enabled in your Firebase Console
3. The app should be connected to your Firebase project

## Steps to Upload Topics

### Option 1: Run via Flutter

```bash
flutter run -d <device> upload_topics.dart
```

Replace `<device>` with your target device (e.g., `chrome`, `macos`, `windows`, etc.)

### Option 2: Run Directly (Desktop Only)

```bash
dart run upload_topics.dart
```

## What the Script Does

The script will:
1. Initialize Firebase
2. Load all 55 pre-defined topics from the code
3. Upload each topic to the Firestore `topics` collection
4. Add a timestamp (`createdAt`) to each topic for sorting
5. Display progress and summary of the upload

## Expected Output

```
Firebase initialized successfully
Starting to upload 55 topics...
✓ Uploaded: Flutter Basics
✓ Uploaded: State Management
✓ Uploaded: REST APIs
...
✓ Uploaded: Robotics Introduction

=== Upload Summary ===
Total topics: 55
Successfully uploaded: 55
Failed: 0
======================

Upload process completed!
```

## After Upload

Once the topics are successfully uploaded:

1. **Delete the upload script** (optional but recommended):
   ```bash
   rm upload_topics.dart
   ```

2. The app will now fetch topics from Firestore automatically
3. Topics are sorted by `createdAt` timestamp (newest first)
4. You can add new topics directly to Firestore using the Firebase Console

## Firestore Structure

Topics are stored in Firestore with the following structure:

```
Collection: topics
Document ID: <topic_id>
Fields:
  - id: string
  - title: string
  - description: string
  - category: string
  - iconCodePoint: number
  - iconFontFamily: string
  - estimatedMinutes: number
  - difficulty: string
  - createdAt: timestamp
```

## Adding New Topics

You can add new topics in two ways:

### 1. Via Firebase Console
1. Go to Firebase Console → Firestore Database
2. Navigate to the `topics` collection
3. Click "Add document"
4. Enter the topic data with the structure shown above

### 2. Via Code
Use the `FirestoreService.addTopic()` method:

```dart
final firestoreService = FirestoreService();
await firestoreService.addTopic(Topic(
  id: '56',
  title: 'New Topic',
  description: 'Description here',
  category: 'Category Name',
  icon: Icons.star,
  estimatedMinutes: 30,
  difficulty: 'Beginner',
  createdAt: DateTime.now(),
));
```

## Troubleshooting

### Error: "Failed to get topics"
- Check your Firestore rules in Firebase Console
- Ensure the rules allow read access to the `topics` collection

### Error: "Failed to add topic"
- Verify Firestore rules allow write access
- Check your Firebase project configuration

### Topics Not Showing in App
- Verify topics were uploaded successfully in Firebase Console
- Check app logs for any error messages
- Ensure network connectivity

## Notes

- The upload script is temporary and can be safely deleted after use
- Topics are cached in the app for better performance
- The app will fall back to hard-coded topics if Firestore fetch fails
- Topics are automatically sorted by creation date (newest first)
