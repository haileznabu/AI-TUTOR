# Topic Upload Instructions

## How to Upload Topics to Firestore

### Prerequisites
1. Ensure you have configured Firebase properly
2. Make sure `topics_data.json` is in the project root
3. The app must be built and running

### Steps to Upload

1. **Launch the App**
   - Run the app on an Android device or emulator
   - Sign in to your account

2. **Navigate to Profile**
   - Tap on the "Profile" tab in the bottom navigation bar

3. **Access Upload Feature**
   - Scroll down to the "Settings" section
   - Find the "Upload Topics to Firestore" option (with upload icon)

4. **Initiate Upload**
   - Tap on "Upload Topics to Firestore"
   - A confirmation dialog will appear
   - Tap "Upload" to confirm

5. **Monitor Progress**
   - A loading indicator will appear while uploading
   - The upload process will run in the background

6. **View Results**
   - A success dialog will show the number of topics uploaded
   - If there are any errors, they will be displayed in the dialog
   - Tap "OK" to close the dialog

### What Gets Uploaded

The upload will process all 55 topics from `topics_data.json`:
- 15 Programming topics
- 4 Life Skills topics
- 4 Science topics
- 4 Arts & Humanities topics
- 4 Math topics
- 4 Economics topics
- 7 Digital Literacy topics
- 6 Problem Solving topics
- 7 STEM Basics topics

### Firestore Structure

Each topic will be stored in Firestore with the following fields:
- `id` - Unique identifier
- `title` - Topic name
- `description` - Topic description
- `category` - Category name
- `iconCodePoint` - Icon code for Material Icons
- `iconFontFamily` - Font family (MaterialIcons)
- `estimatedMinutes` - Estimated learning time
- `difficulty` - Beginner/Intermediate/Advanced
- `createdAt` - Server timestamp

### After Upload

Once the upload is complete and verified:
1. Follow the cleanup guide in `UPLOAD_CLEANUP_GUIDE.md`
2. Remove all upload-related code and files
3. The app will continue to work normally, loading topics from Firestore

### Troubleshooting

**Upload Failed**
- Check your internet connection
- Verify Firebase configuration
- Check Firestore security rules
- Ensure you have write permissions to Firestore

**Partial Upload (Some topics failed)**
- Review the error messages in the dialog
- Check Firestore console to see which topics were uploaded
- You can re-run the upload (existing topics will be overwritten)

**App Crashes During Upload**
- Check Android logs: `flutter logs` or `adb logcat`
- Verify `topics_data.json` is properly formatted
- Ensure Firebase is initialized correctly

### Re-uploading Topics

You can re-run the upload process multiple times:
- Existing topics will be overwritten with new data
- This is useful for updating topic information
- No duplicate topics will be created (same ID)

### Security Note

This upload feature should only be used during development/setup. Once topics are uploaded to Firestore, remove this feature from production builds by following the cleanup guide.
