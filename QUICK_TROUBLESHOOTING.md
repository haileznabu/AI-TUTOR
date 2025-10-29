# Quick Troubleshooting Guide

## Issue: Topics Not Showing

### Symptoms
- App shows loading spinner indefinitely
- No topics appear on home screen
- AI-powered recommendations section is missing

### Solution
The app now automatically falls back to 55 pre-defined topics if Firestore fetch fails.

### To Upload Topics to Firestore

1. **Run the upload script:**
   ```bash
   dart run upload_topics.dart
   ```
   OR
   ```bash
   flutter run -d chrome upload_topics.dart
   ```

2. **Verify in Firebase Console:**
   - Go to Firebase Console → Firestore Database
   - Check the `topics` collection
   - You should see 55 documents

3. **Check Firestore Rules:**
   - Go to Firebase Console → Firestore Database → Rules
   - Ensure this rule exists:
   ```
   match /topics/{topicId} {
     allow read: if request.auth != null;
   }
   ```

## Issue: AI Recommendations Not Showing

### Symptoms
- The "Recommended for You" section with "AI Powered" badge is missing
- Only "Continue Learning" shows (if you have visited topics)

### Solution
This has been fixed! The AI recommendations section will now show:
- When you have visited at least one topic
- It shows up to 6 recommended topics based on your learning history
- Topics from the same categories you've explored are prioritized

### How It Works
1. Visit a few topics (at least 1)
2. Go back to home screen
3. You'll see "Recommended for You" with the AI Powered badge
4. Topics are recommended based on:
   - Categories you've already explored
   - Topics you haven't visited yet
   - Your learning progress

## Issue: Firestore Connection Errors

### Common Errors

**"Failed to get topics"**
- Check internet connection
- Verify Firebase configuration in `lib/firebase_options.dart`
- Check Firestore rules allow authenticated read access

**"Permission denied"**
- Ensure user is logged in
- Check Firestore rules in Firebase Console
- Verify authentication is working

### Debug Mode
Enable debug output to see detailed logs:
```dart
// The app already includes debug prints
// Check console for messages like:
// "Error loading topics from Firestore: ..."
// "Using fallback topics instead"
```

## Data Flow

```
1. App starts
   ↓
2. User logs in
   ↓
3. Home screen loads
   ↓
4. Try to fetch topics from Firestore
   ↓
5a. Success → Use Firestore topics
   OR
5b. Failure → Use fallback topics (55 pre-defined)
   ↓
6. Display topics on home screen
   ↓
7. Load AI recommendations (if user has visited topics)
```

## Fallback Topics

The app includes 55 fallback topics across these categories:
- Programming (15 topics)
- Life Skills (4 topics)
- Science (4 topics)
- Arts & Humanities (4 topics)
- Math (4 topics)
- Economics (4 topics)
- Digital Literacy (7 topics)
- Problem Solving (6 topics)
- STEM Basics (7 topics)

These topics are always available even if Firestore fails.

## Best Practices

1. **Always upload topics to Firestore** for the best experience
2. **Keep Firestore rules updated** to allow authenticated access
3. **Monitor Firebase Console** for any errors or quota issues
4. **Test with fallback topics** to ensure the app works offline

## Still Having Issues?

Check these files for errors:
1. `lib/services/firestore_service.dart` - Firestore operations
2. `lib/screens/home_screen.dart` - UI and topic display
3. `lib/firebase_options.dart` - Firebase configuration
4. Firebase Console → Firestore Database → Rules

Look for error messages in:
- Flutter console output
- Browser console (if running on web)
- Firebase Console → Firestore → Logs
