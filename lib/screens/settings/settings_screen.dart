import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/event_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/futura_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name;
  bool _notif = true, _quiet = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);

  @override
  void initState() {
    super.initState();
    final s = StorageService.instance;
    _name = TextEditingController(text: s.getString('user_name') ?? '');
    _notif = s.getBool('notif_enabled') ?? true;
    _quiet = s.getBool('quiet_hours') ?? false;
    _quietStart = TimeOfDay(hour: s.getInt('qs_h') ?? 22, minute: s.getInt('qs_m') ?? 0);
    _quietEnd = TimeOfDay(hour: s.getInt('qe_h') ?? 7, minute: s.getInt('qe_m') ?? 0);
  }

  @override
  void dispose() { _name.dispose(); super.dispose(); }

  Future<TimeOfDay?> _pickTime(TimeOfDay init) => showTimePicker(
    context: context, initialTime: init,
    builder: (ctx, child) => Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(primary: C.ink, onPrimary: C.bg, surface: C.sheet, onSurface: C.ink),
        dialogTheme: DialogThemeData(backgroundColor: C.sheet, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
      child: child!,
    ),
  );

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.sheet,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Tout effacer ?', style: T.h3(context)),
        content: Text('Toutes les données seront supprimées.', style: T.small(context)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Annuler', style: T.small(context))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Effacer', style: T.small(context).copyWith(color: C.err, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await NotificationService.instance.cancelAll();
    await StorageService.instance.clearAll();
    if (!mounted) return;
    context.read<TaskProvider>().load();
    context.read<ReminderProvider>().load();
    context.read<RoutineProvider>().load();
    context.read<EventProvider>().load();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Données effacées'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverSafeArea(
            bottom: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
              sliver: SliverToBoxAdapter(child: Text('Paramètres', style: T.h1(context))),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 32, 22, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Profil ────────────────────────────────────────────
                Text('PROFIL', style: T.label(context)),
                const SizedBox(height: 12),
                FRow(
                  showDivider: false,
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.border, width: 0.5)),
                      child: const Icon(Icons.person_outline, color: C.muted, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _name,
                        style: T.body(context),
                        decoration: InputDecoration(
                          hintText: 'Votre nom',
                          hintStyle: T.body(context).copyWith(color: C.muted),
                          filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (v) => StorageService.instance.setString('user_name', v.trim()),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => StorageService.instance.setString('user_name', _name.text.trim()),
                      child: const Icon(Icons.check, color: C.muted, size: 16),
                    ),
                  ]),
                ),

                const SizedBox(height: 32),
                Text('NOTIFICATIONS', style: T.label(context)),
                const SizedBox(height: 12),

                FRow(
                  showDivider: true,
                  child: Row(children: [
                    Text('Activer', style: T.body(context)),
                    const Spacer(),
                    Switch(value: _notif, onChanged: (v) async {
                      setState(() => _notif = v);
                      await StorageService.instance.setBool('notif_enabled', v);
                      if (v) NotificationService.instance.requestPermission();
                    }),
                  ]),
                ),

                FRow(
                  showDivider: _quiet,
                  child: Row(children: [
                    Text('Heures silencieuses', style: T.body(context)),
                    const Spacer(),
                    Switch(value: _quiet, onChanged: (v) async {
                      setState(() => _quiet = v);
                      await StorageService.instance.setBool('quiet_hours', v);
                    }),
                  ]),
                ),

                if (_quiet)
                  FRow(
                    showDivider: false,
                    child: Row(children: [
                      GestureDetector(
                        onTap: () async {
                          final t = await _pickTime(_quietStart);
                          if (t != null) { setState(() => _quietStart = t); StorageService.instance.setInt('qs_h', t.hour); StorageService.instance.setInt('qs_m', t.minute); }
                        },
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Début', style: T.label(context)),
                          Text(_fmt(_quietStart), style: T.monoLg(context)),
                        ]),
                      ),
                      const SizedBox(width: 32),
                      GestureDetector(
                        onTap: () async {
                          final t = await _pickTime(_quietEnd);
                          if (t != null) { setState(() => _quietEnd = t); StorageService.instance.setInt('qe_h', t.hour); StorageService.instance.setInt('qe_m', t.minute); }
                        },
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Fin', style: T.label(context)),
                          Text(_fmt(_quietEnd), style: T.monoLg(context)),
                        ]),
                      ),
                    ]),
                  ),

                const SizedBox(height: 32),
                Text('DONNÉES', style: T.label(context)),
                const SizedBox(height: 12),

                FRow(
                  onTap: _clearAll,
                  showDivider: false,
                  child: Row(children: [
                    Text('Tout effacer', style: T.body(context).copyWith(color: C.err)),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: C.err, size: 16),
                  ]),
                ),

                const SizedBox(height: 48),
                Center(
                  child: Column(children: [
                    Text('FUTURA', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: C.muted, letterSpacing: 4)),
                    const SizedBox(height: 4),
                    Text('v1.0.0', style: T.mono(context).copyWith(fontSize: 11, color: C.muted)),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
