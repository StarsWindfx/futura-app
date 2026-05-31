import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../models/sport_model.dart';
import '../../providers/sport_provider.dart';

class AddExerciseSheet extends StatefulWidget {
  final SportExercise? exercise;
  const AddExerciseSheet({super.key, this.exercise});

  @override
  State<AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<AddExerciseSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emojiCtrl;
  late final TextEditingController _goalCtrl;
  late String _unit;
  late List<int> _restDays; // DateTime.weekday: 1=Lun…7=Dim

  static const _presets = [
    ('💪', 'Pompes', 'reps', 40),
    ('🏋️', 'Squats', 'reps', 50),
    ('🔥', 'Abdos', 'reps', 40),
    ('⚡', 'Burpees', 'reps', 15),
    ('⏱️', 'Planche', 'sec', 60),
    ('🚶', 'Fentes', 'reps', 30),
    ('🤲', 'Dips', 'reps', 25),
    ('🏔️', 'Mountain Climbers', 'reps', 40),
    ('🔄', 'Jumping Jacks', 'reps', 50),
    ('🧘', 'Gainage latéral', 'sec', 45),
    ('🦵', 'Pistol Squats', 'reps', 20),
    ('🤸', 'Pompes diamant', 'reps', 20),
  ];

  // Libellés jours courts (index 0 = Lun = weekday 1)
  static const _dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    final ex = widget.exercise;
    _nameCtrl = TextEditingController(text: ex?.name ?? '');
    _emojiCtrl = TextEditingController(text: ex?.emoji ?? '');
    _goalCtrl =
        TextEditingController(text: ex != null ? ex.dailyGoal.toString() : '');
    _unit = ex?.unit ?? 'reps';
    _restDays = List<int>.from(ex?.restDays ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emojiCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  void _pickPreset(String emoji, String name, String unit, int goal) {
    setState(() {
      _emojiCtrl.text = emoji;
      _nameCtrl.text = name;
      _unit = unit;
      _goalCtrl.text = goal.toString();
    });
  }

  void _toggleRestDay(int weekday) {
    setState(() {
      if (_restDays.contains(weekday)) {
        _restDays.remove(weekday);
      } else {
        _restDays.add(weekday);
      }
    });
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final goal = int.tryParse(_goalCtrl.text.trim()) ?? 10;
    final emoji =
        _emojiCtrl.text.trim().isEmpty ? '💪' : _emojiCtrl.text.trim();

    final p = context.read<SportProvider>();
    if (widget.exercise != null) {
      p.updateExercise(widget.exercise!.copyWith(
        name: name,
        emoji: emoji,
        unit: _unit,
        dailyGoal: goal,
        restDays: List<int>.from(_restDays),
      ));
    } else {
      p.addExercise(SportExercise(
        id: const Uuid().v4(),
        name: name,
        emoji: emoji,
        unit: _unit,
        dailyGoal: goal,
        restDays: List<int>.from(_restDays),
      ));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.exercise != null;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: C.sheet,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                        color: C.muted,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(isEdit ? 'Modifier' : 'Nouvel exercice',
                    style: T.h2(context)),
                const SizedBox(height: 20),

                // ── Presets ──────────────────────────────────────────
                if (!isEdit) ...[
                  Text('RACCOURCIS', style: T.label(context)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemCount: _presets.length,
                      itemBuilder: (_, i) {
                        final (emoji, name, unit, goal) = _presets[i];
                        return GestureDetector(
                          onTap: () => _pickPreset(emoji, name, unit, goal),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: C.border, width: 0.5),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Text('$emoji $name',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: C.dim,
                                      fontFamily: 'Inter')),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Emoji + Name ──────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: C.elevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: C.border, width: 0.5),
                      ),
                      child: Center(
                        child: TextField(
                          controller: _emojiCtrl,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '💪',
                            contentPadding: EdgeInsets.zero,
                            filled: false,
                          ),
                          maxLength: 8,
                          buildCounter: (_, {required currentLength,
                              required isFocused,
                              maxLength}) =>
                              null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _nameCtrl,
                        autofocus: !isEdit,
                        style: T.body(context),
                        decoration: const InputDecoration(
                            hintText: 'Nom de l\'exercice'),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Objectif + Unité ──────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _goalCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: T.body(context),
                        decoration: const InputDecoration(
                            hintText: 'Objectif journalier'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: C.elevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: C.border, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          for (final u in ['reps', 'sec', 'min'])
                            GestureDetector(
                              onTap: () => setState(() => _unit = u),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 13, vertical: 13),
                                decoration: BoxDecoration(
                                  color: _unit == u
                                      ? C.ink
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  u,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _unit == u ? C.bg : C.dim,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Jours de repos ────────────────────────────────────
                Text('JOURS DE REPOS', style: T.label(context)),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(7, (i) {
                    final weekday = i + 1; // 1=Lun … 7=Dim
                    final isRest = _restDays.contains(weekday);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _toggleRestDay(weekday),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 36,
                          decoration: BoxDecoration(
                            color: isRest ? C.ink : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: isRest ? C.ink : C.border, width: 0.5),
                          ),
                          child: Center(
                            child: Text(
                              _dayLabels[i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isRest ? C.bg : C.dim,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // ── Bouton sauvegarder ────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: _save,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                          color: C.ink,
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: Text(
                          isEdit ? 'Mettre à jour' : 'Ajouter',
                          style: T.body(context).copyWith(
                              color: C.bg, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
