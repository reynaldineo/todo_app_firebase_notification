import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import 'edit_task_screen.dart';
import '../utils/notification_helper.dart' as notif;

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _task;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  @override
  Widget build(BuildContext context) {
    // Format date for better display
    final formattedDate =
        '${_task.dueDate.day}/${_task.dueDate.month}/${_task.dueDate.year} at ${_task.dueDate.hour}:${_task.dueDate.minute.toString().padLeft(2, '0')}';

    final bool isOverdue =
        _task.dueDate.isBefore(DateTime.now()) && !_task.isCompleted;

    // Calculate days remaining or overdue
    final difference = _task.dueDate.difference(DateTime.now());
    final daysText =
        difference.isNegative
            ? '${difference.inDays.abs()} days overdue'
            : difference.inDays == 0
            ? 'Due today'
            : '${difference.inDays} days remaining';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit task',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditTaskScreen(task: _task),
                ),
              );

              // If task was updated or deleted
              if (result == true) {
                Navigator.pop(context); // Go back to home screen
              }
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task title card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isOverdue ? Colors.red : Colors.grey.shade300,
                          width: isOverdue ? 2 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      _task.isCompleted
                                          ? Colors.green
                                          : (isOverdue
                                              ? Colors.red
                                              : Colors.blue),
                                  radius: 24,
                                  child: Icon(
                                    _task.isCompleted
                                        ? Icons.check
                                        : (isOverdue
                                            ? Icons.warning
                                            : Icons.task_alt),
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _task.title,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          decoration:
                                              _task.isCompleted
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                          color: isOverdue ? Colors.red : null,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                            color:
                                                isOverdue
                                                    ? Colors.red
                                                    : Colors.grey.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Due: $formattedDate',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  isOverdue
                                                      ? Colors.red
                                                      : Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        daysText,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              isOverdue
                                                  ? Colors.red
                                                  : (difference.inDays < 2
                                                      ? Colors.orange
                                                      : Colors.green),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Status: ${_task.isCompleted ? 'Completed' : 'Pending'}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        _task.isCompleted
                                            ? Colors.green
                                            : (isOverdue
                                                ? Colors.red
                                                : Colors.orange),
                                  ),
                                ),
                                Switch(
                                  value: _task.isCompleted,
                                  activeColor: Colors.green,
                                  onChanged: (value) {
                                    _updateTaskStatus(value);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.edit,
                            label: 'Edit',
                            color: Colors.blue,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => EditTaskScreen(task: _task),
                                ),
                              );

                              if (result == true) {
                                Navigator.pop(
                                  context,
                                ); // Go back to home screen
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.notifications_active,
                            label: 'Reminder',
                            color: Colors.amber,
                            onTap:
                                _task.isCompleted
                                    ? null
                                    : _rescheduleNotification,
                            disabled: _task.isCompleted,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.delete,
                            label: 'Delete',
                            color: Colors.red,
                            onTap: _showDeleteConfirmation,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Mark as complete button
                    if (!_task.isCompleted)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _updateTaskStatus(true),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: Colors.green,
                          ),
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Mark as Completed',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    if (_task.isCompleted)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _updateTaskStatus(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          icon: const Icon(Icons.restart_alt),
                          label: const Text(
                            'Mark as Pending',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    bool disabled = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: disabled ? Colors.grey.shade200 : Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: disabled ? Colors.grey : color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: disabled ? Colors.grey : color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _rescheduleNotification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await notif.showReminderNotification(_task);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification scheduled'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scheduling notification: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateTaskStatus(bool isCompleted) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedTask = Task(
        id: _task.id,
        title: _task.title,
        dueDate: _task.dueDate,
        isCompleted: isCompleted,
      );

      await TaskService().updateTask(updatedTask);

      // If task is set to pending, reschedule notification
      if (!isCompleted) {
        await notif.showReminderNotification(updatedTask);
      }

      setState(() {
        _task = updatedTask;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCompleted
                  ? 'Task marked as completed'
                  : 'Task marked as pending',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating task: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: const Text('Are you sure you want to delete this task?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context); // Close dialog

                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    await TaskService().deleteTask(_task.id);

                    if (mounted) {
                      Navigator.pop(context); // Return to previous screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Task deleted'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting task: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
