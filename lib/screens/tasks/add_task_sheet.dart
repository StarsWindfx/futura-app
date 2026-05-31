import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../widgets/futura_tile.dart';

class AddTaskSheet extends StatefulWidget {
  final TaskModel? task;
  const AddTaskSheet({super.key, this.task});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late final TextEditingController _cat;
  final TextEditingController _subCtrl = TextEditingController();
  int _priority = 0;
  DateTime? _due;
  late List<String> _subtasks;
  late List<bool> _subtasksDone;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.task?.title ?? '');
    _desc = TextEditingController(text: widget.task?.description ?? '');
    _cat = TextEditingController(text: widget.task?.category ?? '');
    _priority = widget.task?.priority ?? 0;
    _due = widget.task?.dueDate;
    _subtasks = List.from(widget.task?.subtasks ?? []);
    _subtasksDone = List.from(widget.task?.subtasksDone ?? []);
  }

  @override
  void dispose() { _title.dispose(); _desc.dispose(); _cat.dispose(); _subCtrl.dispose(); super.dispose(); }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _due ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: _darkPicker,
    );
    if (d != null) setState(() => _due = d);
  }

  Widget _darkPicker(BuildContext ctx, Widget? child) => Theme(
    data: ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(primary: C.ink, onPrimary: C.bg, surface: C.sheet, onSurface: C.ink),
      dialogTheme: DialogThemeData(backgroundColor: C.sheet, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    ),
    child: child!,
  );

  void _addSubtask() {
    final txt = _subCtrl.text.trim();
    if (txt.isEmpty) return;
    setState(() { _subtasks.add(txt); _subtasksDone.add(false); _subCtrl.clear(); });
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) return;
    final p = context.read<TaskProvider>();
    if (widget.task == null) {
      await p.create(
        title: _title.text.trim(),
        description: _desc.text.trim(),
        priority: _priority,
        dueDate: _due,
        category: _cat.text.trim(),
        subtasks: List.from(_subtasks),
        subtasksDone: List.from(_subtasksDone),
      );
    } else {
      await p.update(widget.task!.copyWith(
        title: _title.text.trim(),
        description: _desc.text.trim(),
        priority: _priority,
        dueDate: _due,
        category: _cat.text.trim(),
        clearDueDate: _due == null,
        subtasks: List.from(_subtasks),
        subtasksDone: List.from(_subtasksDone),
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        decoration: const BoxDecoration(color: C.sheet, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const FHandle(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FInlineField(
                  label: 'Titre de la tâche',
                  ctrl: _title,
                  autofocus: widget.task == null,
                  style: T.h2(context),
                ),
                const SizedBox(height: 8),
                FInlineField(
                  label: 'Notes...',
                  ctrl: _desc,
                  maxLines: 3,
                  style: T.small(context).copyWith(color: C.dim, fontSize: 15),
                ),
                const SizedBox(height: 20),
                const Divider(color: C.line, thickness: 0.5),

                FRow(
                  showDivider: true,
                  child: Row(children: [
                    Text('Priorité', style: T.body(context)),
                    const Spacer(),
                    _PrioSelector(current: _priority, onChange: (v) => setState(() => _priority = v)),
                  ]),
                ),

                FRow(
                  onTap: _pickDate,
                  showDivider: true,
                  child: Row(children: [
                    Text('Échéance', style: T.body(context)),
                    const Spacer(),
                    if (_due != null) ...[
                      Text(DateFormat('d MMM yyyy', 'fr_FR').format(_due!), style: T.mono(context)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _due = null),
                        child: const Icon(Icons.close, color: C.muted, size: 14),
                      ),
                    ] else
                      Text('Choisir', style: T.small(context).copyWith(color: C.muted)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: C.muted, size: 14),
                  ]),
                ),

                FRow(
                  showDivider: false,
                  child: Row(children: [
                    Text('Catégorie', style: T.body(context)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _cat,
                        textAlign: TextAlign.end,
                        style: T.mono(context),
                        decoration: InputDecoration(
                          hintText: 'Travail, Perso...',
                          hintStyle: T.small(context).copyWith(color: C.muted),
                          filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 8),
                const Divider(color: C.line, thickness: 0.5),

                // Sous-tâches
                FSectionLabel(text: 'SOUS-TÂCHES'),
                ..._subtasks.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => setState(() => _subtasksDone[e.key] = !_subtasksDone[e.key]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _subtasksDone[e.key] ? C.ink : Colors.transparent,
                          border: Border.all(color: _subtasksDone[e.key] ? C.ink : C.muted, width: 1),
                        ),
                        child: _subtasksDone[e.key]
                            ? const Icon(Icons.check, color: C.bg, size: 10)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.value,
                        style: T.body(context).copyWith(
                          color: _subtasksDone[e.key] ? C.muted : C.ink,
                          decoration: _subtasksDone[e.key] ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() { _subtasks.removeAt(e.key); _subtasksDone.removeAt(e.key); }),
                      child: const Icon(Icons.close, color: C.muted, size: 16),
                    ),
                  ]),
                )),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _subCtrl,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addSubtask(),
                      style: GoogleFonts.inter(color: C.ink, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Ajouter une sous-tâche...',
                        hintStyle: GoogleFonts.inter(color: C.muted, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _addSubtask,
                    child: Container(
                      width: 28, height: 28,
                      decoration: const BoxDecoration(color: C.ink, shape: BoxShape.circle),
                      child: const Icon(Icons.add_rounded, color: C.bg, size: 14),
                    ),
                  ),
                ]),

                const SizedBox(height: 24),
                FBtn(
                  label: widget.task == null ? 'Créer' : 'Enregistrer',
                  onTap: _submit,
                ),
                if (widget.task != null) ...[
                  const SizedBox(height: 10),
                  FBtn(
                    label: 'Supprimer la tâche',
                    filled: false,
                    onTap: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: C.sheet,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Text('Supprimer ?', style: T.h3(context)),
                          content: Text('La tâche "${widget.task!.title}" sera supprimée.', style: T.small(context)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Annuler', style: T.small(context))),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Supprimer', style: T.small(context).copyWith(color: C.err, fontWeight: FontWeight.w700))),
                          ],
                        ),
                      );
                      if (ok == true && mounted) {
                        await context.read<TaskProvider>().remove(widget.task!.id);
                        if (mounted) Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _PrioSelector extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChange;
  const _PrioSelector({required this.current, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final labels = ['—', '!', '!!'];
    final colors = [C.muted, C.warn, C.err];
    return Row(children: List.generate(3, (i) {
      final on = current == i;
      return GestureDetector(
        onTap: () => onChange(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.only(left: 6),
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: on ? colors[i].withValues(alpha: 0.15) : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: on ? colors[i] : C.border, width: on ? 1 : 0.5),
          ),
          child: Center(child: Text(labels[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: on ? colors[i] : C.muted, fontFamily: 'Inter'))),
        ),
      );
    }));
  }
}
