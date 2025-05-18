class Task {
  String id;
  String title;
  bool isCompleted;
  DateTime dueDate;

  Task({
    required this.id,
    required this.title,
    required this.dueDate,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isCompleted': isCompleted,
      'dueDate': dueDate.toIso8601String(),
    };
  }

  static Task fromMap(String id, Map<String, dynamic> map) {
    return Task(
      id: id,
      title: map['title'],
      isCompleted: map['isCompleted'],
      dueDate: DateTime.parse(map['dueDate']),
    );
  }

  @override
  String toString() {
    return 'Task{id: $id, title: $title, isCompleted: $isCompleted, dueDate: ${dueDate.toIso8601String()}}';
  }
}
