import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/reminder_provider.dart';
import '../../widgets/futura_tile.dart';

class AddReminderSheet extends StatefulWidget {
  const AddReminderSheet({super.key});

  @override
  State<AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<AddReminderSheet> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  DateTime _dt = DateTime.now().add(const Duration(hours: 1));
  bool _recurring = false;
  final Set<int> _days = {};
  bool _loading = false;

  @override
  void dispose() { _title.dispose(); _note.dispose(); super.dispose(); }

  Widget _dark(BuildContext ctx, Widget? child) => Theme(
    data: ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(primary: C.ink, onPrimary: C.bg, surface: C.sheet, onSurface: C.ink),
      dialogTheme: DialogThemeData(backgroundColor: C.sheet, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    ),
    child: child!,
  );

  Future<void> _pick() async {
    final d = await showDatePicker(context: context, initialDate: _dt, firstDate: DateTime.now(), lastDate: DateTime(2030), builder: _dark);
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dt), builder: _dark);
    if (t == null) return;
    setState(() => _dt = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _loading = true);
    await context.read<ReminderProvider>().create(
      title: _title.text.trim(),
      note: _note.text.trim(),
      dateTime: _dt,
      isRecurring: _recurring,
      recurringDays: _days.toList()..sort(),
    );
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
              FInlineField(label: 'Titre du rappel', ctrl: _title, autofocus: true, style: T.h2(context)),
              const SizedBox(height: 6),
              FInlineField(label: 'Notes...', ctrl: _note, maxLines: 2, style: T.small(context).copyWith(fontSize: 15, color: C.dim)),
              const SizedBox(height: 20),
              const Divider(color: C.line, thickness: 0.5),

              // Date & heure
              FRow(
                onTap: _pick,
                showDivider: true,
                child: Row(children: [
                  Text('Date & heure', style: T.body(context)),
                  const Spacer(),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(DateFormat('EEE d MMM', 'fr_FR').format(_dt), style: T.small(context)),
                    Text(DateFormat('HH:mm').format(_dt), style: T.monoLg(context).copyWith(fontSize: 18)),
                  ]),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, color: C.muted, size: 14),
                ]),
              ),

              // Récurrent
              FRow(
                showDivider: _recurring,
                child: Row(children: [
                  Text('Répéter', style: T.body(context)),
                  const Spacer(),
                  Switch(value: _recurring, onChanged: (v) => setState(() => _recurring = v)),
                ]),
              ),

              if (_recurring) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 6),
                  child: FDayPicker(
                    selected: _days,
                    onToggle: (d) => setState(() { if (_days.contains(d)) _days.remove(d); else _days.add(d); }),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(color: C.line, thickness: 0.5),
              ],

              const SizedBox(height: 20),
              FBtn(label: _loading ? '...' : 'Créer le rappel', onTap: _loading ? () {} : _submit),
            ]),
          ),
        ]),
      ),
    );
  }
}
