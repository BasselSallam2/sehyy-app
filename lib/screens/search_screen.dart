import 'dart:async'; // (مهم عشان الـ Debounce Timer)
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tabeby_app/services/api_service.dart';
import 'package:tabeby_app/screens/doctor_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? specialtyId;
  final String? specialtyName; // (عشان نعرضه في العنوان)

  const SearchScreen({super.key, this.specialtyId, this.specialtyName});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  final _searchController = TextEditingController(); // 1. كنترولر للـ TextField

  List<dynamic> _results = []; // 2. قايمة النتايج
  bool _isLoading = false;
  Timer? _debounce; // 3. ده "التايمر" بتاع الـ Autocomplete

  // 4. دالة الـ "Debounce"
  // (دي بتستنى 500ms بعد ما اليوزر يخلص كتابة قبل ما تكلم الـ API)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.length > 2) {
        // (مش بيبحث غير لو كتب 3 حروف أو أكتر)
        _performSearch(query);
      } else {
        setState(() {
          _results = [];
          _isLoading = false;
        });
      }
    });
  }

  // 5. دالة البحث (بتكلم الـ API)
  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final results = await _apiService.autocompleteSearch(
        query,
        specialtyId: widget.specialtyId,
      );
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // 6. --- بناء الـ UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 7. بنحط الـ TextField جوه الـ AppBar
        title: TextField(
          controller: _searchController,
          autofocus: true, // (بيخلي الكيبورد يفتح أول ما الشاشة تفتح)
          decoration: InputDecoration(
            hintText: 'ابحث عن ${widget.specialtyName ?? 'طبيب'}...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.shade600),
          ),
          onChanged: _onSearchChanged, // (بنشغل الدالة مع كل حرف)
        ),
      ),
      body: _buildBody(),
    );
  }

  // 8. بناء "جسم" الشاشة
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      return const Center(
        child: Text(
          'ابدأ الكتابة للبحث...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد نتايج تطابق هذا البحث',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // 9. لو فيه نتايج، بنعرضها
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final doctor = _results[index];
        return _buildResultCard(doctor); // (بنستخدم الكارت الجديد)
      },
    );
  }

  // 10. --- ودجت "كارت النتيجة" (المعدل والأكثر أماناً) ---
  Widget _buildResultCard(Map<String, dynamic> doctor) {
    
    final String photoUrl = (doctor['avatar'] != null && doctor['avatar']['url'] != null)
        ? doctor['avatar']['url']
        : '';
        
    // --- 1. (هنا الكود الجديد) ---
    // بنعرف متغير افتراضي
    String specialtyName = 'أخصائي'; 
    
    // بنتأكد إن الحقل موجود
    if (doctor['specialize'] != null) {
      // 2. بنشيك: هل الحقل ده Map (يعني populated)؟
      if (doctor['specialize'] is Map<String, dynamic> && doctor['specialize']['title'] != null) {
        specialtyName = doctor['specialize']['title'];
      } 
      // (لو هو String، خلاص هنسيبه "أخصائي" زي ما هو
      // لإننا منقدرش نجيب الاسم من الـ ID بس في الشاشة دي)
    }
    // --- نهاية الكود الجديد ---
        
    final String city = doctor['city'] ?? '...';
    
    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
        child: photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
      ),
      title: Text(doctor['name'] ?? 'دكتور'),
      
      // 3. بنستخدم المتغيرات الجديدة
      subtitle: Text('$specialtyName - $city'), 
      
      trailing: const Icon(Icons.keyboard_arrow_left),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorProfileScreen(
              doctorId: doctor['_id'],
            ),
          ),
        );
      },
    );
  }
}
