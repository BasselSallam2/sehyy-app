import 'package:flutter/material.dart';
import 'package:tabeby_app/screens/home_screen.dart';
import 'package:tabeby_app/screens/bookings_screen.dart'; // (لسه هنعمله)

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // (0 = الرئيسية, 1 = حجوزاتي)

  // 1. دي قايمة الشاشات بتاعتنا
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    BookingsScreen(), // (الشاشة الجديدة)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 2. بنعرض الشاشة المختارة
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      // 3. ده الـ NavBar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home), // (أيقونة وهي مختارة)
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'حجوزاتي',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue.shade700, // (لون الأيقونة المختارة)
        onTap: _onItemTapped,
      ),
    );
  }
}