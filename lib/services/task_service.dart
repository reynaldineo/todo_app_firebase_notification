import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskService {
  final _db = FirebaseFirestore.instance.collection('tasks');

  Future<void> addTask(Task task) async {
    await _db.add(task.toMap());
  }

  Stream<List<Task>> getTasks() {
    return _db.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromMap(doc.id, doc.data())).toList();
    });
  }

  Future<void> updateTask(Task task) async {
    await _db.doc(task.id).update(task.toMap());
  }

  Future<void> deleteTask(String id) async {
    await _db.doc(id).delete();
  }
}
