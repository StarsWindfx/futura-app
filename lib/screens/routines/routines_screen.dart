import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/routine_model.dart';
import '../../providers/routine_provider.dart';
import '../../widgets/futura_tile.dart';
import 'add_routine_sheet.dart';

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key});

  void _add(BuildContext ctx, [RoutineModel? r]) => showModalBottomSheet(
    context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => AddRoutineSheet(routine: r),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Consumer<RoutineProvider>(builder: (ctx, p, _) {
        final routines = p.all;
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
                        Text('Routines', style: T.h1(context)),
                        const SizedBox(height: 4),
                        Text('${p.active.length} actives', style: T.small(context)),
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
            if (routines.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('∞', style: TextStyle(fontSize: 40, color: C.muted, fontFamily: 'JetBrainsMono')),
                    const SizedBox(height: 14),
                    Text('Aucune routine', style: T.h3(context).copyWith(color: C.dim)),
                  ]).animate().fadeIn(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 120),
                sliver: SliverList.builder(
                  itemCount: routines.length,
                  itemBuilder: (_, i) => _RoutineRow(
                    routine: routines[i],
                    index: i,
                    onToggle: () => p.toggleActive(routines[i].id),
                    onEdit: () => _add(context, routines[i]),
                    onDelete: () => p.remove(routines[i].id),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _RoutineRow extends StatelessWidget {
  final RoutineModel routine;
  final int index;
  final VoidCallback onToggle, onEdit, onDelete;
  const _RoutineRow({required this.routine, required this.index, required this.onToggle, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.45,
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
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      routine.title,
                      style: T.h3(context).copyWith(color: routine.isActive ? C.ink : C.muted),
                    ),
                    const SizedBox(height: 5),
                    Row(children: [
                      Text(routine.timeLabel, style: T.monoLg(context).copyWith(fontSize: 13, color: routine.isActive ? C.dim : C.muted)),
                      const SizedBox(width: 10),
                      Container(width: 1, height: 10, color: C.line),
                      const SizedBox(width: 10),
                      Text(routine.daysLabel, style: T.small(context).copyWith(color: routine.isActive ? C.dim : C.muted)),
                      if (routine.steps.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Container(width: 1, height: 10, color: C.line),
                        const SizedBox(width: 10),
                        Text('${routine.steps.length} étapes', style: T.small(context)),
                      ],
                    ]),
                    if (routine.alertType != RecurringAlertType.none) ...[
                      const SizedBox(height: 5),
                      Row(children: [
                        const Icon(Icons.timer_outlined, size: 11, color: C.muted),
                        const SizedBox(width: 4),
                        Text(routine.alertLabel, style: T.small(context).copyWith(fontSize: 11, color: C.muted)),
                      ]),
                    ],
                  ]),
                ),
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 44, height: 26,
                    decoration: BoxDecoration(
                      color: routine.isActive ? C.ink : C.elevated,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Align(
                      alignment: routine.isActive ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 20, height: 20,
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: routine.isActive ? C.bg : C.muted,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
              if (routine.isActive && routine.steps.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: routine.steps.take(4).toList().asMap().entries.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: C.elevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: C.border, width: 0.5),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('${e.key + 1}', style: T.small(context).copyWith(color: C.muted, fontSize: 10, fontFamily: 'JetBrainsMono')),
                        const SizedBox(width: 5),
                        Text(e.value, style: T.small(context).copyWith(fontSize: 12)),
                      ]),
                    );
                  }).toList(),
                ),
                if (routine.steps.length > 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('+${routine.steps.length - 4} étapes', style: T.small(context).copyWith(color: C.muted, fontSize: 11)),
                  ),
              ],
            ]),
          ),
          const Divider(height: 0, thickness: 0.5, color: C.line),
        ]),
      ),
    ).animate(delay: Duration(milliseconds: index * 30)).fadeIn();
  }
}
