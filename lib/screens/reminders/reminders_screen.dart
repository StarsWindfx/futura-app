import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/reminder_model.dart';
import '../../providers/reminder_provider.dart';
import '../../widgets/futura_tile.dart';
import 'add_reminder_sheet.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  void _add(BuildContext ctx) => showModalBottomSheet(
    context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => const AddReminderSheet(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Consumer<ReminderProvider>(builder: (ctx, p, _) {
        final upcoming = p.upcoming;
        final past = p.past;
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverSafeArea(
              bottom: false,
              sliver: SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Rappels', style: T.h1(context)),
                        const SizedBox(height: 4),
                        Text('${upcoming.length} à venir', style: T.small(context)),
                      ]),
                    ),
                    GestureDetector(
                      onTap: () => _add(context),
                      child: Container(
                        width: 32, height: 32,
                        decoration: const BoxDecoration(color: C.ink, shape: BoxShape.circle),
                        child: const Icon(Icons.add_rounded, color: C.bg, size: 18),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            if (upcoming.isEmpty && past.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('◌', style: TextStyle(fontSize: 40, color: C.muted, fontFamily: 'JetBrainsMono')),
                    const SizedBox(height: 14),
                    Text('Aucun rappel', style: T.h3(context).copyWith(color: C.dim)),
                  ]).animate().fadeIn(),
                ),
              )
            else ...[
              if (upcoming.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('À VENIR', style: T.label(context)),
                      const SizedBox(height: 12),
                      ...upcoming.asMap().entries.map((e) => _ReminderRow(
                        reminder: e.value, index: e.key,
                        onToggle: () => p.toggleComplete(e.value.id),
                        onDelete: () => p.remove(e.value.id),
                      )),
                    ]),
                  ),
                ),
              if (past.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 120),
                  sliver: SliverToBoxAdapter(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('PASSÉS', style: T.label(context)),
                      const SizedBox(height: 12),
                      ...past.take(10).toList().asMap().entries.map((e) => Opacity(
                        opacity: 0.4,
                        child: _ReminderRow(
                          reminder: e.value, index: e.key,
                          onToggle: () => p.toggleComplete(e.value.id),
                          onDelete: () => p.remove(e.value.id),
                        ),
                      )),
                    ]),
                  ),
                ),
            ],
          ],
        );
      }),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final ReminderModel reminder;
  final int index;
  final VoidCallback onToggle, onDelete;
  const _ReminderRow({required this.reminder, required this.index, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [SlidableAction(onPressed: (_) => onDelete(), backgroundColor: Colors.transparent, foregroundColor: C.err, icon: Icons.delete_outline, padding: EdgeInsets.zero)],
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onToggle,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: FCheck(checked: reminder.isCompleted, onToggle: onToggle, color: C.blue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    reminder.title,
                    style: T.body(context).copyWith(
                      decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                      color: reminder.isCompleted ? C.muted : C.ink,
                    ),
                  ),
                  if (reminder.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(reminder.note, style: T.small(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(
                      DateFormat('EEE d MMM · HH:mm', 'fr_FR').format(reminder.dateTime),
                      style: T.mono(context).copyWith(fontSize: 11),
                    ),
                    if (reminder.isRecurring) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.repeat, color: C.muted, size: 11),
                      const SizedBox(width: 3),
                      Text(reminder.recurringLabel, style: T.small(context).copyWith(fontSize: 11)),
                    ],
                  ]),
                ]),
              ),
            ]),
          ),
          const Divider(height: 0, thickness: 0.5, color: C.line),
        ]),
      ),
    ).animate(delay: Duration(milliseconds: index * 30)).fadeIn();
  }
}
