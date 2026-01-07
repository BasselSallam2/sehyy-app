import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // final String _baseUrl = 'http://localhost:3000/api'; // <-- Local backend for development
  final String _baseUrl =
      'https://dashboard.sehetie.com/api'; // <-- Production backend
  final _storage = const FlutterSecureStorage();

  // --- دوال الـ Headers ---

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('User not authenticated');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, String> _getPublicHeaders() {
    return {'Content-Type': 'application/json; charset=UTF-8'};
  }

  // --- دوال الـ Auth (Signup / Login) ---

  Future<Map<String, dynamic>> signup({
    required String name,
    required String phone,
    required String password,
    required String country,
    required String city,
  }) async {
    final Uri url = Uri.parse('$_baseUrl/user/auth/signup');
    final Map<String, String> body = {
      'name': name,
      'phone': phone,
      'password': password,
      'country': country,
      'city': city,
    };

    try {
      final response = await http.post(
        url,
        headers: _getPublicHeaders(), // <-- Signup ده Public
        body: json.encode(body),
      );
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (response.statusCode == 201) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to create account');
      }
    } catch (e) {
      // 1. دي أهم سطور، هتطبع الإيرور الحقيقي ونوعه
      print("--- FAILED AT: [اسم الدالة، مثلاً getSpecialties] ---");
      print("--- ORIGINAL ERROR: ${e.toString()} ---");
      print("--- ERROR TYPE: ${e.runtimeType} ---");

      // 2. بنرجع رسالة الخطأ الأصلية زي ما هي
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> guestLogin() async {
    final Uri url = Uri.parse('$_baseUrl/user/auth/guest');

    try {
      final response = await http.post(url, headers: _getPublicHeaders());
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to login as guest');
      }
    } catch (e) {
      print("--- FAILED AT: guestLogin ---");
      print("--- ORIGINAL ERROR: ${e.toString()} ---");
      print("--- ERROR TYPE: ${e.runtimeType} ---");

      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final Uri url = Uri.parse('$_baseUrl/user/auth/signin');
    final Map<String, String> body = {'phone': phone, 'password': password};

    try {
      final response = await http.post(
        url,
        headers: _getPublicHeaders(), // <-- Login ده Public
        body: json.encode(body),
      );
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to login');
      }
    } catch (e) {
      // 1. دي أهم سطور، هتطبع الإيرور الحقيقي ونوعه
      print("--- FAILED AT: [اسم الدالة، مثلاً getSpecialties] ---");
      print("--- ORIGINAL ERROR: ${e.toString()} ---");
      print("--- ERROR TYPE: ${e.runtimeType} ---");

      // 2. بنرجع رسالة الخطأ الأصلية زي ما هي
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // --- دوال الـ Public Data (Countries / Cities) ---

  Future<List<String>> fetchCountries() async {
    // (ده Endpoint عام، فبنستخدم Public Headers)
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/country'),
        headers: _getPublicHeaders(),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> countriesData = data['data'] ?? [];
        return countriesData
            .where(
              (item) =>
                  item != null &&
                  item is Map<String, dynamic> &&
                  item.containsKey('country'),
            )
            .map((item) => item['country'].toString())
            .toList();
      } else {
        throw Exception('Failed to load countries');
      }
    } catch (e) {
      // 1. دي أهم سطور، هتطبع الإيرور الحقيقي ونوعه
      print("--- FAILED AT: fetchCountries ---");
      print("--- ORIGINAL ERROR: ${e.toString()} ---");
      print("--- ERROR TYPE: ${e.runtimeType} ---");

      // 2. بنرجع رسالة الخطأ الأصلية زي ما هي
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<List<String>> fetchCities(String country) async {
    // (ده Endpoint عام، فبنستخدم Public Headers)
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/country?country=$country'),
        headers: _getPublicHeaders(),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> countryData = data['data'] ?? [];
        if (countryData.isNotEmpty && countryData[0] != null) {
          final dynamic countryObj = countryData[0];
          if (countryObj is Map<String, dynamic> &&
              countryObj.containsKey('cities')) {
            final List<dynamic> cities = countryObj['cities'] ?? [];
            return cities.map((city) => city.toString()).toList();
          }
        }
        return [];
      } else {
        throw Exception('Failed to load cities');
      }
    } catch (e) {
      // 1. دي أهم سطور، هتطبع الإيرور الحقيقي ونوعه
      print("--- FAILED AT: fetchCities ---");
      print("--- ORIGINAL ERROR: ${e.toString()} ---");
      print("--- ERROR TYPE: ${e.runtimeType} ---");

      // 2. بنرجع رسالة الخطأ الأصلية زي ما هي
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // --- دوال الـ Secure Data (بتحتاج توكين) ---

  Future<List<String>> getUserCities() async {
    // (ده Endpoint آمن، بنستخدم Auth Headers)
    final url = Uri.parse('$_baseUrl/country/user/cities');
    try {
      final response = await http.get(
        url,
        headers: await _getAuthHeaders(), // <-- آمن
      );
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        final List<dynamic> cities = responseData['data']['cities'];
        return cities.map((city) => city.toString()).toList();
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to load user cities',
        );
      }
    } catch (e) {
      print("--- FAILED AT: getSpecialties ---"); // <--- ضيف السطر ده
      // 1. دي أهم سطور، هتطبع الإيرور الحقيقي ونوعه
      print("--- FAILED AT: [اسم الدالة، مثلاً getSpecialties] ---");
      print("--- ORIGINAL ERROR: ${e.toString()} ---");
      print("--- ERROR TYPE: ${e.runtimeType} ---");

      // 2. بنرجع رسالة الخطأ الأصلية زي ما هي
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<List<dynamic>> getSpecialties() async {
    final url = Uri.parse('$_baseUrl/specialize');
    try {
      // Check if user is authenticated (has token)
      final token = await _storage.read(key: 'auth_token');
      final headers = (token != null && token.isNotEmpty)
          ? await _getAuthHeaders() // Use auth headers if authenticated
          : _getPublicHeaders(); // Use public headers for guests

      final response = await http.get(
        url,
        headers: headers, // <-- Dynamic headers based on auth status
      );
      final Map<String, dynamic> data = json.decode(response.body);
      if (response.statusCode == 200) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to load specialties');
      }
    } catch (e) {
      // 1. دي أهم سطور، هتطبع الإيرور الحقيقي ونوعه
      print("--- FAILED AT: getSpecialties ---");
      print("--- ORIGINAL ERROR: ${e.toString()} ---");
      print("--- ERROR TYPE: ${e.runtimeType} ---");

      // 2. بنرجع رسالة الخطأ الأصلية زي ما هي
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 7. دالة جلب البنرات (معدلة لترجع الداتا والـ Pagination)
  Future<Map<String, dynamic>> getBanners({
    String? specialize,
    String? city,
    int page = 1,
    int limit = 3,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (specialize != null && specialize.isNotEmpty) {
      queryParams['specialize'] = specialize;
    }
    if (city != null && city.isNotEmpty) {
      queryParams['city'] = city;
    }

    final url = Uri.parse(
      '$_baseUrl/bunner',
    ).replace(queryParameters: queryParams);
    try {
      // Check if user is authenticated (has token)
      final token = await _storage.read(key: 'auth_token');
      final headers = (token != null && token.isNotEmpty)
          ? await _getAuthHeaders() // Use auth headers if authenticated
          : _getPublicHeaders(); // Use public headers for guests

      final response = await http.get(
        url,
        headers: headers, // <-- Dynamic headers based on auth status
      );

      // 1. دي هي الاستجابة الكاملة من الباك إند
      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200) {
        // 2. بنرجع الداتا والـ pagination مع بعض
        return {
          'data': data['data'], // دي قايمة البنرات
          'pagination': data['pagination'], // دي معلومات الصفحة
        };
      } else {
        throw Exception(data['message'] ?? 'Failed to load banners');
      }
    } catch (e) {
      throw Exception('Connection error: ${e.toString()}');
    }
  }

  // 8. دالة جلب الأطباء (معدلة عشان تعمل populate)
  Future<List<dynamic>> getDoctorsBySpecialty(String specialtyId) async {
    // 1. --- التعديل هنا ---
    // بنجهز الـ query parameters
    final Map<String, String> queryParams = {
      'specialize': specialtyId,
      'populate': '{"path": "specialize"}', // <-- 2. الكود اللي إنت بعته
    };

    // 3. بنبني الـ URL بالـ query parameters
    final url = Uri.parse(
      '$_baseUrl/employee',
    ).replace(queryParameters: queryParams);
    // --- نهاية التعديل ---

    try {
      // Check if user is authenticated (has token)
      final token = await _storage.read(key: 'auth_token');
      final headers = (token != null && token.isNotEmpty)
          ? await _getAuthHeaders() // Use auth headers if authenticated
          : _getPublicHeaders(); // Use public headers for guests

      final response = await http.get(url, headers: headers);

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Failed to load doctors');
      }
    } catch (e) {
      // (ده الكود بتاع الـ debugging اللي عملناه)
      print("--- FAILED AT: getDoctorsBySpecialty ---");
      print("--- ORIGINAL ERROR: ${e.toString()} ---");
      print("--- ERROR TYPE: ${e.runtimeType} ---");
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ... (الكود اللي فوق بتاع getDoctorsBySpecialty) ...

  // 9. دالة جلب تفاصيل دكتور واحد (جديدة)
  Future<Map<String, dynamic>> getDoctorDetails(String doctorId) async {
    // 1. بنعمل populate للـ specialize زي ما اتفقنا
    final Map<String, String> queryParams = {'populate': 'specialize'};
    final url = Uri.parse(
      '$_baseUrl/employee/$doctorId',
    ).replace(queryParameters: queryParams);

    try {
      // Check if user is authenticated (has token)
      final token = await _storage.read(key: 'auth_token');
      final headers = (token != null && token.isNotEmpty)
          ? await _getAuthHeaders() // Use auth headers if authenticated
          : _getPublicHeaders(); // Use public headers for guests

      final response = await http.get(url, headers: headers);

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data['data']; // الـ API بيرجع object
      } else {
        throw Exception(data['message'] ?? 'Failed to load doctor details');
      }
    } catch (e) {
      print("--- FAILED AT: getDoctorDetails ---");
      print("--- ORIGINAL ERROR: ${e.toString()} ---");
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 10. دالة جلب مواعيد الدكتور (جديدة)
  Future<List<dynamic>> getDoctorSlots(String doctorId) async {
    // 1. بنجيب كل المواعيد (ممكن نضيف فلتر تاريخ لو احتجنا)
    final url = Uri.parse('$_baseUrl/slot/$doctorId?sort=date');

    try {
      // Check if user is authenticated (has token)
      final token = await _storage.read(key: 'auth_token');
      final headers = (token != null && token.isNotEmpty)
          ? await _getAuthHeaders() // Use auth headers if authenticated
          : _getPublicHeaders(); // Use public headers for guests

      final response = await http.get(url, headers: headers);

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data['data']; // الـ API بيرجع array of slots
      } else {
        throw Exception(data['message'] ?? 'Failed to load slots');
      }
    } catch (e) {
      print("--- FAILED AT: getDoctorSlots ---");
      print("--- ORIGINAL ERROR: ${e.toString()} ---");
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 11. دالة حجز موعد (جديدة)
  Future<Map<String, dynamic>> bookSlot(
    String slotId, {
    String? bannerId,
  }) async {
    final url = Uri.parse('$_baseUrl/slot/resirve/$slotId'); // (resirve)

    final Map<String, dynamic> body = {
      'reserved': true,
      // (لو فيه بانر بنبعته)
      if (bannerId != null) 'bunner': bannerId,
    };

    try {
      final response = await http.put(
        url,
        headers: await _getAuthHeaders(),
        body: json.encode(body),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to book slot');
      }
    } catch (e) {
      print("--- FAILED AT: bookSlot ---");
      print("--- ORIGINAL ERROR: ${e.toString()} ---");
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ... (الكود اللي فوق بتاع bookSlot) ...

  // 12. دالة البحث (Autocomplete) - جديدة
  Future<List<dynamic>> autocompleteSearch(
    String searchQuery, {
    String? specialtyId,
  }) async {
    // 1. بنجهز الـ query parameters
    final Map<String, String> queryParams = {
      'search': searchQuery,
      // 2. بنعمل populate عشان نجيب اسم التخصص (لو حبينا نعرضه)
      'populate': '{"path": "specialize"}',
    };

    // 3. لو فيه قسم معين، بنضيفه للفلتر
    if (specialtyId != null && specialtyId.isNotEmpty) {
      queryParams['specialize'] = specialtyId;
    }

    final url = Uri.parse(
      '$_baseUrl/employee/autocomplete',
    ).replace(queryParameters: queryParams);

    try {
      // Check if user is authenticated (has token)
      final token = await _storage.read(key: 'auth_token');
      final headers = (token != null && token.isNotEmpty)
          ? await _getAuthHeaders() // Use auth headers if authenticated
          : _getPublicHeaders(); // Use public headers for guests

      final response = await http.get(url, headers: headers);

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data['data']; // الـ API بيرجع array of doctors
      } else {
        throw Exception(data['message'] ?? 'Failed to search');
      }
    } catch (e) {
      print("--- FAILED AT: autocompleteSearch ---");
      print("--- ORIGINAL ERROR: ${e.toString()} ---");
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ... (الكود اللي فوق بتاع bookSlot) ...

  // 12. دالة جلب "كل" عروض الدكتور (جديدة)
  Future<List<dynamic>> getBannersForDoctor(String doctorId) async {
    // 1. بنفلتر الـ "bunner" بالـ "doctor" (زي ما طلبت)
    final Map<String, String> queryParams = {'doctor': doctorId};

    final url = Uri.parse(
      '$_baseUrl/bunner',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(url, headers: await _getAuthHeaders());
      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200) {
        // (بنفترض إنه هيرجع "data" زي باقي الـ Endpoints)
        return data['data']; // بيرجع قايمة البنرات
      } else {
        throw Exception(data['message'] ?? 'Failed to load doctor banners');
      }
    } catch (e) {
      print("--- FAILED AT: getBannersForDoctor ---");
      print("--- ORIGINAL ERROR: ${e.toString()} ---");
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ... (تحت دالة getBannersForDoctor)

  // 13. دالة جلب "كل" حجوزاتي (معدلة لعمل populate)
  Future<List<dynamic>> getMyBookings() async {
    // 1. --- التعديل هنا ---
    final Map<String, String> queryParams = {
      'populate': '{"path": "doctor", "populate": {"path": "specialize"}}',
    };

    final url = Uri.parse(
      '$_baseUrl/slot/myReservations',
    ).replace(queryParameters: queryParams); // <-- 2. بنضيف الفلتر

    // --- نهاية التعديل ---

    try {
      final response = await http.get(
        url,
        headers: await _getAuthHeaders(), // (آمنة)
      );

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data['data']; // (قايمة الحجوزات)
      } else {
        throw Exception(data['message'] ?? 'Failed to load bookings');
      }
    } catch (e) {
      print("--- FAILED AT: getMyBookings ---");
      print("--- ORIGINAL ERROR: ${e.toString()} ---");
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 13. دالة إلغاء الحجز (جديدة)
  Future<void> cancelBooking(String slotId) async {
    final url = Uri.parse('$_baseUrl/slot/unresirve/$slotId');

    // 1. الجسم اللي إنت طلبته بالظبط
    final Map<String, dynamic> body = {
      "reserved": false,
      "patient": null,
      "bunner": null,
    };

    try {
      final response = await http.put(
        url,
        headers: await _getAuthHeaders(), // (لازم يكون عامل لوجن)
        body: json.encode(body),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);

      // (الـ API بتاعك بيرجع 200 OK)
      if (response.statusCode != 200) {
        throw Exception(responseData['message'] ?? 'Failed to cancel booking');
      }
      // (نجح)
    } catch (e) {
      print("--- FAILED AT: cancelBooking ---");
      print("--- ORIGINAL ERROR: ${e.toString()} ---");
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
} // <--- نهاية الكلاس
