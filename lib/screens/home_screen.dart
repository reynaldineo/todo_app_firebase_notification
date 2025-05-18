import 'package:flutter/material.dart';
import 'package:todo_app_firbase_notification/screens/add_task_screen.dart';
import 'package:todo_app_firbase_notification/screens/task_detail_screen_new.dart';
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
  String _filterOption = 'all'; // 'all', 'pending', 'completed'
  String _sortOption = 'dueDate'; // 'dueDate', 'title'
  Task? _deletedTask; // Store recently deleted task for undo functionality

  @override
  void initState() {
    super.initState();
    _checkNotificationPermissions();
  }

  // Filter tasks based on current filter option
  List<Task> _filterTasks(List<Task> tasks) {
    switch (_filterOption) {
      case 'pending':
        return tasks.where((task) => !task.isCompleted).toList();
      case 'completed':
        return tasks.where((task) => task.isCompleted).toList();
      case 'all':
      default:
        return tasks;
    }
  }

  // Sort tasks based on current sort option
  List<Task> _sortTasks(List<Task> tasks) {
    switch (_sortOption) {
      case 'title':
        return tasks..sort((a, b) => a.title.compareTo(b.title));
      case 'dueDate':
      default:
        return tasks..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    }
  }

  Future<void> _checkNotificationPermissions() async {
    await notif.requestNotificationPermissions();
    await notif.checkScheduledNotifications();
    developer.log(
      'Home screen initialized and checked notifications',
      name: 'HomeScreen',
    );
  }

  // Delete task with undo functionality
  void _deleteTask(Task task) {
    _deletedTask = task;
    TaskService().deleteTask(task.id);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Task deleted'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            if (_deletedTask != null) {
              TaskService().addTask(_deletedTask!);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Task restored')));
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo List'),
        actions: [
          // Filter menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter tasks',
            onSelected: (value) {
              setState(() {
                _filterOption = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Filtered to ${value} tasks')),
              );
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'all', child: Text('All Tasks')),
                  const PopupMenuItem(
                    value: 'pending',
                    child: Text('Pending Tasks'),
                  ),
                  const PopupMenuItem(
                    value: 'completed',
                    child: Text('Completed Tasks'),
                  ),
                ],
          ),

          // Sort menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort tasks',
            onSelected: (value) {
              setState(() {
                _sortOption = value;
              });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Sorted by ${value}')));
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'dueDate',
                    child: Text('Sort by Due Date'),
                  ),
                  const PopupMenuItem(
                    value: 'title',
                    child: Text('Sort by Title'),
                  ),
                ],
          ),

          // Notification menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.notifications),
            tooltip: 'Notification options',
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.task_alt, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    'No tasks yet. Add one!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddTaskScreen(),
                          ),
                        ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Task'),
                  ),
                ],
              ),
            );
          }

          // Apply filtering and sorting
          final filteredTasks = _filterTasks(snapshot.data!);
          final sortedTasks = _sortTasks(filteredTasks);

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: sortedTasks.length,
            itemBuilder: (context, index) {
              final task = sortedTasks[index];

              // Format date for better display
              final formattedDate =
                  '${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year} at ${task.dueDate.hour}:${task.dueDate.minute.toString().padLeft(2, '0')}';

              final bool isOverdue =
                  task.dueDate.isBefore(DateTime.now()) && !task.isCompleted;

              // Add Dismissible for swipe-to-delete
              return Dismissible(
                key: Key(task.id),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Delete Task'),
                          content: Text(
                            'Are you sure you want to delete "${task.title}"?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                  );
                },
                onDismissed: (direction) {
                  _deleteTask(task);
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side:
                        isOverdue
                            ? const BorderSide(color: Colors.red, width: 1)
                            : BorderSide.none,
                  ),
                  elevation: 3,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskDetailScreen(task: task),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              task.isCompleted
                                  ? Colors.green
                                  : (isOverdue ? Colors.red : Colors.blue),
                          child: Icon(
                            task.isCompleted
                                ? Icons.check
                                : (isOverdue ? Icons.warning : Icons.task_alt),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration:
                                task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                            color: isOverdue ? Colors.red : null,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Due: $formattedDate',
                          style: TextStyle(
                            color: isOverdue ? Colors.red : Colors.grey,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Edit task',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            TaskDetailScreen(task: task),
                                  ),
                                );
                              },
                            ),
                            Checkbox(
                              activeColor: Colors.green,
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
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddTaskScreen()),
            ),
      ),

      // Bottom action bar with filter options only (removed test notification)
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).primaryColor,
        shape: const CircularNotchedRectangle(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Filter button - all tasks
              IconButton(
                icon: Icon(
                  Icons.list,
                  color: _filterOption == 'all' ? Colors.amber : Colors.white,
                ),
                tooltip: 'All Tasks',
                onPressed: () {
                  setState(() {
                    _filterOption = 'all';
                  });
                },
              ),

              // Filter button - pending tasks
              IconButton(
                icon: Icon(
                  Icons.pending_actions,
                  color:
                      _filterOption == 'pending' ? Colors.amber : Colors.white,
                ),
                tooltip: 'Pending Tasks',
                onPressed: () {
                  setState(() {
                    _filterOption = 'pending';
                  });
                },
              ),

              // Filter button - completed tasks
              IconButton(
                icon: Icon(
                  Icons.done_all,
                  color:
                      _filterOption == 'completed'
                          ? Colors.amber
                          : Colors.white,
                ),
                tooltip: 'Completed Tasks',
                onPressed: () {
                  setState(() {
                    _filterOption = 'completed';
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
