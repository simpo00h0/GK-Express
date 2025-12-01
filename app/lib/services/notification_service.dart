import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Initialize notifications
  static Future<void> initialize() async {
    if (_initialized) return;

    // Windows doesn't need special initialization
    const initializationSettings = InitializationSettings(
      android: null,
      iOS: null,
      macOS: null,
      linux: null,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
        // TODO: Navigate to parcel details
      },
    );

    _initialized = true;
    debugPrint('✅ Notifications initialized');
  }

  // Show notification for new parcel
  static Future<void> showNewParcelNotification({
    required String parcelId,
    required String senderName,
    required String originOffice,
    required String destination,
  }) async {
    // For Windows, we'll use a simple approach
    // The notification will appear in the Windows notification center
    const notificationDetails = NotificationDetails(
      android: null,
      iOS: null,
      macOS: null,
      linux: null,
    );

    try {
      await _notifications.show(
        parcelId.hashCode, // Unique ID
        '📦 Nouveau Colis Reçu !',
        'De $originOffice → $destination\nExpéditeur: $senderName',
        notificationDetails,
        payload: parcelId,
      );

      debugPrint('📬 Notification shown for parcel: $parcelId');
    } catch (e) {
      debugPrint('Error showing notification: $e');
      // Fallback: just print to console
      debugPrint(
        '📦 NEW PARCEL: From $originOffice to $destination by $senderName',
      );
    }
  }

  // Request permissions (for mobile, not needed on Windows)
  static Future<bool> requestPermissions() async {
    // Windows doesn't need explicit permission
    return true;
  }
}
