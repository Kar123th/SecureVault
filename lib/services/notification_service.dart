import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/all_models.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );
  }

  Future<void> scheduleReminder(ReminderItem reminder) async {
    if (reminder.id == null || reminder.isCompleted) return;

    // Schedule for the actual due date at 9:00 AM
    await _scheduleNotification(
      id: reminder.id!,
      title: 'Due Today: ${reminder.title}',
      body: 'Your ${reminder.category} is due today. Tap to view details.',
      scheduledDate: _getScheduledDate(reminder.reminderDate, 9),
    );

    // Schedule for 1 day before at 9:00 AM
    await _scheduleNotification(
      id: reminder.id! + 100000, // Unique ID for advance notice
      title: 'Reminder: ${reminder.title}',
      body: 'Your ${reminder.category} is due tomorrow.',
      scheduledDate: _getScheduledDate(reminder.reminderDate.subtract(const Duration(days: 1)), 9),
    );
  }

  Future<void> scheduleExpiryWarning({
    required int id,
    required String docName,
    required DateTime expiryDate,
  }) async {
    // Schedule for 30 days before at 10:00 AM
    final warningDate = expiryDate.subtract(const Duration(days: 30));
    
    await _scheduleNotification(
      id: id + 200000, // Offset for expiry warnings
      title: 'Document Expiring Soon',
      body: 'Your document "$docName" will expire in 30 days. Please take action.',
      scheduledDate: _getScheduledDate(warningDate, 10),
    );
  }

  Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
    await _notifications.cancel(id + 100000); // Normal reminder prefix
    await _notifications.cancel(id + 200000); // Expiry warning prefix
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Don't schedule if date is in the past
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders_channel',
          'Reminders',
          channelDescription: 'Notifications for vault reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  DateTime _getScheduledDate(DateTime date, int hour) {
    return DateTime(date.year, date.month, date.day, hour);
  }
}
