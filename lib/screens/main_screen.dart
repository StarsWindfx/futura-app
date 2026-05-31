import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/notifications/notification_service.dart';
import '../core/theme/app_theme.dart';
import 'home/home_screen.dart';
import 'tasks/tasks_screen.dart';
import 'reminders/reminders_screen.dart';
import 'agenda/agenda_screen.dart';
import 'routines/routines_screen.dart';
import 'sport/sport_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await NotificationService.instance.requestPermission();
  }

  static const _nav = [
    (Icons.house_outlined, Icons.house_rounded, 'Accueil'),
    (Icons.check_box_outline_blank_rounded, Icons.check_box_rounded, 'Tâches'),
    (Icons.fitness_center_outlined, Icons.fitness_center_rounded, 'Sport'),
    (Icons.notifications_outlined, Icons.notifications_rounded, 'Rappels'),
    (Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Agenda'),
    (Icons.repeat_rounded, Icons.repeat_rounded, 'Routines'),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onGo: (i) => setState(() => _i = i)),
      const TasksScreen(),
      const SportScreen(),
      const RemindersScreen(),
      const AgendaScreen(),
      const RoutinesScreen(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: C.bg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: C.bg,
        extendBody: true,
        body: IndexedStack(index: _i, children: screens),
        bottomNavigationBar: _FloatingNav(
          current: _i,
          items: _nav,
          onTap: (i) {
            HapticFeedback.selectionClick();
            setState(() => _i = i);
          },
        ),
      ),
    );
  }
}

class _FloatingNav extends StatelessWidget {
  final int current;
  final List<(IconData, IconData, String)> items;
  final ValueChanged<int> onTap;

  const _FloatingNav({required this.current, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: C.pill,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: C.border, width: 0.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 10)),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              final (iconOff, iconOn, label) = items[i];
              final selected = current == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: selected ? C.ink : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        selected ? iconOn : iconOff,
                        size: 18,
                        color: selected ? C.bg : C.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: selected ? 1 : 0,
                      child: Container(
                        width: 3, height: 3,
                        decoration: const BoxDecoration(color: C.ink, shape: BoxShape.circle),
                      ),
                    ),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}
