import 'package:flutter/material.dart';
import 'views/home_screen.dart';
// import 'database/database_helper.dart';

void main() {
  // وقفنا كود الديسكتوب مؤقتاً عشان الويب
  // WidgetsFlutterBinding.ensureInitialized();
  // DatabaseHelper db = DatabaseHelper();
  // await db.database;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ميزاني - إدارة الخردة',
      theme: ThemeData(
        // اخترنا لون مناسب للحديد والمخازن (BlueGrey)
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      // دي الشاشة اللي هتفتح أول ما البرنامج يشتغل
      home: const HomeScreen(),
    );
  }
}