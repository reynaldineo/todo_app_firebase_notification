import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:todo_app_firbase_notification/firebase_options.dart';
import 'package:todo_app_firbase_notification/screens/home_screen.dart';
import 'package:todo_app_firbase_notification/utils/notification_helper.dart'
    as notif;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notifications with our improved helper
  await notif.initializeNotifications();
  await notif.requestNotificationPermissions();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Listener for notification events, debugging purposes
    AwesomeNotifications().setListeners(
      onNotificationCreatedMethod: onNotificationCreated,
      onNotificationDisplayedMethod: onNotificationDisplayed,
      onActionReceivedMethod: onActionReceived,
      onDismissActionReceivedMethod: onDismissActionReceived,
    );
  }

  static Future<void> onNotificationCreated(
    ReceivedNotification receivedNotification,
  ) async {
    developer.log(
      'Notification created: ${receivedNotification.id}',
      name: 'NotificationListener',
    );
  }

  static Future<void> onNotificationDisplayed(
    ReceivedNotification receivedNotification,
  ) async {
    developer.log(
      'Notification displayed: ${receivedNotification.id}',
      name: 'NotificationListener',
    );
  }

  static Future<void> onDismissActionReceived(
    ReceivedAction receivedAction,
  ) async {
    developer.log(
      'Notification dismissed: ${receivedAction.id}',
      name: 'NotificationListener',
    );
  }

  static Future<void> onActionReceived(ReceivedAction receivedAction) async {
    developer.log(
      'Action received: ${receivedAction.id}',
      name: 'NotificationListener',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDo App',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const HomeScreen(),
    );
  }
}
