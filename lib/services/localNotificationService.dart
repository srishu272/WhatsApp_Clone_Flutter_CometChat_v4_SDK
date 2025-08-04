import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void initialize({
    required Function(String? payload) onNotificationClick,
  }) {
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        );

    _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (
        NotificationResponse notificationResponse,
      ) {
        //debugPrint("🔔 Notification tapped: ${notificationResponse.payload}");
        onNotificationClick(notificationResponse.payload);
      },
    );
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0, //default to 0 for chat, 1001 for call
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        "chat_messages_channel", // Channel ID
        "Chat Messages", // Channel Name
        importance: Importance.max,
        playSound: false,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(presentSound: false),
    );

    await _notificationsPlugin.show(
      id, // Notification ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
