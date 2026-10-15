import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/models.dart';

/// Schedules daily LOCAL notifications for the medication reminders the patient (or their doctor's plan) defined.
/// It only repeats what the user configured; it never suggests medication.
///
/// Limitation: times are scheduled against UTC wall-clock arithmetic of the device's current offset, so after a daylight
/// saving change reminders are re-synced the next time the app opens. (No DST in India.)
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(const InitializationSettings(android: android));
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable on this platform: $e');
    }
  }

  /// Replaces every scheduled reminder with the current list. Disabled reminders / archived meds are skipped.
  static Future<int> syncReminders(List<Medication> meds, {bool enabled = true}) async {
    if (!_ready) return 0;
    try {
      await _plugin.cancelAll();
      if (!enabled) return 0;
      var count = 0;
      final now = DateTime.now();
      for (final m in meds.where((m) => m.active)) {
        for (final r in m.reminders.where((r) => r.enabled)) {
          final parts = r.timeOfDay.split(':');
          var next = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
          if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
          await _plugin.zonedSchedule(
            r.id,
            'Medication reminder',
            'Time for ${m.name} (${m.dosage}) as in your plan.',
            tz.TZDateTime.from(next, tz.UTC),
            const NotificationDetails(
              android: AndroidNotificationDetails('med_reminders', 'Medication reminders',
                  channelDescription: 'Daily reminders you set for your medicines',
                  importance: Importance.high, priority: Priority.high),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          count++;
        }
      }
      return count;
    } catch (e) {
      debugPrint('Could not schedule reminders: $e');
      return 0;
    }
  }

  static Future<void> cancelAll() async {
    if (_ready) await _plugin.cancelAll();
  }
}
