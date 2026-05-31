import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/event_provider.dart';
import '../../widgets/futura_tile.dart';

class AddEventSheet extends StatefulWidget {
  final DateTime? initialDate;
  const AddEventSheet({super.key, this.initialDate});

  @override
  State<AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<AddEventSheet> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  late DateTime _start, _end;
  bool _allDay = false;
  int _colorIdx = 0;
  bool _loading = false;

  static const _colors = [C.ink, C.blue, C.ok, C.warn, C.err];

  @override
  void initState() {
    super.initState();
    final base = widget.initialDate ?? DateTime.now();
    final h = TimeOfDay.now().hour + 1;
    _start = DateTime(base.year, base.month, base.day, h, 0);
    _end = _start.add(const Duration(hours: 1));
  }

  @override
  void dispose() { _title.dispose(); _desc.dispose(); super.dispose(); }

  Widget _dark(BuildContext ctx, Widget? child) => Theme(
    data: ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(primary: C.ink, onPrimary: C.bg, surface: C.sheet, onSurface: C.ink),
      dialogTheme: DialogThemeData(backgroundColor: C.sheet, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    ),
    child: child!,
  );

  Future<DateTime?> _pickDT(DateTime init) async {
    final d = await showDatePicker(context: context, initialDate: init, firstDate: DateTime(2020), lastDate: DateTime(2030), builder: _dark);
    if (d == null || !mounted) return null;
    if (_allDay) return DateTime(d.year, d.month, d.day);
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(init), builder: _dark);
    if (t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _loading = true);
    await context.read<EventProvider>().create(
      title: _title.text.trim(), description: _desc.text.trim(),
      startDate: _start, endDate: _end, isAllDay: _allDay, colorIndex: _colorIdx,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = _allDay ? DateFormat('EEE d MMM', 'fr_FR') : DateFormat('EEE d MMM · HH:mm', 'fr_FR');
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: C.sheet, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const FHandle(),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FInlineField(label: 'Titre', ctrl: _title, autofocus: true, style: T.h2(context)),
              const SizedBox(height: 6),
              FInlineField(label: 'Description...', ctrl: _desc, maxLines: 2, style: T.small(context).copyWith(fontSize: 15, color: C.dim)),
              const SizedBox(height: 20),
              const Divider(color: C.line, thickness: 0.5),

              FRow(
                showDivider: true,
                child: Row(children: [
                  Text('Journée entière', style: T.body(context)),
                  const Spacer(),
                  Switch(value: _allDay, onChanged: (v) => setState(() => _allDay = v)),
                ]),
              ),

              FRow(
                onTap: () async { final dt = await _pickDT(_start); if (dt != null) setState(() { _start = dt; if (_end.isBefore(_start)) _end = _start.add(const Duration(hours: 1)); }); },
                showDivider: true,
                child: Row(children: [
                  Text('Début', style: T.body(context)),
                  const Spacer(),
                  Text(fmt.format(_start), style: T.mono(context)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: C.muted, size: 14),
                ]),
              ),

              FRow(
                onTap: () async { final dt = await _pickDT(_end); if (dt != null && !dt.isBefore(_start)) setState(() => _end = dt); },
                showDivider: true,
                child: Row(children: [
                  Text('Fin', style: T.body(context)),
                  const Spacer(),
                  Text(fmt.format(_end), style: T.mono(context)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: C.muted, size: 14),
                ]),
              ),

              // Couleur
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(children: List.generate(_colors.length, (i) {
                  final on = _colorIdx == i;
                  return GestureDetector(
                    onTap: () => setState(() => _colorIdx = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 28, height: 28,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: _colors[i],
                        shape: BoxShape.circle,
                        border: on ? Border.all(color: C.dim, width: 3) : null,
                      ),
                    ),
                  );
                })),
              ),
              const Divider(color: C.line, thickness: 0.5),
              const SizedBox(height: 20),
              FBtn(label: _loading ? '...' : 'Créer l\'événement', onTap: _loading ? () {} : _submit),
            ]),
          ),
        ]),
      ),
    );
  }
}
