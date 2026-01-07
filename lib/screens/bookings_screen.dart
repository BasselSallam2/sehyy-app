import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:sehetie_app/services/api_service.dart';
import 'package:sehetie_app/screens/doctor_profile_screen.dart'; // (عشان زرار "زيارة")

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

// 1. بنستخدم "TickerProviderStateMixin" عشان الـ TabController
class _BookingsScreenState extends State<BookingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<dynamic> _allBookings = [];
  bool _isLoading = true;
  bool _isGuest = false;

  // 2. القوايم المفلترة
  List<dynamic> _todayBookings = [];
  List<dynamic> _upcomingBookings = [];
  List<dynamic> _pastBookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 تابات
    _checkGuestStatus();
  }

  Future<void> _checkGuestStatus() async {
    final isGuest = await _storage.read(key: 'is_guest');
    setState(() {
      _isGuest = isGuest == 'true';
    });

    if (!_isGuest) {
      _loadMyBookings();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMyBookings() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final bookings = await _apiService.getMyBookings();
      setState(() {
        _allBookings = bookings;
        _filterBookings(); // <-- 3. بننادي دالة الفلترة
        _isLoading = false;
      });
    } catch (e) {
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

  // 4. --- دالة الفلترة (الأهم) ---
  void _filterBookings() {
    final now = DateTime.now();
    final today = DateTime(
      now.year,
      now.month,
      now.day,
    ); // (النهاردة الساعة 12ص)

    // بنفضي القوايم القديمة
    _todayBookings.clear();
    _upcomingBookings.clear();
    _pastBookings.clear();

    for (var booking in _allBookings) {
      final slotDate = DateTime.parse(booking['date']);
      final bookingDay = DateTime(slotDate.year, slotDate.month, slotDate.day);

      if (bookingDay.isAtSameMomentAs(today)) {
        // (حجز اليوم)
        _todayBookings.add(booking);
      } else if (bookingDay.isAfter(today)) {
        // (حجز قادم)
        _upcomingBookings.add(booking);
      } else {
        // (حجز منتهي)
        _pastBookings.add(booking);
      }
    }
  }

  // 5. دالة "إلغاء الحجز"
  Future<void> _cancelBooking(String slotId) async {
    final bool? didConfirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الحجز'),
        content: const Text('هل أنت متأكد أنك ترغب في إلغاء هذا الموعد؟'),
        actions: [
          TextButton(
            child: const Text('لا'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            child: const Text('نعم، إلغاء'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (didConfirm == true) {
      try {
        await _apiService.cancelBooking(slotId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إلغاء الحجز بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _loadMyBookings(); // (بنعمل "تحديث" للقوايم)
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- 6. بناء الـ UI ---
  @override
  Widget build(BuildContext context) {
    // Show guest message if user is not logged in
    if (_isGuest) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'حجوزاتي',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              const Text(
                'يجب تسجيل الدخول لرؤية الحجوزات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'قم بتسجيل الدخول لحجز المواعيد وعرض حجوزاتك',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Navigate back to home or show login
                  Navigator.of(
                    context,
                  ).pushReplacementNamed('/'); // Go to main screen
                },
                child: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'حجوزاتي',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        // 7. الـ TabBar (العناوين)
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'اليوم'),
            Tab(text: 'قادم'),
            Tab(text: 'منتهي'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              // 8. الـ TabBarView (المحتوى)
              controller: _tabController,
              children: [
                _buildBookingsList(_todayBookings, canCancel: true),
                _buildBookingsList(_upcomingBookings, canCancel: true),
                _buildBookingsList(
                  _pastBookings,
                  canCancel: false,
                ), // (المنتهي مينفعش يتلغي)
              ],
            ),
    );
  }

  // 9. ودجت "قايمة الحجوزات"
  Widget _buildBookingsList(List<dynamic> bookings, {required bool canCancel}) {
    if (bookings.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد حجوزات في هذا التصنيف',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking, canCancel);
      },
    );
  }

  // 10. ودجت "كارت الحجز" (الأهم)
  Widget _buildBookingCard(Map<String, dynamic> booking, bool canCancel) {
    // --- (هنا بنفترض إنك عملت populate للدكتور) ---
    final doctor = booking['doctor'] as Map<String, dynamic>?;

    final String doctorName = doctor?['name'] ?? 'طبيب غير معروف';
    final String specialty = doctor?['specialize']?['title'] ?? 'تخصص';
    final String photoUrl = doctor?['avatar']?['url'] ?? '';

    final slotDate = DateTime.parse(booking['date']);
    final dateString = DateFormat('EEEE، d MMMM yyyy', 'ar').format(slotDate);
    final timeString = booking['from'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. بيانات الدكتور
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: photoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(photoUrl)
                      : null,
                  child: photoUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        specialty,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            // 2. بيانات الموعد
            Text(
              '$dateString - الساعة $timeString',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),

            // 3. (لو فيه بانر بنعرضه)
            if (booking['bunner'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  ' (تم الحجز عن طريق عرض) 🏷️',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // 4. الزراير
            if (canCancel) const SizedBox(height: 10),
            if (canCancel)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text('زيارة الصفحة'),
                    onPressed: () {
                      if (doctor != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DoctorProfileScreen(doctorId: doctor['_id']),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                    ),
                    child: const Text('إلغاء الحجز'),
                    onPressed: () => _cancelBooking(booking['_id']),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
