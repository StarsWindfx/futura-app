import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../models/reminder_model.dart';
import '../../models/event_model.dart';
import '../../models/routine_model.dart';

class WidgetService {
  static Future<void> updateTasks(List<TaskModel> tasks) async {
    final pending = tasks.where((t) => !t.isCompleted).toList();
    await HomeWidget.saveWidgetData<int>('task_count', pending.length);
    for (int i = 0; i < 3; i++) {
      await HomeWidget.saveWidgetData<String>('task_$i', i < pending.length ? pending[i].title : '');
    }
    await HomeWidget.updateWidget(androidName: 'FuturaWidgetProvider');
  }

  // Keep backward compat
  static Future<void> update(List<TaskModel> tasks) => updateTasks(tasks);

  static Future<void> updateReminders(List<ReminderModel> reminders) async {
    final now = DateTime.now();
    final upcoming = reminders
        .where((r) => !r.isCompleted && r.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    await HomeWidget.saveWidgetData<int>('reminder_count', upcoming.length);
    for (int i = 0; i < 3; i++) {
      final r = i < upcoming.length ? upcoming[i] : null;
      await HomeWidget.saveWidgetData<String>('reminder_${i}_title', r?.title ?? '');
      await HomeWidget.saveWidgetData<String>('reminder_${i}_time',
          r != null ? DateFormat('HH:mm').format(r.dateTime) : '');
    }
    await HomeWidget.updateWidget(androidName: 'RemindersWidgetProvider');
  }

  static Future<void> updateEvents(List<EventModel> events) async {
    final now = DateTime.now();
    final today = events.where((e) => e.isOnDay(now)).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    await HomeWidget.saveWidgetData<int>('agenda_count', today.length);
    await HomeWidget.saveWidgetData<String>(
        'agenda_date', DateFormat('EEE d MMM', 'fr_FR').format(now));
    for (int i = 0; i < 3; i++) {
      final e = i < today.length ? today[i] : null;
      await HomeWidget.saveWidgetData<String>('agenda_${i}_title', e?.title ?? '');
      await HomeWidget.saveWidgetData<String>('agenda_${i}_time',
          e == null ? '' : (e.isAllDay ? 'Journée' : DateFormat('HH:mm').format(e.startDate)));
    }
    await HomeWidget.updateWidget(androidName: 'AgendaWidgetProvider');
  }

  static Future<void> updateRoutines(List<RoutineModel> routines) async {
    final active = routines.where((r) => r.isActive).toList()
      ..sort((a, b) => a.timeMinutes.compareTo(b.timeMinutes));
    await HomeWidget.saveWidgetData<int>('rtn_count', active.length);
    for (int i = 0; i < 3; i++) {
      final r = i < active.length ? active[i] : null;
      await HomeWidget.saveWidgetData<String>('rtn_${i}_title', r?.title ?? '');
      await HomeWidget.saveWidgetData<String>('rtn_${i}_time', r?.timeLabel ?? '');
    }
    await HomeWidget.updateWidget(androidName: 'RoutinesWidgetProvider');
  }
}
