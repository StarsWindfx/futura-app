import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'screens/main_screen.dart';

class FuturaApp extends StatefulWidget {
  const FuturaApp({super.key});

  @override
  State<FuturaApp> createState() => _FuturaAppState();
}

class _FuturaAppState extends State<FuturaApp> {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Futura',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const MainScreen(),
    );
  }
}
