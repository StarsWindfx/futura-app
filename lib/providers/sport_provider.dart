import 'package:flutter/foundation.dart';
import '../models/sport_model.dart';
import '../core/storage/storage_service.dart';

class SportProvider extends ChangeNotifier {
  List<SportExercise> _exercises = [];
  final Map<String, SportDayLog> _logs = {};

  List<SportExercise> get exercises => _exercises;

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get _today => _dateKey(DateTime.now());

  SportDayLog get todayLog => _logs[_today] ?? SportDayLog(date: _today, counts: {});

  SportDayLog logForDate(DateTime date) =>
      _logs[_dateKey(date)] ?? SportDayLog(date: _dateKey(date), counts: {});

  int countFor(String exerciseId) => todayLog.countFor(exerciseId);
  int countForDate(String exerciseId, DateTime date) => logForDate(date).countFor(exerciseId);

  List<SportExercise> activeForDate(DateTime date) =>
      _exercises.where((e) => !e.isRestOn(date)).toList();

  List<SportExercise> get activeToday => activeForDate(DateTime.now());

  int get completedToday {
    final now = DateTime.now();
    return _exercises
        .where((e) => !e.isRestOn(now) && countFor(e.id) >= e.dailyGoal)
        .length;
  }

  int get totalActiveToday => activeToday.length;
  int get total => _exercises.length;

  bool isDayComplete(DateTime date) {
    final active = activeForDate(date);
    if (active.isEmpty) return false;
    final log = logForDate(date);
    return active.every((e) => log.countFor(e.id) >= e.dailyGoal);
  }

  bool isDayPartial(DateTime date) {
    final log = logForDate(date);
    return log.totalReps > 0 && !isDayComplete(date);
  }

  int totalRepsForDate(DateTime date) => logForDate(date).totalReps;

  Future<void> load() async {
    _exercises = await StorageService.instance.loadExercises();
    if (_exercises.isEmpty) {
      _exercises = SportExercise.defaults;
      await StorageService.instance.saveExercises(_exercises);
    }
    final rawLogs = await StorageService.instance.loadSportLogs();
    _logs.addAll(rawLogs);
    notifyListeners();
  }

  Future<void> _saveExercises() => StorageService.instance.saveExercises(_exercises);

  Future<void> _saveLog(SportDayLog log) async {
    _logs[log.date] = log;
    await StorageService.instance.saveSportLogs(_logs);
  }

  Future<void> increment(String exerciseId, {int by = 1}) async {
    final newCount = todayLog.countFor(exerciseId) + by;
    await _saveLog(todayLog.withCount(exerciseId, newCount));
    notifyListeners();
  }

  Future<void> decrement(String exerciseId) async {
    final newCount = (todayLog.countFor(exerciseId) - 1).clamp(0, 99999);
    await _saveLog(todayLog.withCount(exerciseId, newCount));
    notifyListeners();
  }

  Future<void> setCount(String exerciseId, int count) async {
    await _saveLog(todayLog.withCount(exerciseId, count.clamp(0, 99999)));
    notifyListeners();
  }

  Future<void> reorderExercises(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex--;
    final item = _exercises.removeAt(oldIndex);
    _exercises.insert(newIndex, item);
    await _saveExercises();
    notifyListeners();
  }

  Future<void> addExercise(SportExercise ex) async {
    _exercises.add(ex);
    await _saveExercises();
    notifyListeners();
  }

  Future<void> updateExercise(SportExercise ex) async {
    final idx = _exercises.indexWhere((e) => e.id == ex.id);
    if (idx == -1) return;
    _exercises[idx] = ex;
    await _saveExercises();
    notifyListeners();
  }

  Future<void> removeExercise(String id) async {
    _exercises.removeWhere((e) => e.id == id);
    await _saveExercises();
    notifyListeners();
  }
}
