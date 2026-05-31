import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../core/storage/storage_service.dart';
import '../core/widget/widget_service.dart';

class TaskProvider extends ChangeNotifier {
  List<TaskModel> _tasks = [];
  final _uuid = const Uuid();
  Timer? _midnightTimer;

  List<TaskModel> get all => _tasks;
  List<TaskModel> get pending => _tasks.where((t) => !t.isCompleted).toList();
  List<TaskModel> get completed => _tasks.where((t) => t.isCompleted).toList();
  List<TaskModel> get today {
    final now = DateTime.now();
    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      final d = t.dueDate!;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
  }

  List<TaskModel> get highPriority =>
      _tasks.where((t) => t.priority == 2 && !t.isCompleted).toList();

  Future<void> load() async {
    _tasks = await StorageService.instance.loadTasks();
    _removeOldCompleted();
    _scheduleMidnightCleanup();
    notifyListeners();
  }

  void _removeOldCompleted() {
    final today = DateTime.now();
    _tasks.removeWhere((t) {
      if (!t.isCompleted || t.completedAt == null) return false;
      final c = t.completedAt!;
      return c.year < today.year || c.month < today.month || c.day < today.day;
    });
  }

  void _scheduleMidnightCleanup() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final delay = midnight.difference(now);
    _midnightTimer = Timer(delay, () async {
      _removeOldCompleted();
      await _save();
      _scheduleMidnightCleanup();
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  Future<void> _save() async {
    await StorageService.instance.saveTasks(_tasks);
    WidgetService.update(_tasks);
  }

  Future<void> add(TaskModel task) async {
    _tasks.insert(0, task);
    notifyListeners();
    await _save();
  }

  Future<TaskModel> create({
    required String title,
    String description = '',
    int priority = 0,
    DateTime? dueDate,
    String category = '',
    List<String> subtasks = const [],
    List<bool> subtasksDone = const [],
  }) async {
    final task = TaskModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      category: category,
      createdAt: DateTime.now(),
      subtasks: subtasks,
      subtasksDone: subtasksDone,
    );
    await add(task);
    return task;
  }

  Future<void> update(TaskModel task) async {
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx == -1) return;
    _tasks[idx] = task;
    notifyListeners();
    await _save();
  }

  Future<void> toggleComplete(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final wasCompleted = _tasks[idx].isCompleted;
    _tasks[idx] = _tasks[idx].copyWith(
      isCompleted: !wasCompleted,
      completedAt: wasCompleted ? null : DateTime.now(),
      clearCompletedAt: wasCompleted,
    );
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> clearCompleted() async {
    _tasks.removeWhere((t) => t.isCompleted);
    notifyListeners();
    await _save();
  }
}
