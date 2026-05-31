import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/reminder_model.dart';
import '../core/storage/storage_service.dart';
import '../core/notifications/notification_service.dart';
import '../core/widget/widget_service.dart';

class ReminderProvider extends ChangeNotifier {
  List<ReminderModel> _reminders = [];
  final _uuid = const Uuid();
  int _nextId = 10000;

  List<ReminderModel> get all => _reminders;
  List<ReminderModel> get upcoming => _reminders
      .where((r) => !r.isCompleted && r.dateTime.isAfter(DateTime.now()))
      .toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  List<ReminderModel> get past => _reminders
      .where((r) => r.isCompleted || r.dateTime.isBefore(DateTime.now()))
      .toList()
    ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  Future<void> load() async {
    _reminders = await StorageService.instance.loadReminders();
    if (_reminders.isNotEmpty) {
      _nextId = _reminders.map((r) => r.notificationId).reduce((a, b) => a > b ? a : b) + 1;
    }
    notifyListeners();
  }

  Future<void> _save() async {
    await StorageService.instance.saveReminders(_reminders);
    WidgetService.updateReminders(_reminders);
  }

  Future<void> create({
    required String title,
    String note = '',
    required DateTime dateTime,
    bool isRecurring = false,
    List<int> recurringDays = const [],
  }) async {
    final id = _nextId++;
    final reminder = ReminderModel(
      id: _uuid.v4(),
      title: title,
      note: note,
      dateTime: dateTime,
      isRecurring: isRecurring,
      recurringDays: recurringDays,
      notificationId: id,
    );
    _reminders.insert(0, reminder);
    notifyListeners();
    await _save();
    await _scheduleNotification(reminder);
  }

  Future<void> _scheduleNotification(ReminderModel r) async {
    final svc = NotificationService.instance;
    if (r.isRecurring && r.recurringDays.isNotEmpty) {
      for (int i = 0; i < r.recurringDays.length; i++) {
        await svc.scheduleWeekly(
          r.notificationId + i,
          r.title,
          r.note.isEmpty ? 'Rappel' : r.note,
          r.recurringDays[i],
          r.dateTime.hour,
          r.dateTime.minute,
        );
      }
    } else {
      await svc.scheduleOnce(r.notificationId, r.title, r.note.isEmpty ? 'Rappel' : r.note, r.dateTime);
    }
  }

  Future<void> toggleComplete(String id) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    _reminders[idx] = _reminders[idx].copyWith(isCompleted: !_reminders[idx].isCompleted);
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    final r = _reminders.firstWhere((r) => r.id == id);
    await NotificationService.instance.cancel(r.notificationId);
    _reminders.removeWhere((r) => r.id == id);
    notifyListeners();
    await _save();
  }
}
