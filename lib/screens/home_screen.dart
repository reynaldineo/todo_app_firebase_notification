import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:todo_app_firbase_notification/screens/add_task_screen.dart';
import '../services/task_service.dart';
import '../models/task_model.dart';
import '../utils/notification_helper.dart' as notif;
import 'dart:developer' as developer;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkNotificationPermissions();
  }

  Future<void> _checkNotificationPermissions() async {
    await notif.requestNotificationPermissions();
    await notif.checkScheduledNotifications();
    developer.log(
      'Home screen initialized and checked notifications',
      name: 'HomeScreen',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo List'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'check') {
                await notif.checkScheduledNotifications();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification status logged to console'),
                    ),
                  );
                }
              } else if (value == 'cancel') {
                await notif.cancelAllNotifications();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All notifications canceled')),
                  );
                }
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'check',
                    child: Text('Check Scheduled Notifications'),
                  ),
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Text('Cancel All Notifications'),
                  ),
                ],
          ),
        ],
      ),
      body: StreamBuilder<List<Task>>(
        stream: TaskService().getTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tasks yet. Add one!'));
          }

          final tasks = snapshot.data!;
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];

              // Format date for better display
              final formattedDate =
                  '${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year} at ${task.dueDate.hour}:${task.dueDate.minute.toString().padLeft(2, '0')}';

              // Check if the task is overdue
              final bool isOverdue =
                  task.dueDate.isBefore(DateTime.now()) && !task.isCompleted;

              return ListTile(
                title: Text(
                  task.title,
                  style: TextStyle(
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                    color: isOverdue ? Colors.red : null,
                  ),
                ),
                subtitle: Text(
                  'Due: $formattedDate',
                  style: TextStyle(color: isOverdue ? Colors.red : null),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        // Re-schedule notification for this task
                        notif.showReminderNotification(task);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notification rescheduled'),
                          ),
                        );
                      },
                    ),
                    Checkbox(
                      value: task.isCompleted,
                      onChanged: (value) {
                        TaskService().updateTask(
                          Task(
                            id: task.id,
                            title: task.title,
                            dueDate: task.dueDate,
                            isCompleted: value!,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                onLongPress: () {
                  TaskService().deleteTask(task.id);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'test_notification',
            onPressed: () {
              AwesomeNotifications().createNotification(
                content: NotificationContent(
                  id: 1,
                  channelKey: 'basic_channel',
                  title: 'Test Notification',
                  body: 'This is a test notification to verify it works',
                ),
              );
              developer.log(
                'Trying to send test notification',
                name: 'HomeScreen',
              );
            },
            label: const Text('Test Notification'),
            icon: const Icon(Icons.notifications),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add_task',
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTaskScreen(),
                  ),
                ),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
