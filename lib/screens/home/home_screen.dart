import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/storage/storage_service.dart';
import '../../models/event_model.dart';
import '../../models/task_model.dart';
import '../../providers/event_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/futura_tile.dart';
import '../../widgets/quick_add_sheet.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int> onGo;
  const HomeScreen({super.key, required this.onGo});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Stream<DateTime> _clock;

  @override
  void initState() {
    super.initState();
    _clock = Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now()).map((_) => DateTime.now());
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Bonne nuit';
    if (h < 12) return 'Bonjour';
    if (h < 18) return "Bon après-midi";
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    final name = StorageService.instance.getString('user_name') ?? '';
    return Scaffold(
      backgroundColor: C.bg,
      body: Consumer4<TaskProvider, ReminderProvider, RoutineProvider, EventProvider>(
        builder: (ctx, tasks, reminders, routines, events, _) {
          final pending = tasks.pending;
          final todayEvents = events.today;
          final todayTasks = tasks.today.where((t) => !t.isCompleted).toList();
          final upcoming = reminders.upcoming.take(2).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      StreamBuilder<DateTime>(
                        stream: _clock,
                        initialData: DateTime.now(),
                        builder: (_, snap) {
                          final now = snap.data!;
                          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              DateFormat('HH:mm').format(now),
                              style: T.monoXl(context),
                            ).animate().fadeIn(duration: 600.ms),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE d MMMM', 'fr_FR').format(now),
                              style: T.small(context).copyWith(color: C.dim),
                            ).animate().fadeIn(delay: 100.ms),
                          ]);
                        },
                      ),
                      if (name.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${_greeting()}, $name',
                          style: T.small(context).copyWith(color: C.muted),
                        ).animate().fadeIn(delay: 150.ms),
                      ],
                      const SizedBox(height: 16),
                      // Quick actions
                      Row(children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const QuickAddSheet(),
                            ),
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: C.elevated,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: C.border, width: 0.5),
                              ),
                              child: Row(children: [
                                const SizedBox(width: 12),
                                const Icon(Icons.add, color: C.muted, size: 16),
                                const SizedBox(width: 8),
                                Text('Ajouter...', style: T.small(context).copyWith(color: C.muted)),
                              ]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: C.elevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: C.border, width: 0.5),
                            ),
                            child: const Icon(Icons.search, color: C.muted, size: 18),
                          ),
                        ),
                      ]).animate().fadeIn(delay: 180.ms),
                    ]),
                  ),
                ),
              ),

              // ── Stats ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
                  child: _StatsRow(
                    tasksDone: tasks.completed.length,
                    tasksTotal: tasks.all.length,
                    events: todayEvents.length,
                    routines: routines.active.length,
                    onTasksTap: () => widget.onGo(1),
                    onEventsTap: () => widget.onGo(3),
                    onRoutinesTap: () => widget.onGo(4),
                  ).animate().fadeIn(delay: 200.ms),
                ),
              ),

              // ── Divider ──────────────────────────────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                  child: Divider(color: C.line, thickness: 0.5, height: 0),
                ),
              ),

              // ── Tâches du jour ────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                sliver: SliverToBoxAdapter(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    FSectionLabel(
                      text: todayTasks.isNotEmpty ? 'AUJOURD\'HUI' : 'EN COURS',
                      action: 'Voir tout',
                      onAction: () => widget.onGo(1),
                    ),
                    ...(todayTasks.isNotEmpty ? todayTasks : pending).take(4).toList().asMap().entries.map((e) {
                      return _MiniTaskRow(task: e.value, index: e.key);
                    }),
                    if (pending.length > 4)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: GestureDetector(
                          onTap: () => widget.onGo(1),
                          child: Text(
                            '+${pending.length - 4} autres tâches',
                            style: T.small(context).copyWith(color: C.ink),
                          ),
                        ),
                      ),
                    if (pending.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('Tout est à jour ✓', style: T.small(context).copyWith(color: C.ok)),
                      ),
                  ]),
                ),
              ),

              // ── Agenda ────────────────────────────────────────────────
              if (todayEvents.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  sliver: SliverToBoxAdapter(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      FSectionLabel(text: 'AGENDA', action: 'Calendrier', onAction: () => widget.onGo(3)),
                      ...todayEvents.take(3).toList().asMap().entries.map((e) {
                        return _EventRow(event: e.value, index: e.key);
                      }),
                    ]),
                  ),
                ),
              ],

              // ── Rappels ───────────────────────────────────────────────
              if (upcoming.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  sliver: SliverToBoxAdapter(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      FSectionLabel(text: 'RAPPELS', action: 'Tous', onAction: () => widget.onGo(2)),
                      ...upcoming.toList().asMap().entries.map((e) {
                        final r = e.value;
                        return FRow(
                          showDivider: e.key < upcoming.length - 1,
                          child: Row(children: [
                            const Icon(Icons.notifications_outlined, size: 14, color: C.dim),
                            const SizedBox(width: 10),
                            Expanded(child: Text(r.title, style: T.body(context), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Text(DateFormat('HH:mm', 'fr_FR').format(r.dateTime), style: T.mono(context)),
                          ]),
                        ).animate(delay: Duration(milliseconds: e.key * 40)).fadeIn();
                      }),
                    ]),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),
    );
  }
}

// ── Stats ─────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int tasksDone, tasksTotal, events, routines;
  final VoidCallback onTasksTap, onEventsTap, onRoutinesTap;

  const _StatsRow({
    required this.tasksDone,
    required this.tasksTotal,
    required this.events,
    required this.routines,
    required this.onTasksTap,
    required this.onEventsTap,
    required this.onRoutinesTap,
  });

  @override
  Widget build(BuildContext context) {
    final pending = tasksTotal - tasksDone;
    final pct = tasksTotal == 0 ? 1.0 : tasksDone / tasksTotal;

    return Row(children: [
      // Donut chart
      GestureDetector(
        onTap: onTasksTap,
        child: SizedBox(
          width: 72, height: 72,
          child: Stack(alignment: Alignment.center, children: [
            PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 26,
                startDegreeOffset: -90,
                sections: [
                  PieChartSectionData(color: C.ink, value: pct, radius: 8, showTitle: false),
                  PieChartSectionData(color: C.elevated, value: 1 - pct, radius: 8, showTitle: false),
                ],
              ),
            ),
            Text(
              '$pending',
              style: T.monoLg(context).copyWith(fontSize: 18),
            ),
          ]),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: onTasksTap,
            child: Text(
              pending == 0 ? 'Tout terminé' : '$pending tâche${pending > 1 ? 's' : ''} en attente',
              style: T.h3(context),
            ),
          ),
          const SizedBox(height: 6),
          Row(children: [
            GestureDetector(
              onTap: onEventsTap,
              child: _StatChip(value: events, label: 'événement${events > 1 ? 's' : ''}'),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onRoutinesTap,
              child: _StatChip(value: routines, label: 'routine${routines > 1 ? 's' : ''}'),
            ),
          ]),
        ]),
      ),
    ]);
  }
}

class _StatChip extends StatelessWidget {
  final int value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: C.elevated, borderRadius: BorderRadius.circular(6)),
      child: Text('$value $label', style: T.small(context).copyWith(fontSize: 12)),
    );
  }
}

// ── Mini tâche row ─────────────────────────────────────────────────────────────
class _MiniTaskRow extends StatelessWidget {
  final TaskModel task;
  final int index;
  const _MiniTaskRow({required this.task, required this.index});

  @override
  Widget build(BuildContext context) {
    return FRow(
      showDivider: true,
      child: Row(children: [
        Container(
          width: 18, height: 18,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.muted, width: 1)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(task.title, style: T.body(context), maxLines: 1, overflow: TextOverflow.ellipsis)),
        if (task.priority > 0)
          Container(width: 5, height: 5, decoration: BoxDecoration(color: C.priority(task.priority), shape: BoxShape.circle)),
      ]),
    ).animate(delay: Duration(milliseconds: index * 40)).fadeIn().slideX(begin: 0.03);
  }
}

// ── Event row ─────────────────────────────────────────────────────────────────
const _eventColors = [C.ink, C.blue, C.ok, C.warn, C.err];

class _EventRow extends StatelessWidget {
  final EventModel event;
  final int index;
  const _EventRow({required this.event, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = _eventColors[event.colorIndex.clamp(0, 4)];
    return FRow(
      showDivider: true,
      child: Row(children: [
        Container(width: 2, height: 34, color: color, margin: const EdgeInsets.only(right: 14)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(event.title, style: T.body(context), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(
            event.isAllDay ? 'Journée entière' : '${DateFormat('HH:mm').format(event.startDate)} → ${DateFormat('HH:mm').format(event.endDate)}',
            style: T.mono(context),
          ),
        ])),
      ]),
    ).animate(delay: Duration(milliseconds: index * 40)).fadeIn();
  }
}
