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
      appBar: AppBar(title: const Text('Add Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Task Title'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickDate,
                  child: const Text('Select Due Date'),
                ),
                const SizedBox(width: 10),
                if (_selectedDate != null)
                  Text('${_selectedDate!.toLocal()}'.split('.')[0]),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _submitTask,
              child: const Text('Save Task'),
            ),
          ],
        ),
      ),
    );
  }
}
