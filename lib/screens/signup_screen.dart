import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
// 1. استيراد الـ Service بتاعنا
import 'package:tabeby_app/services/api_service.dart'; // <--- عدّل اسم المشروع لو مختلف

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _completePhoneNumber = '';

  // 2. متغيرات الـ State الجديدة
  final ApiService _apiService = ApiService(); // نسخة من الـ Service

  List<String> _countries = []; // قايمة الدول
  List<String> _cities = []; // قايمة المدن

  String? _selectedCountry; // الدولة اللي اختارها
  String? _selectedCity; // المدينة اللي اختارها

  bool _isLoadingCountries = true;
  bool _isLoadingCities = false;
  bool _isLoadingSignup = false;

  // 3. بنجيب الدول أول ما الشاشة تفتح
  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await _apiService.fetchCountries();
      setState(() {
        _countries = countries;
        _isLoadingCountries = false;
      });
    } catch (e) {
      // TODO: Show error snackbar
      setState(() {
        _isLoadingCountries = false;
      });
    }
  }

  // 4. بنجيب المدن لما اليوزر يختار دولة
  Future<void> _loadCities(String country) async {
    setState(() {
      _isLoadingCities = true;
      _cities = []; // بنفضّي المدن القديمة
      _selectedCity = null; // بنعمل ريسيت للمدينة
    });

    try {
      final cities = await _apiService.fetchCities(country);
      setState(() {
        _cities = cities;
        _isLoadingCities = false;
      });
    } catch (e) {
      // TODO: Show error snackbar
      setState(() {
        _isLoadingCities = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // دالة إنشاء الحساب (الجديدة)
  Future<void> _handleSignup() async {
    // 1. نتأكد إن الفورم سليم
    if (!_formKey.currentState!.validate()) {
      return; // لو الفورم مش سليم، بنرجع
    }

    // 2. بنعرض دايرة التحميل
    setState(() {
      _isLoadingSignup = true;
    });

    try {
      // 3. بننادي الـ API
      final response = await _apiService.signup(
        name: _nameController.text,
        phone: _completePhoneNumber,
        password: _passwordController.text,
        country: _selectedCountry!,
        city: _selectedCity!,
      );

      // 4. لو نجح:
      // بنوقف دايرة التحميل
      setState(() {
        _isLoadingSignup = false;
      });

      // بنعرض رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'تم إنشاء الحساب بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );

      // 5. بنرجّع اليوزر لورا (عشان يروح لصفحة اللوجن)
      Navigator.pop(context);
    } catch (e) {
      // 6. لو فشل (مثلاً: رقم متكرر أو مشكلة سيرفر)
      // بنوقف دايرة التحميل
      setState(() {
        _isLoadingSignup = false;
      });

      // بنعرض رسالة خطأ
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
      appBar: AppBar(title: const Text('إنشاء حساب جديد')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- حقل الاسم ---
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم بالكامل',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.name,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'برجاء إدخال الاسم'
                      : null,
                ),
                const SizedBox(height: 16),

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
                    if (value.length < 6)
                      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- 5. حقل الدولة (الاحترافي) ---
                DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  decoration: InputDecoration(
                    labelText: 'الدولة',
                    prefixIcon: _isLoadingCountries
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.map_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  // لو مفيش دول، بنعرض رسالة
                  hint: Text(
                    _isLoadingCountries ? 'جاري تحميل الدول...' : 'اختر الدولة',
                  ),
                  isExpanded: true,
                  // لو لسه بيحمّل، بنقفل الـ Dropdown
                  disabledHint: const Text('جاري تحميل الدول...'),
                  items: _countries.map((String country) {
                    return DropdownMenuItem<String>(
                      value: country,
                      child: Text(country),
                    );
                  }).toList(),
                  // 6. دي أهم دالة: لما اليوزر يختار
                  onChanged: _isLoadingCountries
                      ? null
                      : (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCountry = newValue;
                            });
                            // بنحمّل المدن بناءً على اختياره
                            _loadCities(newValue);
                          }
                        },
                  validator: (value) =>
                      (value == null) ? 'برجاء اختيار الدولة' : null,
                ),
                const SizedBox(height: 16),

                // --- 7. حقل المدينة (الاحترافي) ---
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: InputDecoration(
                    labelText: 'المدينة',
                    prefixIcon: _isLoadingCities
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.location_city_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  // لو مختارش دولة، بنقفل الـ Dropdown ده
                  hint: Text(
                    _selectedCountry == null
                        ? 'اختر الدولة أولاً'
                        : 'اختر المدينة',
                  ),
                  isExpanded: true,
                  disabledHint: Text(
                    _selectedCountry == null
                        ? 'اختر الدولة أولاً'
                        : 'جاري تحميل المدن...',
                  ),
                  items: _cities.map((String city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  // بنقفل الـ Dropdown لو مفيش دولة مختارة أو المدن لسه بتحمل
                  onChanged: (_selectedCountry == null || _isLoadingCities)
                      ? null
                      : (String? newValue) {
                          setState(() {
                            _selectedCity = newValue;
                          });
                        },
                  validator: (value) =>
                      (value == null) ? 'برجاء اختيار المدينة' : null,
                ),
                const SizedBox(height: 32),

                // --- زرار إنشاء الحساب ---
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _handleSignup,
                  child: _isLoadingSignup
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('إنشاء حساب'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
