import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tabeby_app/screens/main_screen.dart';
import 'package:tabeby_app/screens/welcome_screen.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final _storage = const FlutterSecureStorage();

  // 1. الدالة دي بتشتغل "أول ما الشاشة تفتح"
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // 2. بنديله ثانية واحدة عشان دايرة التحميل تبان (اختياري)
    await Future.delayed(const Duration(seconds: 1));

    try {
      // 3. بنقرأ التوكين من الـ Storage
      final token = await _storage.read(key: 'auth_token');

      if (!mounted) return; // (Safety check)

      if (token != null && token.isNotEmpty) {
        // 4. لو لقينا توكين: وديه للهوم
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        // 5. لو ملقيناش: وديه للـ Welcome
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    } catch (e) {
      // 6. لو حصل أي إيرور: وديه للـ Welcome برضه
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  // 7. دي شاشة التحميل اللي اليوزر هيشوفها لثانية
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}