import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import '../models/prescription_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification tapped: ${response.payload}');
      },
    );
  }

  Future<void> requestPermissions() async {
    // Android 13+ notification permission
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // iOS notification permissions
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> scheduleMedicationReminders(Medication medication, String prescriptionId) async {
    await cancelMedicationNotifications(medication.id);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (today.isBefore(medication.startDate) || today.isAfter(medication.endDate)) {
      return;
    }

    for (var dose in medication.doses) {
      final doseTime = DateTime(
        today.year,
        today.month,
        today.day,
        dose.time.hour,
        dose.time.minute,
      );

      final notificationTime = doseTime.subtract(Duration(minutes: medication.notificationLeadTime));

      if (notificationTime.isAfter(now)) {
        await _scheduleNotification(
          id: _generateNotificationId(medication.id, dose.id),
          title: 'Medication Reminder',
          body: 'Time to take ${medication.name} (${dose.quantity} ${medication.dosage}) at ${dose.formattedTime}',
          scheduledTime: notificationTime,
          payload: '$prescriptionId:${medication.id}:${dose.id}',
        );

        await _scheduleNotification(
          id: _generateMissedNotificationId(medication.id, dose.id),
          title: 'Missed Medication',
          body: 'You missed your ${medication.name} dose scheduled for ${dose.formattedTime}',
          scheduledTime: doseTime.add(const Duration(minutes: 30)),
          payload: 'missed:$prescriptionId:${medication.id}:${dose.id}',
        );
      }
    }
  }

  Future<void> scheduleAllMedications(List<PrescriptionModel> prescriptions) async {
    await _notificationsPlugin.cancelAll();

    for (var prescription in prescriptions) {
      for (var medication in prescription.medications) {
        if (_isMedicationActive(medication)) {
          await scheduleMedicationReminders(medication, prescription.id);
        }
      }
    }
  }

  Future<void> cancelMedicationNotifications(String medicationId) async {
    final notificationIds = _generateAllNotificationIds(medicationId);

    for (var id in notificationIds) {
      await _notificationsPlugin.cancel(id);
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.high,
          priority: Priority.high,
          sound: const RawResourceAndroidNotificationSound('notification_sound'),
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'notification_sound.aiff',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.time, // Keeps daily reminders
    );
  }

  int _generateNotificationId(String medicationId, String doseId) {
    final idString = '$medicationId:$doseId';
    return idString.hashCode.abs() % 100000;
  }

  int _generateMissedNotificationId(String medicationId, String doseId) {
    final idString = 'missed:$medicationId:$doseId';
    return idString.hashCode.abs() % 100000;
  }

  List<int> _generateAllNotificationIds(String medicationId) {
    final List<int> ids = [];
    for (int i = 0; i < 10; i++) {
      final doseId = 'dose_$i';
      ids.add(_generateNotificationId(medicationId, doseId));
      ids.add(_generateMissedNotificationId(medicationId, doseId));
    }
    return ids;
  }

  bool _isMedicationActive(Medication medication) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.isAfter(medication.startDate.subtract(const Duration(days: 1))) &&
           today.isBefore(medication.endDate.add(const Duration(days: 1)));
  }
}
