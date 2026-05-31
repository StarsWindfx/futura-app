import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_theme.dart';
import '../../models/sport_model.dart';
import '../../providers/sport_provider.dart';
import 'add_exercise_sheet.dart';

extension _Capitalize on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

class SportScreen extends StatefulWidget {
  const SportScreen({super.key});

  @override
  State<SportScreen> createState() => _SportScreenState();
}

class _SportScreenState extends State<SportScreen> {
  int _tab = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  void _openSheet([SportExercise? ex]) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddExerciseSheet(exercise: ex),
      );

  String _motivation(int completed, int total) {
    if (total == 0) return 'Ajoute tes exercices';
    if (completed == total) return 'Objectifs atteints 🏆';
    if (completed == 0) return 'Allez, c\'est parti !';
    final pct = completed / total;
    if (pct < 0.35) return 'Lance-toi 🔥';
    if (pct < 0.65) return 'Continue comme ça !';
    return 'Presque là, pousse !';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Consumer<SportProvider>(builder: (_, p, __) {
        return CustomScrollView(
          key: ValueKey(_tab),
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────────
            SliverSafeArea(
              bottom: false,
              sliver: SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sport', style: T.h1(context)),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now()),
                              style: T.small(context),
                            ),
                          ],
                        ),
                      ),
                      if (_tab == 0)
                        GestureDetector(
                          onTap: () => _openSheet(),
                          child: Container(
                            width: 32, height: 32,
                            decoration: const BoxDecoration(color: C.ink, shape: BoxShape.circle),
                            child: const Icon(Icons.add_rounded, color: C.bg, size: 18),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // ── Tabs ─────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: C.elevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: C.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      _TabBtn(label: 'Aujourd\'hui', selected: _tab == 0,
                          onTap: () => setState(() => _tab = 0)),
                      _TabBtn(label: 'Historique', selected: _tab == 1,
                          onTap: () => setState(() => _tab = 1)),
                    ],
                  ),
                ),
              ),
            ),
            // ── Content ──────────────────────────────────────────────
            if (_tab == 0) ..._todaySliver(p) else ..._historySliver(p),
          ],
        );
      }),
    );
  }

  // ── Today tab ────────────────────────────────────────────────────────
  List<Widget> _todaySliver(SportProvider p) => [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
          sliver: SliverToBoxAdapter(
            child: _DayProgress(
              completed: p.completedToday,
              total: p.totalActiveToday,
              motivation: _motivation(p.completedToday, p.totalActiveToday),
            ),
          ),
        ),
        if (p.exercises.isEmpty)
          SliverFillRemaining(child: _EmptyState(onAdd: () => _openSheet()))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 120),
            sliver: SliverReorderableList(
              itemCount: p.exercises.length,
              onReorder: (oldIndex, newIndex) {
                HapticFeedback.mediumImpact();
                p.reorderExercises(oldIndex, newIndex);
              },
              proxyDecorator: (child, index, animation) => Material(
                color: Colors.transparent,
                child: child,
              ),
              itemBuilder: (_, i) {
                final ex = p.exercises[i];
                return _ExerciseCard(
                  key: ValueKey(ex.id),
                  exercise: ex,
                  count: p.countFor(ex.id),
                  index: i,
                  isRest: ex.isRestToday,
                  onAdd: (by) {
                    HapticFeedback.lightImpact();
                    p.increment(ex.id, by: by);
                  },
                  onSet: (v) => p.setCount(ex.id, v),
                  onDecrement: () {
                    HapticFeedback.selectionClick();
                    p.decrement(ex.id);
                  },
                  onEdit: () => _openSheet(ex),
                  onDelete: () => p.removeExercise(ex.id),
                );
              },
            ),
          ),
      ];

  // ── History tab ──────────────────────────────────────────────────────
  List<Widget> _historySliver(SportProvider p) => [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 120),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SportCalendar(
                  provider: p,
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  onDaySelected: (sel, foc) => setState(() {
                    _selectedDay = sel;
                    _focusedDay = foc;
                  }),
                  onPageChanged: (foc) => setState(() => _focusedDay = foc),
                ),
                const SizedBox(height: 20),
                _DayBreakdown(day: _selectedDay, provider: p),
                const SizedBox(height: 28),
                Text('ÉVOLUTION — 14 JOURS', style: T.label(context)),
                const SizedBox(height: 12),
                _TrendChart(provider: p),
              ],
            ),
          ),
        ),
      ];
}

// ── Tab button ────────────────────────────────────────────────────────────────
class _TabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? C.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? C.bg : C.dim,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Day progress header ───────────────────────────────────────────────────────
class _DayProgress extends StatelessWidget {
  final int completed;
  final int total;
  final String motivation;
  const _DayProgress(
      {required this.completed, required this.total, required this.motivation});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    final allDone = total > 0 && completed == total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: allDone ? C.ok.withValues(alpha: 0.07) : C.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: allDone ? C.ok.withValues(alpha: 0.25) : C.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(motivation, style: T.h3(context))),
              Text(
                total == 0 ? '—' : '$completed / $total',
                style: T.mono(context)
                    .copyWith(color: allDone ? C.ok : C.dim, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: progress),
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  backgroundColor: C.line,
                  valueColor: AlwaysStoppedAnimation(allDone ? C.ok : C.ink),
                  minHeight: 4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Exercise card ─────────────────────────────────────────────────────────────
class _ExerciseCard extends StatefulWidget {
  final SportExercise exercise;
  final int count;
  final int index;
  final bool isRest;
  final void Function(int by) onAdd;
  final void Function(int value) onSet;
  final VoidCallback onDecrement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExerciseCard({
    super.key,
    required this.exercise,
    required this.count,
    required this.index,
    required this.isRest,
    required this.onAdd,
    required this.onSet,
    required this.onDecrement,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final TextEditingController _editCtrl;
  late final FocusNode _focusNode;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.28, end: 1.0), weight: 55),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _editCtrl = TextEditingController();
    _focusNode = FocusNode()
      ..addListener(() {
        if (!_focusNode.hasFocus && _editing) _commitEdit();
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _editCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleAdd(int by) {
    widget.onAdd(by);
    _ctrl.forward(from: 0);
  }

  void _startEdit() {
    setState(() {
      _editing = true;
      _editCtrl.text = '${widget.count}';
      _editCtrl.selection =
          TextSelection(baseOffset: 0, extentOffset: _editCtrl.text.length);
    });
    Future.microtask(() => _focusNode.requestFocus());
  }

  void _commitEdit() {
    final v = int.tryParse(_editCtrl.text.trim()) ?? widget.count;
    widget.onSet(v);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.exercise.dailyGoal;
    final count = widget.count;
    final progress = (count / goal).clamp(0.0, 1.0);
    final done = !widget.isRest && count >= goal;

    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.4,
        children: [
          SlidableAction(
            onPressed: (_) => widget.onEdit(),
            backgroundColor: Colors.transparent,
            foregroundColor: C.dim,
            icon: Icons.edit_outlined,
            padding: EdgeInsets.zero,
          ),
          SlidableAction(
            onPressed: (_) => widget.onDelete(),
            backgroundColor: Colors.transparent,
            foregroundColor: C.err,
            icon: Icons.delete_outline,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
      child: Opacity(
        opacity: widget.isRest ? 0.42 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: C.elevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: done ? C.ok.withValues(alpha: 0.35) : C.border,
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: accent + emoji + name + count + drag handle
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 3, height: 38,
                      decoration: BoxDecoration(
                        color: done ? C.ok : (widget.isRest ? C.muted : C.ink),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(widget.exercise.emoji,
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(widget.exercise.name, style: T.h3(context)),
                            if (done) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.check_circle_rounded,
                                  color: C.ok, size: 13),
                            ],
                            if (widget.isRest) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: C.border, width: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('REPOS',
                                    style: T.label(context)
                                        .copyWith(fontSize: 9)),
                              ),
                            ],
                          ]),
                          Text(
                            'Objectif : $goal ${widget.exercise.unit}',
                            style: T.small(context),
                          ),
                        ],
                      ),
                    ),
                    // Count — tap pour éditer manuellement
                    GestureDetector(
                      onTap: _editing ? null : _startEdit,
                      child: _editing
                          ? SizedBox(
                              width: 64,
                              child: TextField(
                                controller: _editCtrl,
                                focusNode: _focusNode,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                textAlign: TextAlign.right,
                                style: T.monoLg(context).copyWith(
                                  color: done ? C.ok : C.ink,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  filled: false,
                                ),
                                onSubmitted: (_) => _commitEdit(),
                              ),
                            )
                          : AnimatedBuilder(
                              animation: _scale,
                              builder: (_, child) => Transform.scale(
                                  scale: _scale.value, child: child),
                              child: Text(
                                '$count',
                                style: T.monoLg(context).copyWith(
                                  color: done ? C.ok : C.ink,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    ReorderableDelayedDragStartListener(
                      index: widget.index,
                      child: const Icon(Icons.drag_handle_rounded, color: C.muted, size: 18),
                    ),
                  ],
                ),
                if (!widget.isRest) ...[
                  const SizedBox(height: 12),
                  // Row 2: progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                      tween: Tween(begin: 0, end: progress),
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        backgroundColor: C.line,
                        valueColor: AlwaysStoppedAnimation(done ? C.ok : C.ink),
                        minHeight: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Row 3: buttons
                  Row(
                    children: [
                      _IconBtn(
                        onTap: widget.onDecrement,
                        child: const Icon(Icons.remove_rounded,
                            size: 14, color: C.dim),
                      ),
                      const Spacer(),
                      _ChipBtn(label: '+1', filled: false,
                          onTap: () => _handleAdd(1)),
                      const SizedBox(width: 6),
                      _ChipBtn(label: '+5', filled: false,
                          onTap: () => _handleAdd(5)),
                      const SizedBox(width: 6),
                      _ChipBtn(label: '+10', filled: true,
                          onTap: () => _handleAdd(10)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: widget.index * 45))
        .fadeIn()
        .slideX(begin: 0.04, end: 0);
  }
}

class _IconBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _IconBtn({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: C.sheet,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: C.border, width: 0.5),
          ),
          child: Center(child: child),
        ),
      );
}

class _ChipBtn extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _ChipBtn(
      {required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: filled ? C.ink : C.sheet,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: filled ? C.ink : C.border, width: 0.5),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: filled ? C.bg : C.dim,
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ),
        ),
      );
}

// ── Calendar ──────────────────────────────────────────────────────────────────
class _SportCalendar extends StatelessWidget {
  final SportProvider provider;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final void Function(DateTime, DateTime) onDaySelected;
  final void Function(DateTime) onPageChanged;

  const _SportCalendar({
    required this.provider,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: C.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.border, width: 0.5),
      ),
      child: TableCalendar(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now(),
        focusedDay: focusedDay,
        locale: 'fr_FR',
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {CalendarFormat.month: 'Mois'},
        startingDayOfWeek: StartingDayOfWeek.monday,
        rowHeight: 42,
        selectedDayPredicate: (d) => isSameDay(d, selectedDay),
        onDaySelected: onDaySelected,
        onPageChanged: onPageChanged,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
              color: C.ink,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter'),
          leftChevronIcon:
              Icon(Icons.chevron_left_rounded, color: C.dim, size: 18),
          rightChevronIcon:
              Icon(Icons.chevron_right_rounded, color: C.dim, size: 18),
          headerPadding: EdgeInsets.symmetric(vertical: 10),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
              color: C.muted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter'),
          weekendStyle: TextStyle(
              color: C.muted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter'),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          cellMargin: const EdgeInsets.all(3),
          defaultTextStyle:
              const TextStyle(color: C.dim, fontSize: 13, fontFamily: 'Inter'),
          weekendTextStyle:
              const TextStyle(color: C.dim, fontSize: 13, fontFamily: 'Inter'),
          todayTextStyle: const TextStyle(
              color: C.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter'),
          selectedTextStyle: const TextStyle(
              color: C.bg,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter'),
          disabledTextStyle:
              const TextStyle(color: C.muted, fontSize: 13, fontFamily: 'Inter'),
          todayDecoration: BoxDecoration(
              border: Border.all(color: C.ink, width: 0.75),
              shape: BoxShape.circle),
          selectedDecoration:
              const BoxDecoration(color: C.ink, shape: BoxShape.circle),
          markerSize: 4,
          markersMaxCount: 1,
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, _) {
            if (day.isAfter(DateTime.now())) return null;
            final complete = provider.isDayComplete(day);
            final partial = provider.isDayPartial(day);
            if (!complete && !partial) return null;
            return Container(
              width: 4, height: 4,
              decoration: BoxDecoration(
                color: complete ? C.ok : C.dim,
                shape: BoxShape.circle,
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Day breakdown ─────────────────────────────────────────────────────────────
class _DayBreakdown extends StatelessWidget {
  final DateTime day;
  final SportProvider provider;
  const _DayBreakdown({required this.day, required this.provider});

  @override
  Widget build(BuildContext context) {
    final log = provider.logForDate(day);
    final isToday = isSameDay(day, DateTime.now());
    final dateStr = isToday
        ? 'Aujourd\'hui'
        : DateFormat('EEEE d MMMM', 'fr_FR').format(day).capitalize();

    final hasData = log.totalReps > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(dateStr, style: T.h3(context)),
        const SizedBox(height: 10),
        if (!hasData)
          Text(
            provider.activeForDate(day).isEmpty
                ? 'Tous les exercices en repos'
                : 'Aucun entraînement enregistré',
            style: T.small(context),
          )
        else
          ...provider.exercises.map((ex) {
            final count = log.countFor(ex.id);
            if (count == 0) return const SizedBox.shrink();
            final done = count >= ex.dailyGoal;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Text(ex.emoji, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 10),
                Expanded(child: Text(ex.name, style: T.body(context))),
                Text('$count ${ex.unit}', style: T.mono(context)),
                const SizedBox(width: 8),
                Icon(
                  done ? Icons.check_rounded : Icons.remove_rounded,
                  size: 13,
                  color: done ? C.ok : C.muted,
                ),
              ]),
            );
          }),
      ],
    );
  }
}

// ── Trend chart ───────────────────────────────────────────────────────────────
class _TrendChart extends StatelessWidget {
  final SportProvider provider;
  const _TrendChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final spots = List.generate(14, (i) {
      final date = now.subtract(Duration(days: 13 - i));
      return FlSpot(i.toDouble(), provider.totalRepsForDate(date).toDouble());
    });

    final maxY = spots.map((s) => s.y).reduce(math.max);

    if (maxY == 0) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: C.elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.border, width: 0.5),
        ),
        child: Center(
            child: Text('Commence à t\'entraîner !', style: T.small(context))),
      );
    }

    return Container(
      height: 150,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
      decoration: BoxDecoration(
        color: C.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.border, width: 0.5),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            show: true,
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 6,
                getTitlesWidget: (value, _) {
                  final date =
                      now.subtract(Duration(days: 13 - value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('d/M').format(date),
                      style: T.label(context).copyWith(fontSize: 9),
                    ),
                  );
                },
              ),
            ),
          ),
          minX: 0,
          maxX: 13,
          minY: 0,
          maxY: maxY * 1.25,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: C.ink,
              barWidth: 1.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: spot.y > 0 ? 3 : 0,
                  color: C.ink,
                  strokeWidth: 0,
                  strokeColor: Colors.transparent,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: C.ink.withValues(alpha: 0.06),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏋️', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text('Aucun exercice', style: T.h3(context).copyWith(color: C.dim)),
          const SizedBox(height: 6),
          Text('Ajoute tes premiers exercices', style: T.small(context)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: C.border, width: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('+ Ajouter un exercice',
                  style: T.small(context).copyWith(color: C.ink)),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}
