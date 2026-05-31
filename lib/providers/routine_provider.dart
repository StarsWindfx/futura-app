import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/routine_model.dart';
import '../core/storage/storage_service.dart';
import '../core/notifications/notification_service.dart';
import '../core/widget/widget_service.dart';

class RoutineProvider extends ChangeNotifier {
  List<RoutineModel> _routines = [];
  final _uuid = const Uuid();
  int _nextId = 20000;

  List<RoutineModel> get all => _routines;
  List<RoutineModel> get active => _routines.where((r) => r.isActive).toList();

  Future<void> load() async {
    _routines = await StorageService.instance.loadRoutines();
    if (_routines.isNotEmpty) {
      final ids = [
        ..._routines.expand((r) => r.notificationIds),
        ..._routines.expand((r) => r.alertNotifIds),
      ];
      if (ids.isNotEmpty) _nextId = ids.reduce((a, b) => a > b ? a : b) + 1;
    }
    notifyListeners();
  }

  Future<void> _save() async {
    await StorageService.instance.saveRoutines(_routines);
    WidgetService.updateRoutines(_routines);
  }

  /// Calcule tous les créneaux de notification entre start et end.
  List<int> _fireTimes(int startMins, int? endMins, RecurringAlertType type, int intervalMins) {
    if (type == RecurringAlertType.none) return [];
    if (type == RecurringAlertType.daily) return [startMins]; // quotidien = une fois au démarrage
    final int step = type == RecurringAlertType.hourly ? 60 : intervalMins;
    final int limit = endMins ?? startMins; // sans plage = juste le début
    final times = <int>[];
    int t = startMins;
    while (t <= limit) {
      times.add(t);
      t += step;
    }
    return times;
  }

  Future<void> create({
    required String title,
    String description = '',
    List<String> steps = const [],
    required int timeMinutes,
    int? endTimeMinutes,
    List<int> days = const [1, 2, 3, 4, 5],
    bool notificationsEnabled = true,
    RecurringAlertType alertType = RecurringAlertType.none,
    int alertIntervalMinutes = 60,
  }) async {
    final notifIds = days.map((_) => _nextId++).toList();
    final slots = _fireTimes(timeMinutes, endTimeMinutes, alertType, alertIntervalMinutes);
    final alertIds = slots.isNotEmpty
        ? List.generate(days.length * slots.length, (_) => _nextId++)
        : <int>[];

    final routine = RoutineModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      steps: steps,
      timeMinutes: timeMinutes,
      endTimeMinutes: endTimeMinutes,
      days: days,
      notificationsEnabled: notificationsEnabled,
      notificationIds: notifIds,
      alertType: alertType,
      alertIntervalMinutes: alertIntervalMinutes,
      alertNotifIds: alertIds,
    );
    _routines.insert(0, routine);
    notifyListeners();
    await _save();
    if (notificationsEnabled) await _scheduleAll(routine);
  }

  Future<void> update(RoutineModel updated) async {
    final idx = _routines.indexWhere((r) => r.id == updated.id);
    if (idx == -1) return;
    await _cancelAll(_routines[idx]);

    // Réalloue les IDs de notification selon le nouveau nombre de jours
    final notifIds = List.generate(updated.days.length, (_) => _nextId++);

    // Réalloue les IDs d'alerte selon la nouvelle plage
    final slots = _fireTimes(updated.timeMinutes, updated.endTimeMinutes, updated.alertType, updated.alertIntervalMinutes);
    final needed = slots.isNotEmpty ? updated.days.length * slots.length : 0;
    final alertIds = List.generate(needed, (_) => _nextId++);
    final refreshed = updated.copyWith(notificationIds: notifIds, alertNotifIds: alertIds);

    _routines[idx] = refreshed;
    notifyListeners();
    await _save();
    if (refreshed.isActive && refreshed.notificationsEnabled) await _scheduleAll(refreshed);
  }

  Future<void> toggleActive(String id) async {
    final idx = _routines.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    final r = _routines[idx];
    final updated = r.copyWith(isActive: !r.isActive);
    _routines[idx] = updated;
    notifyListeners();
    await _save();
    if (updated.isActive && updated.notificationsEnabled) {
      await _scheduleAll(updated);
    } else {
      await _cancelAll(updated);
    }
  }

  Future<void> remove(String id) async {
    final r = _routines.firstWhere((r) => r.id == id);
    await _cancelAll(r);
    _routines.removeWhere((r) => r.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> _scheduleAll(RoutineModel r) async {
    final svc = NotificationService.instance;
    for (int i = 0; i < r.days.length && i < r.notificationIds.length; i++) {
      await svc.scheduleWeekly(r.notificationIds[i], r.title, r.description.isEmpty ? 'Rappel routine' : r.description, r.days[i], r.hour, r.minute);
    }
    if (r.alertType != RecurringAlertType.none && r.alertNotifIds.isNotEmpty) {
      await _scheduleRecurringAlert(r);
    }
  }

  Future<void> _scheduleRecurringAlert(RoutineModel r) async {
    final svc = NotificationService.instance;
    final slots = _fireTimes(r.timeMinutes, r.endTimeMinutes, r.alertType, r.alertIntervalMinutes);
    if (slots.isEmpty) return;

    int idIdx = 0;
    for (int dayIdx = 0; dayIdx < r.days.length; dayIdx++) {
      for (final fireTime in slots) {
        if (idIdx >= r.alertNotifIds.length) break;
        await svc.scheduleWeekly(
          r.alertNotifIds[idIdx],
          '${r.title} — rappel',
          r.alertLabel,
          r.days[dayIdx],
          (fireTime ~/ 60) % 24,
          fireTime % 60,
        );
        idIdx++;
      }
    }
  }

  Future<void> _cancelAll(RoutineModel r) async {
    for (final id in r.notificationIds) await NotificationService.instance.cancel(id);
    for (final id in r.alertNotifIds) await NotificationService.instance.cancel(id);
  }
}
