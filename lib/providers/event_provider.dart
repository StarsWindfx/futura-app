import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';
import '../core/storage/storage_service.dart';
import '../core/notifications/notification_service.dart';
import '../core/widget/widget_service.dart';

class EventProvider extends ChangeNotifier {
  List<EventModel> _events = [];
  final _uuid = const Uuid();
  int _nextId = 30000;

  List<EventModel> get all => _events;

  List<EventModel> eventsForDay(DateTime day) =>
      _events.where((e) => e.isOnDay(day)).toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

  List<EventModel> get today => eventsForDay(DateTime.now());

  Future<void> load() async {
    _events = await StorageService.instance.loadEvents();
    if (_events.isNotEmpty) {
      _nextId = _events.map((e) => e.notificationId).reduce((a, b) => a > b ? a : b) + 1;
    }
    notifyListeners();
  }

  Future<void> _save() async {
    await StorageService.instance.saveEvents(_events);
    WidgetService.updateEvents(_events);
  }

  Future<void> create({
    required String title,
    String description = '',
    required DateTime startDate,
    required DateTime endDate,
    bool isAllDay = false,
    int colorIndex = 0,
    bool withNotification = true,
  }) async {
    final id = _nextId++;
    final event = EventModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      isAllDay: isAllDay,
      colorIndex: colorIndex,
      notificationId: id,
    );
    _events.insert(0, event);
    notifyListeners();
    await _save();
    if (withNotification && !isAllDay) {
      final notifTime = startDate.subtract(const Duration(minutes: 15));
      await NotificationService.instance.scheduleOnce(id, title, description.isEmpty ? 'Événement dans 15 min' : description, notifTime);
    }
  }

  Future<void> update(EventModel event) async {
    final idx = _events.indexWhere((e) => e.id == event.id);
    if (idx == -1) return;
    _events[idx] = event;
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    final e = _events.firstWhere((e) => e.id == id);
    await NotificationService.instance.cancel(e.notificationId);
    _events.removeWhere((e) => e.id == id);
    notifyListeners();
    await _save();
  }
}
