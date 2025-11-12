import 'package:flutter/material.dart';
// 1. --- (جديد) استدعاء مكتبة تهيئة التواريخ ---
import 'package:intl/date_symbol_data_local.dart';
import 'package:tabeby_app/screens/auth_check_screen.dart';

// 2. --- (تعديل) بنخلي الدالة "async" ---
Future<void> main() async {
  // 3. --- (جديد) بنتأكد إن فلاتر جاهز ---
  WidgetsFlutterBinding.ensureInitialized();

  // 4. --- (جديد) بنهيئ اللغة العربية ---
  await initializeDateFormatting('ar', null);

  // 5. بنشغل التطبيق
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tabeby App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Cairo', // (اختياري: لو حابب تستخدم خط عربي أنضف)
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF9F9F9),
          elevation: 0,
        ),
      ),
      home: const AuthCheckScreen(),
    );
  }
}
