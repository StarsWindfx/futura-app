import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'core/notifications/notification_service.dart';
import 'core/storage/storage_service.dart';
import 'providers/task_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/routine_provider.dart';
import 'providers/event_provider.dart';
import 'providers/sport_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0C0C0C),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await StorageService.instance.init();
  await NotificationService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()..load()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()..load()),
        ChangeNotifierProvider(create: (_) => RoutineProvider()..load()),
        ChangeNotifierProvider(create: (_) => EventProvider()..load()),
        ChangeNotifierProvider(create: (_) => SportProvider()..load()),
      ],
      child: const FuturaApp(),
    ),
  );
}
