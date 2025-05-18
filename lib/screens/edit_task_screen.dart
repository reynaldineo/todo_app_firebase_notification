import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../utils/notification_helper.dart' as notif;
import 'dart:developer' as developer;

class EditTaskScreen extends StatefulWidget {
  final Task task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController _titleController;
  late DateTime _selectedDate;
  late bool _isCompleted;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _selectedDate = widget.task.dueDate;
    _isCompleted = widget.task.isCompleted;

    _titleController.addListener(_checkChanges);
  }

  @override
  void dispose() {
    _titleController.removeListener(_checkChanges);
    _titleController.dispose();
    super.dispose();
  }

  void _checkChanges() {
    final hasChanges =
        _titleController.text != widget.task.title ||
        _selectedDate != widget.task.dueDate ||
        _isCompleted != widget.task.isCompleted;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  void _updateTask() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task title cannot be empty')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create updated task
      final updatedTask = Task(
        id: widget.task.id,
        title: _titleController.text,
        dueDate: _selectedDate,
        isCompleted: _isCompleted,
      );

      // Save task to Firestore
      final taskService = TaskService();
      await taskService.updateTask(updatedTask);

      // Reschedule notification if task is not completed
      if (!updatedTask.isCompleted) {
        developer.log(
          'Rescheduling notification for updated task: ${updatedTask.title}',
          name: 'EditTaskScreen',
        );
        await notif.showReminderNotification(updatedTask);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Pass true to indicate successful update
      }
    } catch (e) {
      developer.log(
        'Error updating task: $e',
        name: 'EditTaskScreen',
        error: e,
      );
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

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(
        const Duration(days: 365),
      ), // Allow past dates for historical tasks
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
        _checkChanges();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} at ${_selectedDate.hour}:${_selectedDate.minute.toString().padLeft(2, '0')}';

    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          final result = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Discard Changes?'),
                  content: const Text(
                    'You have unsaved changes. Are you sure you want to discard them?',
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          () => Navigator.pop(context, false), // Don't discard
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true), // Discard
                      child: const Text('Discard'),
                    ),
                  ],
                ),
          );
          return result ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Task'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                _showDeleteConfirmation();
              },
            ),
          ],
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Task Title',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter task title',
                                  border: OutlineInputBorder(),
                                ),
                                autofocus: false,
                                textCapitalization:
                                    TextCapitalization.sentences,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Due Date',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today),
                                  const SizedBox(width: 10),
                                  Text(formattedDate),
                                  const Spacer(),
                                  ElevatedButton(
                                    onPressed: _pickDate,
                                    child: const Text('Change'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Text(
                                'Task Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: _isCompleted,
                                activeColor: Colors.green,
                                onChanged: (value) {
                                  setState(() {
                                    _isCompleted = value;
                                  });
                                  _checkChanges();
                                },
                              ),
                              Text(
                                _isCompleted ? 'Completed' : 'Pending',
                                style: TextStyle(
                                  color:
                                      _isCompleted
                                          ? Colors.green
                                          : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor:
                                _hasChanges
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey,
                          ),
                          onPressed: _hasChanges ? _updateTask : null,
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: const Text(
              'Are you sure you want to delete this task? This action cannot be undone.',
            ),
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
                    await TaskService().deleteTask(widget.task.id);

                    if (mounted) {
                      Navigator.pop(context, true); // Go back to home screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Task deleted successfully'),
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
