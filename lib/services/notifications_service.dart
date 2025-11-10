import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(
  NotificationResponse notificationResponse,
) {
  debugPrint(
    'Notification tapped with payload: ${notificationResponse.payload}',
  );
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationDetails _mainChannel =
      AndroidNotificationDetails(
        'notive_channel',
        'Notive Notifications',
        channelDescription: 'Task reminders and updates',
        importance: Importance.max,
        priority: Priority.high,
      );

  static Future<void> init() async {
    // 1. Setup platform-specific initialization settings
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iOSInit,
    );

    // 2. Initialize the plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    // 3. Initialize timezone data
    tz.initializeTimeZones();

    // 4. Request all necessary permissions on app start
    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      await Permission.notification.request();

      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    }
  }

  /// Shows an immediate notification.
  static Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    const notificationDetails = NotificationDetails(android: _mainChannel);
    await _notifications.show(
      0, // 'id'
      title,
      body,
      notificationDetails,
    );
  }

  /// Schedules a one-time notification for a specific date and time.
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    // 1. Convert the Dart DateTime to a TZDateTime
    final scheduled = tz.TZDateTime.from(dateTime, tz.local);

    // 2. Schedule the notification
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(android: _mainChannel),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancels a single notification by its ID.
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancels all scheduled or active notifications.
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
