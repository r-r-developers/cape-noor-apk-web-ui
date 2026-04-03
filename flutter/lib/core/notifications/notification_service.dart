import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings     = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> schedulePrayer({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    String? audioAsset,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _plugin.zonedSchedule(
      id,
      'Prayer Time — $prayerName',
      'Time for $prayerName. Allahu Akbar!',
      tzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_alerts',
          'Prayer Alerts',
          channelDescription: 'Adhan and prayer time notifications',
          importance: Importance.high,
          priority: Priority.high,
          sound: const RawResourceAndroidNotificationSound('adhan_makka'),
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'adhan_makka.caf',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  static Future<void> cancelAll() => _plugin.cancelAll();

  static Future<void> cancel(int id) => _plugin.cancel(id);

  static Future<void> showInstant({
    required String title,
    required String body,
    int id = 9999,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'general',
          'General',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }
}
