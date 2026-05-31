import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/futura_tile.dart';
import '../../providers/task_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/event_provider.dart';
import '../tasks/add_task_sheet.dart';
import '../agenda/add_event_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Column(children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: C.elevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: C.border, width: 0.5),
                  ),
                  child: Row(children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.search, color: C.muted, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        style: T.body(context),
                        decoration: InputDecoration(
                          hintText: 'Rechercher...',
                          hintStyle: T.body(context).copyWith(color: C.muted),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                      ),
                    ),
                    if (_q.isNotEmpty)
                      GestureDetector(
                        onTap: () { _ctrl.clear(); setState(() => _q = ''); },
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.close, color: C.muted, size: 16),
                        ),
                      ),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text('Annuler', style: T.small(context).copyWith(color: C.ink)),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          const Divider(color: C.line, thickness: 0.5, height: 0),
          Expanded(
            child: _q.isEmpty
                ? _Hint()
                : _Results(query: _q),
          ),
        ]),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.search, color: C.muted, size: 32),
        const SizedBox(height: 12),
        Text('Tâches, rappels, routines, événements', style: T.small(context).copyWith(color: C.muted)),
      ]).animate().fadeIn(duration: 200.ms),
    );
  }
}

class _Results extends StatelessWidget {
  final String query;
  const _Results({required this.query});

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>().all.where((t) => t.title.toLowerCase().contains(query) || t.description.toLowerCase().contains(query) || t.category.toLowerCase().contains(query)).toList();
    final reminders = context.watch<ReminderProvider>().all.where((r) => r.title.toLowerCase().contains(query) || r.note.toLowerCase().contains(query)).toList();
    final routines = context.watch<RoutineProvider>().all.where((r) => r.title.toLowerCase().contains(query) || r.description.toLowerCase().contains(query)).toList();
    final events = context.watch<EventProvider>().all.where((e) => e.title.toLowerCase().contains(query) || e.description.toLowerCase().contains(query)).toList();

    final isEmpty = tasks.isEmpty && reminders.isEmpty && routines.isEmpty && events.isEmpty;
    if (isEmpty) {
      return Center(
        child: Text('Aucun résultat', style: T.small(context).copyWith(color: C.muted)),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 120),
      children: [
        if (tasks.isNotEmpty) ...[
          FSectionLabel(text: 'TÂCHES'),
          ...tasks.take(5).map((t) => _Item(
            icon: t.isCompleted ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            iconColor: t.isCompleted ? C.ok : C.muted,
            title: t.title,
            sub: t.category.isNotEmpty ? t.category : (t.dueDate != null ? DateFormat('d MMM', 'fr_FR').format(t.dueDate!) : ''),
            onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => AddTaskSheet(task: t)),
          )),
        ],
        if (reminders.isNotEmpty) ...[
          FSectionLabel(text: 'RAPPELS'),
          ...reminders.take(5).map((r) => _Item(
            icon: Icons.notifications_outlined,
            iconColor: C.blue,
            title: r.title,
            sub: DateFormat('d MMM · HH:mm', 'fr_FR').format(r.dateTime),
            onTap: () {},
          )),
        ],
        if (routines.isNotEmpty) ...[
          FSectionLabel(text: 'ROUTINES'),
          ...routines.take(5).map((r) => _Item(
            icon: Icons.repeat_rounded,
            iconColor: C.muted,
            title: r.title,
            sub: '${r.timeLabel} · ${r.daysLabel}',
            onTap: () {},
          )),
        ],
        if (events.isNotEmpty) ...[
          FSectionLabel(text: 'ÉVÉNEMENTS'),
          ...events.take(5).map((e) => _Item(
            icon: Icons.calendar_today_outlined,
            iconColor: C.warn,
            title: e.title,
            sub: DateFormat('d MMM', 'fr_FR').format(e.startDate),
            onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => AddEventSheet(initialDate: e.startDate)),
          )),
        ],
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String sub;
  final VoidCallback onTap;
  const _Item({required this.icon, required this.iconColor, required this.title, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: T.body(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (sub.isNotEmpty) Text(sub, style: T.mono(context).copyWith(fontSize: 11, color: C.muted)),
              ]),
            ),
          ]),
        ),
        const Divider(height: 0, thickness: 0.5, color: C.line),
      ]),
    );
  }
}
