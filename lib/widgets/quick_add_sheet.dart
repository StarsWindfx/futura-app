import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/task_provider.dart';
import '../providers/reminder_provider.dart';
import 'futura_tile.dart';

class QuickAddSheet extends StatefulWidget {
  const QuickAddSheet({super.key});

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final _ctrl = TextEditingController();
  bool _isReminder = false;
  int _priority = 0;
  bool _loading = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty) return;
    setState(() => _loading = true);
    if (_isReminder) {
      await context.read<ReminderProvider>().create(
        title: txt,
        dateTime: DateTime.now().add(const Duration(hours: 1)),
      );
    } else {
      await context.read<TaskProvider>().create(title: txt, priority: _priority);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: C.sheet, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const FHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Type toggle
              Row(children: [
                _TypeBtn(label: 'Tâche', icon: Icons.check_box_outline_blank_rounded, selected: !_isReminder, onTap: () => setState(() => _isReminder = false)),
                const SizedBox(width: 8),
                _TypeBtn(label: 'Rappel', icon: Icons.notifications_outlined, selected: _isReminder, onTap: () => setState(() => _isReminder = true)),
              ]),
              const SizedBox(height: 16),
              FInlineField(
                label: _isReminder ? 'Titre du rappel...' : 'Titre de la tâche...',
                ctrl: _ctrl,
                autofocus: true,
                style: T.h2(context),
              ),
              if (!_isReminder) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Text('Priorité', style: T.small(context).copyWith(color: C.muted)),
                  const SizedBox(width: 14),
                  ...List.generate(3, (i) {
                    final labels = ['—', '!', '!!'];
                    final colors = [C.muted, C.warn, C.err];
                    final on = _priority == i;
                    return GestureDetector(
                      onTap: () => setState(() => _priority = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        margin: const EdgeInsets.only(right: 6),
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: on ? colors[i].withValues(alpha: 0.15) : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: on ? colors[i] : C.border, width: on ? 1 : 0.5),
                        ),
                        child: Center(child: Text(labels[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: on ? colors[i] : C.muted, fontFamily: 'Inter'))),
                      ),
                    );
                  }),
                ]),
              ] else ...[
                const SizedBox(height: 8),
                Text('Rappel dans 1 heure', style: T.small(context).copyWith(color: C.muted)),
              ],
              const SizedBox(height: 20),
              FBtn(
                label: _loading ? '...' : (_isReminder ? 'Créer le rappel' : 'Créer la tâche'),
                onTap: _loading ? () {} : _submit,
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeBtn({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? C.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? C.ink : C.border, width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: selected ? C.bg : C.dim),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? C.bg : C.dim, fontFamily: 'Inter')),
        ]),
      ),
    );
  }
}
