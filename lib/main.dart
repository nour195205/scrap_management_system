import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'app_theme.dart';
import 'views/main_layout.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..loadSampleData(),
      child: const MizanyApp(),
    ),
  );
}

class MizanyApp extends StatelessWidget {
  const MizanyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ميزاني - إدارة الخردة',
      theme: AppTheme.dark,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const MainLayout(),
    );
  }
}