import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../widgets/futura_tile.dart';
import 'add_task_sheet.dart';

enum _F { all, today, high, done }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  _F _filter = _F.all;

  List<TaskModel> _get(TaskProvider p) {
    switch (_filter) {
      case _F.all:
        return [...p.pending, ...p.completed];
      case _F.today:
        final t = p.today;
        return [...t.where((t) => !t.isCompleted), ...t.where((t) => t.isCompleted)];
      case _F.high: return p.highPriority;
      case _F.done: return p.completed;
    }
  }

  void _add([TaskModel? t]) => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => AddTaskSheet(task: t),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Consumer<TaskProvider>(builder: (_, p, __) {
        final tasks = _get(p);
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
                        Text('Tâches', style: T.h1(context)),
                        const SizedBox(height: 4),
                        Text(
                          '${p.pending.length} en attente · ${p.completed.length} terminées',
                          style: T.small(context),
                        ),
                      ]),
                    ),
                    GestureDetector(
                      onTap: () => _add(),
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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
              sliver: SliverToBoxAdapter(child: _Filters(current: _filter, onChange: (f) => setState(() => _filter = f))),
            ),
            if (tasks.isEmpty)
              SliverFillRemaining(
                child: _Empty(filter: _filter, onAdd: () => _add()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 120),
                sliver: SliverList.builder(
                  itemCount: tasks.length,
                  itemBuilder: (_, i) => _TaskRow(
                    task: tasks[i],
                    index: i,
                    onEdit: () => _add(tasks[i]),
                    onDelete: () => p.remove(tasks[i].id),
                    onToggle: () => p.toggleComplete(tasks[i].id),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _Filters extends StatelessWidget {
  final _F current;
  final ValueChanged<_F> onChange;
  const _Filters({required this.current, required this.onChange});

  @override
  Widget build(BuildContext context) {
    const items = [(_F.all, 'Toutes'), (_F.today, "Aujourd'hui"), (_F.high, 'Priorité'), (_F.done, '✓ Terminées')];
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final (f, label) = items[i];
          final on = current == f;
          return GestureDetector(
            onTap: () => onChange(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: on ? C.ink : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: on ? C.ink : C.border, width: 0.5),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, fontWeight: on ? FontWeight.w600 : FontWeight.w400, color: on ? C.bg : C.dim, fontFamily: 'Inter'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final TaskModel task;
  final int index;
  final VoidCallback onEdit, onDelete, onToggle;
  const _TaskRow({required this.task, required this.index, required this.onEdit, required this.onDelete, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.4,
        children: [
          SlidableAction(onPressed: (_) => onEdit(), backgroundColor: Colors.transparent, foregroundColor: C.dim, icon: Icons.edit_outlined, padding: EdgeInsets.zero),
          SlidableAction(onPressed: (_) => onDelete(), backgroundColor: Colors.transparent, foregroundColor: C.err, icon: Icons.delete_outline, padding: EdgeInsets.zero),
        ],
      ),
      child: GestureDetector(
        onTap: onEdit,
        behavior: HitTestBehavior.opaque,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: FCheck(checked: task.isCompleted, onToggle: onToggle),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    task.title,
                    style: T.body(context).copyWith(
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      color: task.isCompleted ? C.muted : C.ink,
                    ),
                  ),
                  if (task.dueDate != null || task.category.isNotEmpty || task.subtaskCount > 0) ...[
                    const SizedBox(height: 3),
                    Row(children: [
                      if (task.subtaskCount > 0) ...[
                        Text(
                          '${task.subtaskDoneCount}/${task.subtaskCount}',
                          style: T.mono(context).copyWith(fontSize: 11, color: task.subtaskDoneCount == task.subtaskCount ? C.ok : C.muted),
                        ),
                        if (task.dueDate != null || task.category.isNotEmpty) Text('  ·  ', style: T.small(context).copyWith(color: C.line)),
                      ],
                      if (task.dueDate != null) ...[
                        Text(
                          DateFormat('d MMM', 'fr_FR').format(task.dueDate!),
                          style: T.mono(context).copyWith(fontSize: 11, color: _isOverdue(task) ? C.err : C.muted),
                        ),
                        if (task.category.isNotEmpty) Text('  ·  ', style: T.small(context)),
                      ],
                      if (task.category.isNotEmpty)
                        Text(task.category, style: T.small(context).copyWith(fontSize: 12)),
                    ]),
                  ],
                ]),
              ),
              if (task.priority > 0) ...[
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: FPrioDot(priority: task.priority),
                ),
              ],
            ]),
          ),
          const Divider(height: 0, thickness: 0.5, color: C.line),
        ]),
      ),
    ).animate(delay: Duration(milliseconds: index * 25)).fadeIn();
  }

  bool _isOverdue(TaskModel t) => t.dueDate != null && !t.isCompleted && t.dueDate!.isBefore(DateTime.now());
}

class _Empty extends StatelessWidget {
  final _F filter;
  final VoidCallback onAdd;
  const _Empty({required this.filter, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(filter == _F.done ? '—' : '○', style: TextStyle(fontSize: 32, color: C.muted, fontFamily: 'JetBrainsMono')),
        const SizedBox(height: 14),
        Text(filter == _F.done ? 'Aucune tâche terminée' : 'Liste vide', style: T.h3(context).copyWith(color: C.dim)),
        if (filter != _F.done) ...[
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(border: Border.all(color: C.border, width: 0.5), borderRadius: BorderRadius.circular(20)),
              child: Text('+ Nouvelle tâche', style: T.small(context).copyWith(color: C.ink)),
            ),
          ),
        ],
      ]).animate().fadeIn(duration: 300.ms),
    );
  }
}
