import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sehetie_app/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // (للتاريخ العربي)
import 'package:url_launcher/url_launcher.dart'; // (عشان اللوكيشن والتليفون)
import 'package:sehetie_app/screens/login_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  final String doctorId;
  const DoctorProfileScreen({super.key, required this.doctorId});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Map<String, dynamic>? _doctorDetails;
  List<dynamic> _allSlots = [];
  bool _isLoading = true;
  String _nearestAvailableDay = '...';
  List<dynamic> _slotsForNearestDay = [];
  List<DateTime> _availableDates = [];

  @override
  void initState() {
    super.initState();
    _initializeArabicDateFormatting();
    _loadAllData();
  }

  // دالة لتهيئة اللغة العربية للتواريخ
  Future<void> _initializeArabicDateFormatting() async {
    await initializeDateFormatting('ar', null);
  }

  // --- 1. دوال تحميل الداتا ---
  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final results = await Future.wait([
        _apiService.getDoctorDetails(widget.doctorId),
        _apiService.getDoctorSlots(widget.doctorId),
      ]);
      _doctorDetails = results[0] as Map<String, dynamic>;
      _allSlots = results[1] as List<dynamic>;

      _processSlots();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _loadAllData: $e');
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _processSlots() {
    final now = DateTime.now();

    // بنفلتر المواعيد (عايزين اللي لسه مجاش + مش محجوز)
    final availableSlots = _allSlots.where((slot) {
      final slotDate = DateTime.parse(slot['date']);
      final bool isReserved = slot['reserved'] ?? false;
      final bool isAfterNow = slotDate.isAfter(now);
      return !isReserved && isAfterNow;
    }).toList();

    print('Available slots count: ${availableSlots.length}');

    // بنملى قايمة الأيام المتاحة (عشان نستخدمها في كذا مكان)
    _availableDates = availableSlots
        .map((slot) => DateTime.parse(slot['date']))
        .toSet() // بنشيل التكرار
        .toList(); // بنرجعها لـ List

    if (availableSlots.isEmpty) {
      setState(() {
        _nearestAvailableDay = 'لا توجد مواعيد متاحة';
        _slotsForNearestDay = [];
      });
      return;
    }

    // بنجيب أقرب ميعاد (لإنهم مترتبين بالـ date من الـ API)
    final nearestSlot = availableSlots[0];
    final nearestDate = DateTime.parse(nearestSlot['date']);

    // بنجيب "كل" المواعيد المتاحة في "نفس اليوم ده"
    final slotsForDay = availableSlots.where((slot) {
      final slotDate = DateTime.parse(slot['date']);
      return slotDate.year == nearestDate.year &&
          slotDate.month == nearestDate.month &&
          slotDate.day == nearestDate.day;
    }).toList();

    setState(() {
      _nearestAvailableDay = DateFormat(
        'EEEE، d/M/y',
        'ar',
      ).format(nearestDate);
      _slotsForNearestDay = slotsForDay;
    });
  }

  // --- 2. دوال الحجز والمواعيد (المعدلة) ---

  Future<void> _showCalendar({String? bannerId}) async {
    // بنتأكد إن فيه مواعيد أصلاً
    if (_availableDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد أي مواعيد متاحة للحجز لهذا الطبيب حالياً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // بنخلي أول يوم في التقويم هو "أول يوم متاح"
    final DateTime firstAvailableDate = _availableDates.first;

    // بنحدد تاريخ النهاية - إما 90 يوم من الآن، أو 90 يوم من أول يوم متاح (أيهما أبعد)
    final DateTime defaultLastDate = DateTime.now().add(
      const Duration(days: 90),
    );
    final DateTime extendedLastDate = firstAvailableDate.add(
      const Duration(days: 90),
    );
    final DateTime lastDate = extendedLastDate.isAfter(defaultLastDate)
        ? extendedLastDate
        : defaultLastDate;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: firstAvailableDate, // اليوم اللي "متعلّم عليه"
      currentDate: DateTime.now(), // اليوم اللي "هيفتح عليه" التقويم
      firstDate: firstAvailableDate, // بنبدأ التقويم من أول يوم متاح
      lastDate: lastDate,
      selectableDayPredicate: (DateTime day) {
        // بنشيك على القايمة اللي جهزناها
        return _availableDates.any(
          (d) => d.year == day.year && d.month == day.month && d.day == day.day,
        );
      },
    );

    if (pickedDate != null) {
      _showSlotsForDay(pickedDate, bannerId: bannerId); // (تمرير الـ ID)
    }
  }

  void _showSlotsForDay(DateTime date, {String? bannerId}) {
    final slotsForDay = _allSlots.where((slot) {
      final slotDate = DateTime.parse(slot['date']);
      final bool isReserved = slot['reserved'] ?? false;
      return !isReserved &&
          slotDate.year == date.year &&
          slotDate.month == date.month &&
          slotDate.day == date.day;
    }).toList();

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'المواعيد المتاحة يوم ${DateFormat('EEEE, d MMMM', 'ar').format(date)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: slotsForDay.map((slot) {
                  return ActionChip(
                    label: Text(slot['from']),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showBookingConfirmation(
                        slot,
                        bannerId: bannerId,
                      ); // (تمرير الـ ID)
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showBookingConfirmation(
    Map<String, dynamic> slot, {
    String? bannerId,
  }) async {
    final slotDate = DateTime.parse(slot['date']);
    final dateString = DateFormat('EEEE, d MMMM', 'ar').format(slotDate);
    final timeString = slot['from'];

    String message =
        'هل أنت متأكد أنك ترغب في حجز موعد يوم $dateString، الساعة $timeString؟';
    if (bannerId != null) {
      message += '\n(سيتم تطبيق العرض الخاص بهذا الحجز)';
    }

    final bool? didConfirm = await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('تأكيد الحجز'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('لا'),
              onPressed: () {
                Navigator.of(ctx).pop(false);
              },
            ),
            ElevatedButton(
              child: const Text('نعم، تأكيد'),
              onPressed: () {
                Navigator.of(ctx).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (didConfirm == true) {
      _bookSlot(slot['_id'], bannerId: bannerId); // (تمرير الـ ID)
    }
  }

  Future<bool> _isGuestUser() async {
    final isGuest = await _storage.read(key: 'is_guest');
    return isGuest == 'true';
  }

  Future<void> _bookSlot(String slotId, {String? bannerId}) async {
    // Check if user is a guest
    final isGuest = await _isGuestUser();

    if (isGuest) {
      // Show login prompt for guest users
      _showLoginPrompt();
      return;
    }

    try {
      await _apiService.bookSlot(slotId, bannerId: bannerId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تأكيد الحجز بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadAllData(); // بنحمّل المواعيد تاني عشان نحدث "أقرب يوم"
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تسجيل الدخول مطلوب'),
          content: const Text(
            'يجب عليك تسجيل الدخول لحجز موعد لدى الطبيب. هل تريد تسجيل الدخول الآن؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Navigate to login screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('تسجيل الدخول'),
            ),
          ],
        );
      },
    );
  }

  // --- 3. دوال التواصل (اللوكيشن والتليفون) ---

  Future<void> _launchLocationUrl(String url) async {
    String AUrl = url;
    if (!AUrl.startsWith('http://') && !AUrl.startsWith('https://')) {
      AUrl = 'https://$AUrl';
    }
    final Uri uri = Uri.parse(AUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يمكن فتح هذا الرابط: $AUrl'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final String cleanPhone = phoneNumber.replaceAll('-', '');
    final Uri uri = Uri.parse('tel:$cleanPhone');
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يمكن الاتصال بهذا الرقم: $phoneNumber'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- 4. دالة مودال العروض (الجديدة) ---
  void _showOffersSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return FutureBuilder<List<dynamic>>(
              future: _apiService.getBannersForDoctor(widget.doctorId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    heightFactor: 5,
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    heightFactor: 5,
                    child: Text('خطأ في تحميل العروض: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    heightFactor: 5,
                    child: Text('لا توجد عروض لهذا الطبيب حالياً'),
                  );
                }

                final banners = snapshot.data!;

                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ListView.builder(
                    itemCount: banners.length,
                    itemBuilder: (context, index) {
                      final banner = banners[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        elevation: 2,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context); // 1. اقفل المودال
                            _showCalendar(
                              bannerId: banner['_id'],
                            ); // 2. افتح التقويم بالـ ID
                          },
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: CachedNetworkImage(
                                  imageUrl: banner['image']['url'],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Container(color: Colors.grey[200]),
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                        Icons.error,
                                        color: Colors.red,
                                      ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        banner['title'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        banner['subtitle'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- 5. بناء الـ UI (الدوال المساعدة) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLoading
              ? 'جاري التحميل...'
              : _doctorDetails?['name'] ?? 'بروفايل الطبيب',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _doctorDetails == null
          ? const Center(child: Text('حدث خطأ أثناء تحميل بيانات الطبيب'))
          : _buildDoctorProfile(),
      bottomNavigationBar: _isLoading ? null : _buildBottomBar(),
    );
  }

  Widget _buildDoctorProfile() {
    return ListView(
      children: [
        _buildDoctorHeader(),
        _buildAvailabilitySection(),
        // (إضافة زرار العروض)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.local_offer_outlined),
            label: const Text('مشاهدة العروض المتاحة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange.shade800,
              side: BorderSide(color: Colors.orange.shade800),
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: _showOffersSheet, // (بينادي الدالة الجديدة)
          ),
        ),
        _buildInfoSection(),
      ],
    );
  }

  Widget _buildDoctorHeader() {
    final doctor = _doctorDetails!;
    final String photoUrl =
        (doctor['avatar'] != null && doctor['avatar']['url'] != null)
        ? doctor['avatar']['url']
        : '';
    final String specialtyName =
        (doctor['specialize'] != null && doctor['specialize']['title'] != null)
        ? doctor['specialize']['title']
        : 'أخصائي';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: photoUrl.isNotEmpty
                ? CachedNetworkImageProvider(photoUrl)
                : null,
            child: photoUrl.isEmpty
                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor['name'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  specialtyName,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _nearestAvailableDay,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _slotsForNearestDay.map((slot) {
              final bool isReserved = slot['reserved'] ?? false;
              return ActionChip(
                label: Text(slot['from']),
                backgroundColor: isReserved
                    ? Colors.grey.shade300
                    : Colors.blue.shade50,
                onPressed: isReserved
                    ? null
                    : () {
                        _showBookingConfirmation(
                          slot,
                          bannerId: null,
                        ); // (بنبعت null)
                      },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => _showCalendar(bannerId: null), // (بنبعت null)
              child: const Text('اعرض كل المواعيد'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    final doctor = _doctorDetails!;
    final String address =
        '${doctor['address'] ?? 'العنوان'}, ${doctor['city'] ?? 'المدينة'}';
    final String locationUrl = doctor['location'] ?? '';
    final List<dynamic> contacts = doctor['contacts'] ?? [];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نبذة عن الطبيب',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            doctor['description'] ?? 'لا توجد نبذة حالياً.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const Divider(height: 40),
          const Text(
            'العنوان',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: locationUrl.isNotEmpty
                ? () => _launchLocationUrl(locationUrl)
                : null,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: locationUrl.isNotEmpty
                        ? Colors.blue.shade700
                        : Colors.black54,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(address, style: const TextStyle(fontSize: 15)),
                ),
                if (locationUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(
                      Icons.open_in_new,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 40),
          const Text(
            'أرقام التواصل',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (contacts.isEmpty)
            Text(
              'لا توجد أرقام تواصل متاحة',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
            )
          else
            Column(
              children: contacts.map((phoneNumber) {
                return InkWell(
                  onTap: () => _launchPhone(phoneNumber.toString()),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Icon(
                            Icons.phone_outlined,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            phoneNumber.toString(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const Icon(Icons.call, color: Colors.grey, size: 20),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final doctor = _doctorDetails!;
    final String specialtyName =
        (doctor['specialize'] != null && doctor['specialize']['title'] != null)
        ? doctor['specialize']['title']
        : 'أخصائي';

    return Container(
      padding: const EdgeInsets.all(16.0).copyWith(bottom: 30.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'التخصص',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              Text(
                specialtyName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => _showCalendar(bannerId: null), // (بنبعت null)
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            ),
            child: const Text('احجز الآن'),
          ),
        ],
      ),
    );
  }
}
