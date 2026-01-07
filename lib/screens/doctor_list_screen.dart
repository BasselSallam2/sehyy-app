import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sehetie_app/services/api_service.dart';

// 1. استيراد شاشة البروفايل (اللي لسه هنعملها)
import 'package:sehetie_app/screens/doctor_profile_screen.dart';
import 'package:sehetie_app/screens/search_screen.dart'; // <-- 1. ضيف ده

class DoctorListScreen extends StatefulWidget {
  final String specialtyId;
  final String specialtyName;

  const DoctorListScreen({
    super.key,
    required this.specialtyId,
    required this.specialtyName,
  });

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final doctors = await _apiService.getDoctorsBySpecialty(
        widget.specialtyId,
      );
      setState(() {
        _doctors = doctors;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          widget.specialtyName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // --- 2. التعديل هنا ---
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(
                    specialtyId: widget.specialtyId, // <-- 3. بنبعت الفلتر
                    specialtyName: widget.specialtyName, // (عشان الـ hint)
                  ),
                ),
              );
              // --- نهاية التعديل ---
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _doctors.isEmpty
                      ? const Center(
                          child: Text(
                            'لا يوجد أطباء في هذا القسم حالياً',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _doctors.length,
                          itemBuilder: (context, index) {
                            final doctor = _doctors[index];
                            return _buildDoctorCard(doctor);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDoctorSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'ابحث عن طبيب...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          // TODO: Implement live search logic
        },
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    // 1. بنجيب الداتا الحقيقية
    final String doctorName = doctor['name'] ?? 'اسم الطبيب';

    // 2. الصورة من avatar.url
    final String photoUrl =
        (doctor['avatar'] != null && doctor['avatar']['url'] != null)
        ? doctor['avatar']['url']
        : '';

    // 3. اسم التخصص من الداتا الـ populated
    final String specialtyName =
        (doctor['specialize'] != null && doctor['specialize']['title'] != null)
        ? doctor['specialize']['title']
        : 'أخصائي';

    // 4. العنوان
    final String address =
        '${doctor['address'] ?? 'العنوان'}, ${doctor['city'] ?? 'المدينة'}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.2),
      color: Colors.white,
      child: InkWell(
        // 5. بنخلي الكارت كله "يداس عليه"
        onTap: () {
          // 6. --- التعديل هنا: بننقل لبروفايل الدكتور ---
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorProfileScreen(
                doctorId: doctor['_id'], // <-- بنبعت الـ ID
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- العمود الأيسر (الصورة والزرار) ---
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: photoUrl.isNotEmpty
                        ? CachedNetworkImageProvider(photoUrl)
                        : null,
                    child: photoUrl.isEmpty
                        ? const Icon(Icons.person, size: 40, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  // 7. --- شيلنا الزرار ---
                  // (لإن الكارت كله بقى زرار)
                ],
              ),
              const SizedBox(width: 16),

              // --- العمود الأيمن (البيانات) ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      specialtyName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // 8. --- بنضيف زرار "احجز" هنا ---
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DoctorProfileScreen(doctorId: doctor['_id']),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                        ),
                        child: const Text('احجز'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
