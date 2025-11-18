import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:tabeby_app/screens/welcome_screen.dart';
import 'package:tabeby_app/screens/search_screen.dart';
import 'package:tabeby_app/services/api_service.dart';
import 'package:tabeby_app/screens/doctor_list_screen.dart';
import 'package:tabeby_app/screens/doctor_profile_screen.dart';
import 'package:tabeby_app/screens/about_us_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  // داتا الفلاتر
  List<dynamic> _allSpecialties = [];
  List<String> _userCities = [];

  // الداتا المعروضة
  List<dynamic> _banners = [];

  // الفلاتر المختارة
  String? _selectedSpecialtyId;
  String? _selectedCity;

  // --- 1. متغيرات الـ State الجديدة للـ Pagination ---
  bool _isLoadingPage = true;
  bool _isLoadingBanners = false;
  bool _isLoadingMore = false; // <-- (جديد) للزرار
  int _bannerPage = 1;
  bool _hasNextPage = false; // <-- (جديد) عشان نعرف نعرض الزرار ولا لأ

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // 2. دالة تحميل الداتا "الأولية"
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingPage = true;
      _banners = []; // بنفضي البنرات القديمة
      _bannerPage = 1; // بنبدأ من صفحة 1
    });

    try {
      final results = await Future.wait([
        _apiService.getSpecialties(),
        _apiService.getUserCities(),
        _apiService.getBanners(limit: 3, page: 1), // <-- أول 3 بنرات (صفحة 1)
      ]);

      // 3. بنتعامل مع الرد الجديد (Map)
      final bannerResponse = results[2] as Map<String, dynamic>;

      setState(() {
        _allSpecialties =
            results[0] as List<dynamic>; // <--- 1. ضيف 'as List<dynamic>'
        _userCities = results[1] as List<String>;

        _banners = bannerResponse['data'];
        _hasNextPage = bannerResponse['pagination']['hasNextPage'];
        _isLoadingPage = false;
      });
    } catch (e) {
      _handleError(e);
    }
  }

  // 4. دالة "الفلترة" (دي بتمسح القديم وتحمل من أول صفحة)
  Future<void> _loadFilteredBanners() async {
    setState(() {
      _isLoadingBanners = true;
      _bannerPage = 1; // <-- بنرجع لصفحة 1
      _banners = []; // <-- بنفضي القايمة
    });

    try {
      final bannerResponse = await _apiService.getBanners(
        specialize: _selectedSpecialtyId,
        city: _selectedCity,
        limit: 3,
        page: _bannerPage,
      );

      setState(() {
        _banners = bannerResponse['data'];
        _hasNextPage = bannerResponse['pagination']['hasNextPage'];
        _isLoadingBanners = false;
      });
    } catch (e) {
      _handleError(e);
    }
  }

  // 5. --- دالة "تحميل المزيد" (الجديدة) ---
  Future<void> _loadMoreBanners() async {
    // لو بنحمّل أصلاً، أو مفيش صفحات تانية، منعملش حاجة
    if (_isLoadingMore || !_hasNextPage) return;

    setState(() {
      _isLoadingMore = true;
      _bannerPage++; // <-- بنزود رقم الصفحة
    });

    try {
      final bannerResponse = await _apiService.getBanners(
        specialize: _selectedSpecialtyId,
        city: _selectedCity,
        limit: 3,
        page: _bannerPage, // <-- بنبعت رقم الصفحة الجديد
      );

      setState(() {
        // 6. بنضيف الداتا الجديدة على القديمة (مش بنمسحها)
        _banners.addAll(bannerResponse['data']);
        _hasNextPage = bannerResponse['pagination']['hasNextPage'];
        _isLoadingMore = false;
      });
    } catch (e) {
      _handleError(e);
      setState(() {
        _isLoadingMore = false;
        _bannerPage--; // (بنرجع الصفحة لو فشل)
      });
    }
  }

  // (دوال مساعدة زي ما هي)
  void _handleError(Object e) {
    setState(() {
      _isLoadingPage = false;
      _isLoadingBanners = false;
      _isLoadingMore = false;
    });
    if (!mounted) return;
    if (e.toString().contains('User not authenticated')) {
      _logout();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    // ... (الكود زي ما هو) ...
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'auth_token');
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false,
    );
  }

  // --- 7. بداية الـ UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('الرئيسية'),
        backgroundColor: Colors.transparent,
        elevation: 0,

        // --- (جديد) بنلغي زرار الرجوع الأوتوماتيكي ---
        automaticallyImplyLeading: false,

        actions: [
          // --- (جديد) بنضيف زرار "من نحن" ---
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'عن التطبيق',
            onPressed: () {
              // (لازم نتأكد إننا عاملين import فوق)
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutUsScreen()),
              );
            },
          ),

          // (ده زرار الخروج اللي إنت عامله)
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _isLoadingPage
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('الأقسام الطبية'),
                  const SizedBox(height: 12),
                  _buildSpecialtiesGrid(),

                  const SizedBox(height: 24),

                  _buildSectionTitle('عروض العيادات'),
                  const SizedBox(height: 12),
                  _buildFiltersSection(),

                  const SizedBox(height: 12),

                  _buildBannersList(), // <-- دي اللي بتعرض البنرات
                  // 8. --- زرار "تحميل المزيد" (الجديد) ---
                  _buildLoadMoreButton(),
                ],
              ),
            ),
    );
  }

  // 9. --- ودجت البنرات (المعدل) ---
  Widget _buildBannersList() {
    // لو بيحمّل (بعد الفلترة)، بنعرض دايرة تحميل
    if (_isLoadingBanners) {
      return const Center(heightFactor: 5, child: CircularProgressIndicator());
    }

    // لو مفيش بنرات (نتيجة الفلتر فاضية)
    if (_banners.isEmpty) {
      return const Center(
        heightFactor: 5,
        child: Text(
          'لا توجد عروض تطابق هذا البحث',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // لو فيه بنرات، بنعرضها
    return Column(
      children: _banners.map((banner) {
        return Card(
          // ... (الكود ده سليم)
          child: InkWell(
            onTap: () {
              // --- 2. ده الكود الجديد ---
              // بنجيب ID الدكتور من البنر
              final String? doctorId = banner['doctor'];

              if (doctorId != null) {
                // 3. بننقل لصفحة البروفايل بالـ ID ده
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DoctorProfileScreen(doctorId: doctorId),
                  ),
                );
              } else {
                // (احتياطي لو البنر معلهوش دكتور)
                print('No doctor ID found for this banner');
              }
              // --- نهاية التعديل ---
            },
            child: Row(
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CachedNetworkImage(
                    imageUrl: banner['image']['url'],
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error, color: Colors.red),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          banner['subtitle'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // 10. --- ودجت زرار "تحميل المزيد" (الجديد) ---
  Widget _buildLoadMoreButton() {
    // لو مفيش صفحة تانية، بنعرض "مساحة فاضية"
    if (!_hasNextPage) {
      return const SizedBox(height: 20); // مساحة في آخر الشاشة
    }

    // لو بنحمّل، بنعرض دايرة تحميل
    if (_isLoadingMore) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // لو فيه صفحة تانية ومش بنحمّل، بنعرض الزرار
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: OutlinedButton(
        onPressed: _loadMoreBanners, // <-- بننادي الدالة الجديدة
        child: const Text('تحميل المزيد من العروض'),
      ),
    );
  }

  Widget _buildSearchBar() {
    // 2. ده بقى "زرار" مش "حقل إدخال"
    return InkWell(
      onTap: () {
        // 3. بينقلنا للشاشة الجديدة (من غير فلتر قسم)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SearchScreen(specialtyId: null),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey.shade600),
            const SizedBox(width: 10),
            Text(
              'ابحث عن طبيب أو عيادة...',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _buildSpecialtiesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 115, // <-- 1. الحل: بنثبت ارتفاع كل المربعات
      ),
      itemCount: _allSpecialties.length,
      itemBuilder: (context, index) {
        final specialty = _allSpecialties[index];
        return InkWell(
          onTap: () {
            // --- 2. ده الكود اللي "هيفعّل" الزرار ---
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DoctorListScreen(
                  specialtyId: specialty['_id'],
                  specialtyName: specialty['title'],
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              //mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl: specialty['image']['url'],
                  width: 40,
                  height: 40,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(strokeWidth: 2),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error, color: Colors.red),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: Text(
                    specialty['title'],
                    textAlign: TextAlign.center,
                    maxLines: 2, // هيفضل 2
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // --- نهاية التعديل ---
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedSpecialtyId,
            hint: const Text('كل الأقسام'),
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: _allSpecialties.map((specialty) {
              return DropdownMenuItem<String>(
                value: specialty['_id'],
                child: Text(specialty['title']),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedSpecialtyId = newValue;
              });
              _loadFilteredBanners();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCity,
            hint: const Text('كل المدن'),
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: _userCities.map((String city) {
              return DropdownMenuItem<String>(value: city, child: Text(city));
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedCity = newValue;
              });
              _loadFilteredBanners();
            },
          ),
        ],
      ),
    );
  }
}
