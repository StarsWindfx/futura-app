import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/task_model.dart';
import '../../models/reminder_model.dart';
import '../../models/routine_model.dart';
import '../../models/event_model.dart';
import '../../models/sport_model.dart';

class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  StorageService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Tasks
  Future<List<TaskModel>> loadTasks() async {
    final raw = _prefs.getString('tasks');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => TaskModel.fromJson(e)).toList();
  }

  Future<void> saveTasks(List<TaskModel> tasks) async {
    await _prefs.setString('tasks', jsonEncode(tasks.map((t) => t.toJson()).toList()));
  }

  // Reminders
  Future<List<ReminderModel>> loadReminders() async {
    final raw = _prefs.getString('reminders');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => ReminderModel.fromJson(e)).toList();
  }

  Future<void> saveReminders(List<ReminderModel> items) async {
    await _prefs.setString('reminders', jsonEncode(items.map((t) => t.toJson()).toList()));
  }

  // Routines
  Future<List<RoutineModel>> loadRoutines() async {
    final raw = _prefs.getString('routines');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => RoutineModel.fromJson(e)).toList();
  }

  Future<void> saveRoutines(List<RoutineModel> items) async {
    await _prefs.setString('routines', jsonEncode(items.map((t) => t.toJson()).toList()));
  }

  // Events
  Future<List<EventModel>> loadEvents() async {
    final raw = _prefs.getString('events');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => EventModel.fromJson(e)).toList();
  }

  Future<void> saveEvents(List<EventModel> items) async {
    await _prefs.setString('events', jsonEncode(items.map((t) => t.toJson()).toList()));
  }

  // Sport exercises
  Future<List<SportExercise>> loadExercises() async {
    final raw = _prefs.getString('sport_exercises');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => SportExercise.fromJson(e)).toList();
  }

  Future<void> saveExercises(List<SportExercise> exercises) async {
    await _prefs.setString('sport_exercises',
        jsonEncode(exercises.map((e) => e.toJson()).toList()));
  }

  // Sport logs
  Future<Map<String, SportDayLog>> loadSportLogs() async {
    final raw = _prefs.getString('sport_logs');
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, SportDayLog.fromJson(v as Map<String, dynamic>)));
  }

  Future<void> saveSportLogs(Map<String, SportDayLog> logs) async {
    await _prefs.setString('sport_logs',
        jsonEncode(logs.map((k, v) => MapEntry(k, v.toJson()))));
  }

  // Settings
  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) => _prefs.setString(key, value);
  bool? getBool(String key) => _prefs.getBool(key);
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  int? getInt(String key) => _prefs.getInt(key);
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  Future<void> clearAll() async => _prefs.clear();
}
