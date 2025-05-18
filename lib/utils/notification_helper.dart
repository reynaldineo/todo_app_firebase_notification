import 'package:awesome_notifications/awesome_notifications.dart';
import '../models/task_model.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart' show Color;

Future<void> showReminderNotification(Task task) async {
  try {
    final uniqueId = task.id.hashCode;
    developer.log(
      'Scheduling notification for task: ${task.title}',
      name: 'NotificationHelper',
    );
    developer.log('Notification ID: $uniqueId', name: 'NotificationHelper');
    developer.log(
      'Due date: ${task.dueDate.toIso8601String()}',
      name: 'NotificationHelper',
    );

    final now = DateTime.now();
    final scheduleTime =
        task.dueDate.isAfter(now)
            ? task.dueDate
            : now.add(Duration(seconds: 10));

    developer.log(
      'Actual schedule time: ${scheduleTime.toIso8601String()}',
      name: 'NotificationHelper',
    );
    bool success = await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: uniqueId,
        channelKey: 'basic_channel',
        title: 'Reminder: ${task.title}',
        body: 'Don\'t forget to complete your task!',
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Reminder,
        wakeUpScreen: true,
      ),
      schedule: NotificationCalendar.fromDate(
        date: scheduleTime,
        allowWhileIdle: true,
      ),
    );

    developer.log(
      'Notification scheduled successfully: $success',
      name: 'NotificationHelper',
    );
  } catch (e) {
    developer.log(
      'Error scheduling notification: $e',
      name: 'NotificationHelper',
      error: e,
    );
  }
}

Future<void> initializeNotifications() async {
  await AwesomeNotifications().initialize(null, [
    NotificationChannel(
      channelKey: 'basic_channel',
      channelName: 'Basic notifications',
      channelDescription: 'Notification channel for basic tests',
      defaultColor: const Color(0xFF9D50DD),
      ledColor: const Color(0xFFFFFFFF),
      importance: NotificationImportance.Max,
      channelShowBadge: true,
      playSound: true,
      criticalAlerts: true,
    ),
  ], debug: true);

  // Log notification permission status
  final isAllowed = await AwesomeNotifications().isNotificationAllowed();
  developer.log(
    'Notification permission is granted: $isAllowed',
    name: 'NotificationHelper',
  );
}

Future<void> requestNotificationPermissions() async {
  final isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
    final newStatus = await AwesomeNotifications().isNotificationAllowed();
    developer.log(
      'New notification permission status: $newStatus',
      name: 'NotificationHelper',
    );
  }
}

Future<void> checkScheduledNotifications() async {
  final pendingNotifications =
      await AwesomeNotifications().listScheduledNotifications();
  developer.log(
    'Pending scheduled notifications: ${pendingNotifications.length}',
    name: 'NotificationHelper',
  );

  for (final notification in pendingNotifications) {
    developer.log(
      'Scheduled notification: ${notification.content?.title}, ID: ${notification.content?.id}',
      name: 'NotificationHelper',
    );
    if (notification.schedule != null) {
      developer.log(
        'Schedule: ${notification.schedule?.toMap()}',
        name: 'NotificationHelper',
      );
    }
  }
}

Future<void> cancelAllNotifications() async {
  await AwesomeNotifications().cancelAll();
  developer.log('All notifications canceled', name: 'NotificationHelper');
}
