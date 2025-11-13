// 1. (ده أهم سطر ولازم يكون موجود)
import 'package:flutter/material.dart';
import 'package:tabeby_app/screens/login_screen.dart'; // <--- ضيف ده
import 'package:tabeby_app/screens/signup_screen.dart'; // <--- ضيف ده


class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // بنستخدم MediaQuery عشان نجيب أبعاد الشاشة (الطول والعرض)
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // 1. Stack:
      // ده أهم Widget هنا. بيسمح لنا "نركب" العناصر فوق بعض
      // (زي الـ z-index في الويب). هنحط الخلفية تحت، وفوقها الزراير.
      body: Stack(
        // بنقوله املأ الشاشة كلها
        fit: StackFit.expand,
        children: [
          // --- الطبقة الأولى: الخلفية ---
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                // غيّر الاسم ده لاسم الصورة بتاعتك
                // (أنا هستخدم الصورة اللي حولتها لـ .png)
                image: AssetImage('assets/images/welcome.png'),
                // fit: BoxFit.cover بيضمن إن الصورة تملأ الشاشة
                fit: BoxFit.cover,
                // بنغمّق الصورة شوية عشان الكلام يبان عليها
                colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
              ),
            ),
          ),

          // --- الطبقة التانية: المحتوى (الزراير) ---
          Padding(
            // بنضيف مساحات فاضية حوالين المحتوى
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 60.0,
            ),
            child: Column(
              // mainAxisAlignment: بيرتب العناصر بالطول
              // spaceBetween: بيزق واحد فوق خالص وواحد تحت خالص
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
                      'Sehetie',
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
                  // crossAxisAlignment: بيرتب العناصر بالعرض
                  // stretch: بيخلي العناصر (الزراير) تملأ العرض كله
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- زرار تسجيل الدخول ---
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // لون الزرار
                        foregroundColor: Colors.blue.shade800, // لون النص
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      // onPressed: هي الـ Function اللي هتتنفذ لما ندوس
                      // حالياً هنسيبها فاضية
                      // ... الكود القديم ...
                      onPressed: () {
                        // الكود ده هو اللي بينقل للشاشة الجديدة
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

                    // بنسيب مسافة 12 بيكسل بين الزرارين
                    const SizedBox(height: 12),

                    // --- زرار حساب جديد ---
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Colors.white,
                          width: 2,
                        ), // الإطار
                        foregroundColor: Colors.white, // لون النص
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        // الكود ده بينقل لشاشة الحساب الجديد
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
