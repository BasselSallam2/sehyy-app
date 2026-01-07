import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 1. استيراد الملفات اللي هنحتاجها
import 'package:sehetie_app/services/api_service.dart';
import 'package:sehetie_app/screens/home_screen.dart'; // <--- شاشتنا الجديدة
// import main screen
import 'package:sehetie_app/screens/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  String _completePhoneNumber = '';

  // 2. تعريف الـ Service والـ Storage
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 3. بننادي دالة اللوجن من الـ Service
      final response = await _apiService.login(
        phone: _completePhoneNumber,
        password: _passwordController.text,
      );

      // 4. لو نجح، بنجيب التوكين من الرد
      final token = response['token'];
      if (token != null) {
        // 5. بنخزن التوكين بأمان ونمسح الـ guest flag
        await _storage.write(key: 'auth_token', value: token);
        await _storage.delete(key: 'is_guest'); // Clear guest flag

        // 6. بننقل اليوزر للشاشة الرئيسية
        // بنستخدم pushReplacement عشان اليوزر لو داس "Back" ميرجعش للوجن
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const MainScreen(),
          ), // <--- الصح هنا
          (route) =>
              false, // <-- السطر ده بيمسح شاشة اللوجن والـ Welcome من الذاكرة
        );
      } else {
        throw Exception('Token not found in response');
      }
    } catch (e) {
      // 7. لو فشل (باسورد غلط، ...إلخ)
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- حقل الهاتف ---
                IntlPhoneField(
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    border: OutlineInputBorder(),
                  ),
                  initialCountryCode: 'EG',
                  onChanged: (phone) {
                    _completePhoneNumber =
                        '${phone.countryCode}-${phone.number}';
                  },
                  validator: (phone) => (phone == null || phone.number.isEmpty)
                      ? 'برجاء إدخال رقم الهاتف'
                      : null,
                ),
                const SizedBox(height: 16),

                // --- حقل كلمة المرور ---
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'برجاء إدخال كلمة المرور';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // --- زرار تسجيل الدخول ---
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('دخول'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
