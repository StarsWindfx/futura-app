import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/routine_model.dart';
import '../../providers/routine_provider.dart';
import '../../widgets/futura_tile.dart';

class AddRoutineSheet extends StatefulWidget {
  final RoutineModel? routine;
  const AddRoutineSheet({super.key, this.routine});

  @override
  State<AddRoutineSheet> createState() => _AddRoutineSheetState();
}

class _AddRoutineSheetState extends State<AddRoutineSheet> {
  late final TextEditingController _title;
  late final TextEditingController _desc;
  final TextEditingController _stepCtrl = TextEditingController();
  late TimeOfDay _time;
  TimeOfDay? _endTime;
  late Set<int> _days;
  late List<String> _steps;
  late bool _notif;
  late RecurringAlertType _alertType;
  late int _alertMinutes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final r = widget.routine;
    _title = TextEditingController(text: r?.title ?? '');
    _desc = TextEditingController(text: r?.description ?? '');
    _time = r != null ? TimeOfDay(hour: r.hour, minute: r.minute) : const TimeOfDay(hour: 7, minute: 0);
    _endTime = r?.endTimeMinutes != null ? TimeOfDay(hour: r!.endHour, minute: r.endMinute) : null;
    _days = Set.from(r?.days ?? [1, 2, 3, 4, 5]);
    _steps = List.from(r?.steps ?? []);
    _notif = r?.notificationsEnabled ?? true;
    _alertType = r?.alertType ?? RecurringAlertType.none;
    _alertMinutes = r?.alertIntervalMinutes ?? 60;
  }

  @override
  void dispose() { _title.dispose(); _desc.dispose(); _stepCtrl.dispose(); super.dispose(); }

  Future<void> _pickEndTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay(hour: (_time.hour + 12).clamp(0, 23), minute: 0),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: C.ink, onPrimary: C.bg, surface: C.sheet, onSurface: C.ink),
          dialogTheme: DialogThemeData(backgroundColor: C.sheet, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => _endTime = t);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: C.ink, onPrimary: C.bg, surface: C.sheet, onSurface: C.ink),
          dialogTheme: DialogThemeData(backgroundColor: C.sheet, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => _time = t);
  }

  void _addStep() {
    final txt = _stepCtrl.text.trim();
    if (txt.isEmpty) return;
    setState(() { _steps.add(txt); _stepCtrl.clear(); });
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final p = context.read<RoutineProvider>();
    if (widget.routine == null) {
      final endMins = _endTime != null ? _endTime!.hour * 60 + _endTime!.minute : null;
      await p.create(
        title: _title.text.trim(),
        description: _desc.text.trim(),
        steps: List.from(_steps),
        timeMinutes: _time.hour * 60 + _time.minute,
        endTimeMinutes: endMins,
        days: _days.toList()..sort(),
        notificationsEnabled: _notif,
        alertType: _alertType,
        alertIntervalMinutes: _alertMinutes,
      );
    } else {
      final endMins = _endTime != null ? _endTime!.hour * 60 + _endTime!.minute : null;
      await p.update(widget.routine!.copyWith(
        title: _title.text.trim(),
        description: _desc.text.trim(),
        steps: List.from(_steps),
        timeMinutes: _time.hour * 60 + _time.minute,
        endTimeMinutes: endMins,
        clearEndTime: _endTime == null,
        days: _days.toList()..sort(),
        notificationsEnabled: _notif,
        alertType: _alertType,
        alertIntervalMinutes: _alertMinutes,
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: const BoxDecoration(color: C.sheet, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const FHandle(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FInlineField(
                  label: 'Nom de la routine',
                  ctrl: _title,
                  autofocus: widget.routine == null,
                  style: T.h2(context),
                ),
                const SizedBox(height: 6),
                FInlineField(label: 'Description...', ctrl: _desc, maxLines: 2, style: T.small(context).copyWith(fontSize: 15, color: C.dim)),
                const SizedBox(height: 20),
                const Divider(color: C.line, thickness: 0.5),

                // Heure
                FRow(
                  onTap: _pickTime,
                  showDivider: true,
                  child: Row(children: [
                    Text('Heure', style: T.body(context)),
                    const Spacer(),
                    Text(
                      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                      style: T.monoLg(context),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right, color: C.muted, size: 14),
                  ]),
                ),

                // Notification
                FRow(
                  showDivider: true,
                  child: Row(children: [
                    Text('Notification', style: T.body(context)),
                    const Spacer(),
                    Switch(value: _notif, onChanged: (v) => setState(() => _notif = v)),
                  ]),
                ),

                // Jours
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('JOURS', style: T.label(context)),
                    const SizedBox(height: 12),
                    FDayPicker(
                      selected: _days,
                      onToggle: (d) => setState(() {
                        if (_days.contains(d)) { if (_days.length > 1) _days.remove(d); }
                        else _days.add(d);
                      }),
                    ),
                  ]),
                ),
                const Divider(color: C.line, thickness: 0.5),

                // ── Rappel récurrent ──────────────────────────────────
                FSectionLabel(text: 'RAPPEL RÉCURRENT'),
                _AlertTypePicker(current: _alertType, onChange: (t) => setState(() => _alertType = t)),
                if (_alertType == RecurringAlertType.interval) ...[
                  const SizedBox(height: 12),
                  _IntervalPicker(minutes: _alertMinutes, onChange: (v) => setState(() => _alertMinutes = v)),
                ],
                if (_alertType != RecurringAlertType.none && _alertType != RecurringAlertType.daily) ...[
                  const SizedBox(height: 12),
                  FRow(
                    onTap: _pickEndTime,
                    showDivider: false,
                    child: Row(children: [
                      Text('Heure de fin', style: T.body(context)),
                      const Spacer(),
                      if (_endTime != null) ...[
                        Text(
                          '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
                          style: T.monoLg(context),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _endTime = null),
                          child: const Icon(Icons.close, color: C.muted, size: 14),
                        ),
                      ] else
                        Text('Optionnel', style: T.small(context).copyWith(color: C.muted)),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, color: C.muted, size: 14),
                    ]),
                  ),
                ],
                const Divider(color: C.line, thickness: 0.5),

                // ── Étapes ───────────────────────────────────────────
                FSectionLabel(text: 'ÉTAPES'),
                ..._steps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Text('${e.key + 1}', style: T.mono(context).copyWith(color: C.muted, fontSize: 11)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(e.value, style: T.body(context))),
                    GestureDetector(
                      onTap: () => setState(() => _steps.removeAt(e.key)),
                      child: const Icon(Icons.close, color: C.muted, size: 16),
                    ),
                  ]),
                )),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _stepCtrl,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addStep(),
                      style: GoogleFonts.inter(color: C.ink, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Ajouter une étape...',
                        hintStyle: GoogleFonts.inter(color: C.muted, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _addStep,
                    child: Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(color: C.ink, shape: BoxShape.circle),
                      child: const Icon(Icons.add_rounded, color: C.bg, size: 16),
                    ),
                  ),
                ]),
                const SizedBox(height: 28),
                FBtn(
                  label: _loading ? '...' : (widget.routine == null ? 'Créer la routine' : 'Enregistrer'),
                  onTap: _loading ? () {} : _submit,
                ),
                if (widget.routine != null) ...[
                  const SizedBox(height: 10),
                  FBtn(
                    label: 'Supprimer la routine',
                    filled: false,
                    onTap: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: C.sheet,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Text('Supprimer ?', style: T.h3(context)),
                          content: Text(
                            'La routine "${widget.routine!.title}" sera supprimée définitivement.',
                            style: T.small(context),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text('Annuler', style: T.small(context)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text('Supprimer', style: T.small(context).copyWith(color: C.err, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && mounted) {
                        await context.read<RoutineProvider>().remove(widget.routine!.id);
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

class _AlertTypePicker extends StatelessWidget {
  final RecurringAlertType current;
  final ValueChanged<RecurringAlertType> onChange;
  const _AlertTypePicker({required this.current, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final items = [
      (RecurringAlertType.none, 'Aucun'),
      (RecurringAlertType.interval, 'Intervalle'),
      (RecurringAlertType.hourly, 'Toutes les heures'),
      (RecurringAlertType.daily, 'Quotidien'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final (type, label) = item;
        final on = current == type;
        return GestureDetector(
          onTap: () => onChange(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: on ? C.ink : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: on ? C.ink : C.border, width: 0.5),
            ),
            child: Text(label, style: TextStyle(fontSize: 13, fontWeight: on ? FontWeight.w600 : FontWeight.w400, color: on ? C.bg : C.dim, fontFamily: 'Inter')),
          ),
        );
      }).toList(),
    );
  }
}

class _IntervalPicker extends StatelessWidget {
  final int minutes;
  final ValueChanged<int> onChange;
  const _IntervalPicker({required this.minutes, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final presets = [(15, '15min'), (30, '30min'), (60, '1h'), (120, '2h'), (240, '4h')];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Intervalle', style: T.small(context)),
      const SizedBox(height: 8),
      Row(children: presets.map((p) {
        final (min, label) = p;
        final on = minutes == min;
        return GestureDetector(
          onTap: () => onChange(min),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: on ? C.ink : C.elevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: on ? C.ink : C.border, width: 0.5),
            ),
            child: Text(label, style: TextStyle(fontSize: 12, fontWeight: on ? FontWeight.w600 : FontWeight.w400, color: on ? C.bg : C.dim, fontFamily: 'JetBrainsMono')),
          ),
        );
      }).toList()),
    ]);
  }
}
