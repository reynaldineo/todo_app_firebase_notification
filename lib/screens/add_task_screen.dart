import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../utils/notification_helper.dart' as notif;
import 'dart:developer' as developer;

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  DateTime? _selectedDate;
  void _submitTask() async {
    if (_titleController.text.isEmpty || _selectedDate == null) return;

    try {
      // Create task
      final task = Task(
        id:
            DateTime.now().millisecondsSinceEpoch
                .toString(), // Generate a temporary ID
        title: _titleController.text,
        dueDate: _selectedDate!,
      );

      // Save task to Firestore
      final taskService = TaskService();
      await taskService.addTask(task);
      // Schedule notification
      developer.log(
        'Scheduling notification for new task: ${task.title}',
        name: 'AddTaskScreen',
      );
      await notif.showReminderNotification(task);

      // For debugging - check all scheduled notifications
      await notif.checkScheduledNotifications();

      Navigator.pop(context);
    } catch (e) {
      developer.log(
        'Error submitting task: $e',
        name: 'AddTaskScreen',
        error: e,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving task: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Task'), elevation: 2),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task title field with better styling
              const Text(
                'Task Title',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Enter task title',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 24),

              // Due date section
              const Text(
                'Due Date & Time',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              // Due date selection card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedDate != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.event, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'Selected: ${_formatDate(_selectedDate!)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      ElevatedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _selectedDate == null
                              ? 'Select Due Date & Time'
                              : 'Change Date & Time',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Save button - full width
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitTask,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Save Task',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
