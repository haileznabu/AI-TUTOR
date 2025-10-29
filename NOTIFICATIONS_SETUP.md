# Firebase Notifications Setup

## Implementation Complete

Firebase Cloud Messaging (FCM) has been fully integrated into the app with the following features:

### Features Implemented

1. **Runtime Permission Request**
   - Automatic permission request 2 seconds after Home screen loads
   - User-friendly permission prompt with SnackBar fallback
   - Topic subscription to 'all_users' after permission granted

2. **Platform Support**
   - ✅ Android (API 21+)
   - ✅ iOS (with APNs integration)
   - ⚠️ Web (notifications disabled, not supported)

3. **Notification Handling**
   - Background notifications
   - Foreground notifications with local display
   - Notification tap handling
   - App opened from notification

4. **Additional Features**
   - Topic subscription/unsubscription
   - FCM token management and refresh
   - Test notification button in Profile screen
   - Notification channel configuration (Android)

### Files Modified/Created

1. **New Files:**
   - `lib/services/notification_service.dart` - Core notification service
   - `lib/providers/notification_provider.dart` - Riverpod provider

2. **Modified Files:**
   - `pubspec.yaml` - Added dependencies
   - `lib/main.dart` - Initialize notification service
   - `lib/screens/home_screen.dart` - Runtime permission request
   - `lib/screens/profile_screen.dart` - Test notification button
   - `android/app/src/main/AndroidManifest.xml` - Android permissions & service
   - `android/app/build.gradle` - Firebase messaging dependency
   - `ios/Runner/Info.plist` - iOS background modes
   - `ios/Runner/AppDelegate.swift` - APNs setup

### Testing

1. **Test Local Notification:**
   - Go to Profile screen
   - Tap "Test Notification"
   - Should see notification appear

2. **Test FCM:**
   - Check console for FCM token
   - Use Firebase Console to send test message
   - Or use topic 'all_users' to broadcast

### Firebase Console Setup Required

To send notifications from Firebase Console:

1. Go to Firebase Console > Cloud Messaging
2. Create new campaign or send test message
3. Use FCM token from console logs or topic 'all_users'
4. Configure title, body, and optional data payload

### API Reference

```dart
// Get notification service
final notificationService = NotificationService();

// Request permission
await notificationService.requestPermission();

// Get FCM token
String? token = notificationService.fcmToken;

// Subscribe to topic
await notificationService.subscribeToTopic('topic_name');

// Unsubscribe from topic
await notificationService.unsubscribeFromTopic('topic_name');

// Send test notification
await notificationService.sendTestNotification();
```

### Notes

- Notifications are automatically initialized in `main.dart`
- Permission is requested automatically 2 seconds after Home screen loads
- All users are subscribed to 'all_users' topic after granting permission
- Web platform notifications are disabled
