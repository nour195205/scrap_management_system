import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // متغير وهمي لرأس المال لحد ما نربطه بالداتا بيز
  double currentCapital = 50000.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ميزاني - لوحة التحكم', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade100,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // لوجو بسيط يعبر عن إعادة التدوير والخردة
            const Icon(Icons.recycling, size: 120, color: Colors.green),
            const SizedBox(height: 20),
            
            // عرض رأس المال
            const Text(
              'رأس المال الحالي في الخزنة',
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
            Text(
              '$currentCapital جنيه',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            
            const SizedBox(height: 50),
            
            // زرار إضافة منتج جديد
            ElevatedButton.icon(
              onPressed: () {
                // هنا هنخليه يفتح شاشة إضافة (حديد، نحاس، كرتون)
                print("تم الضغط على إضافة صنف");
              },
              icon: const Icon(Icons.add_box, size: 28),
              label: const Text('إضافة صنف خردة جديد', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}