import 'package:flutter/material.dart';
import 'package:tabeby_app/screens/home_screen.dart';
import 'package:tabeby_app/screens/bookings_screen.dart';
import 'package:tabeby_app/screens/about_us_screen.dart'; // <-- 1. استيراد "من نحن"

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // (0=الرئيسية, 1=حجوزاتي, 2=من نحن)

  // 2. --- (التعديل الأول) ---
  // (بنضيف الشاشة الجديدة للقائمة)
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    BookingsScreen(),
    AboutUsScreen(), // <-- الإضافة
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      // 3. --- (التعديل التاني) ---
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          // (الزرار الأول: الرئيسية)
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          // (الزرار التاني: حجوزاتي)
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'حجوزاتي',
          ),
          // (الزرار التالت: من نحن) <-- الإضافة
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue.shade700,
        // (إضافة بسيطة عشان الأيقونات اللي مش مختارة متبقاش باهتة أوي)
        unselectedItemColor: Colors.grey.shade600,
        onTap: _onItemTapped,
      ),
    );
  }
}
