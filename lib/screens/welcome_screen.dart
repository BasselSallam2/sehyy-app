import 'package:flutter/material.dart';
import 'package:tabeby_app/screens/login_screen.dart';
import 'package:tabeby_app/screens/signup_screen.dart';
import 'package:tabeby_app/screens/about_us_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // بنستخدم MediaQuery عشان نجيب أبعاد الشاشة (الطول والعرض)
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // --- الطبقة الأولى: الخلفية ---
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                // (اتأكد إن اسم الصورة صح - زي ما استخدمته في الـ assets)
                image: AssetImage('assets/images/welcome.png'),
                fit: BoxFit.cover,
                // (الفلتر عشان نغمق الصورة)
                colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
              ),
            ),
          ),

          // --- الطبقة التانية: المحتوى (الزراير) ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 60.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // -- الجزء اللي فوق (اللوجو أو اسم التطبيق) --
                const Column(
                  children: [
                    Icon(
                      Icons.medical_services_rounded,
                      color: Colors.white,
                      size: 80,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Sehetie', // (الاسم اللي إنت عدلته)
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'احجز موعدك بسهولة',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ],
                ),

                // -- الجزء اللي تحت (الزراير) --
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- زرار تسجيل الدخول ---
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // --- مسافة ---
                    const SizedBox(height: 12),

                    // --- زرار حساب جديد ---
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'إنشاء حساب جديد',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // --- (هنا التعديل) ---
                    const SizedBox(height: 16),

                    // 1. بنستخدم Align عشان نلغي الـ stretch ونخليه في النص
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          // 2. لون مميز (أبيض شفاف)
                          foregroundColor: Colors.white.withOpacity(0.85),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 10,
                          ),
                          // 3. ستايل الخط (أصغر ومش bold)
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            decoration: TextDecoration.none, // 4. من غير خط
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutUsScreen(),
                            ),
                          );
                        },
                        child: const Text('من نحن؟'),
                      ),
                    ),
                    // --- نهاية التعديل ---
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
