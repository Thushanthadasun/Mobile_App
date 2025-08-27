import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  /// Your backend base for user routes
  /// (server expects: /api/v1/user/…)
  static const String baseUrl = 'http://localhost:5000/api/v1/user';

  // ---------------------------
  // Helpers
  // ---------------------------

  /// Read the saved JWT from SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Build headers including Authorization when token exists
  static Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ---------------------------
  // Auth
  // ---------------------------

  /// 🔐 Login and persist token
  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    print('📥 Login response: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String?;

      if (token == null) {
        print('❌ No token in response');
        return false;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      return true;
    }
    print('❌ Login failed: ${response.body}');
    return false;
  }

  /// 📝 Signup (returns true on 201/200)
  Future<bool> signup(Map<String, dynamic> userData) async {
    print('Sending signup data: $userData');
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    return response.statusCode == 201 || response.statusCode == 200;
  }

  /// 🚪 Logout (clears stored token)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // ---------------------------
  // Profile
  // ---------------------------

  /// 👤 Get user profile (fname, lname, email, mobile, etc.)
  Future<Map<String, dynamic>?> getUserProfile() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/authUser'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'fname': data['fname']?.toString() ?? '',
        'lname': data['lname']?.toString() ?? '',
        'email': data['email']?.toString() ?? '',
        'mobile': data['mobile']?.toString() ?? '',
        'nicno': data['nicno']?.toString() ?? '',
        'address_line1': data['address_line1']?.toString() ?? '',
        'address_line2': data['address_line2']?.toString() ?? '',
        'address_line3': data['address_line3']?.toString() ?? '',
      };
    }
    print('❌ Failed to load profile: ${response.body}');
    return null;
  }

  /// ✉️ Update email immediately (server will send info email, no link)
  Future<bool> updateEmail(String newEmail) async {
    final headers = await _authHeaders();
    final res = await http.put(
      Uri.parse('$baseUrl/profile/email'),
      headers: headers,
      body: jsonEncode({'email': newEmail}),
    );
    if (res.statusCode == 200) return true;
    print('❌ updateEmail failed: ${res.statusCode} ${res.body}');
    return false;
  }

  /// 📱 Update contact number immediately (server will send info email)
  Future<bool> updateContact(String newMobile) async {
    final headers = await _authHeaders();
    final res = await http.put(
      Uri.parse('$baseUrl/profile/contact'),
      headers: headers,
      body: jsonEncode({'mobile': newMobile}),
    );
    if (res.statusCode == 200) return true;
    print('❌ updateContact failed: ${res.statusCode} ${res.body}');
    return false;
  }

  // ---------------------------
  // Vehicles & Services
  // ---------------------------

  /// 🚗 List user vehicles (returns license plates)
  Future<List<String>> getVehicles() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/vehicles'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => item['license_plate'].toString()).toList();
    }
    print('Failed to load vehicles: ${response.body}');
    throw Exception('Failed to load vehicles');
  }

  /// 💳 Create payment for a reservation (kept from your original code)
  Future<Map<String, dynamic>> createPayment(int reservationId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/../payments/create'), // -> /api/v1/payments/create
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'reservation_id': reservationId}),
    );
    if (res.statusCode == 200)
      return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Create payment failed: ${res.body}');
  }

  /// 🛠️ Service types
  Future<List<Map<String, String>>> getServiceTypes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/loadServiceTypes'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((item) => {
                'service_type_id': item['service_type_id'].toString(),
                'title': item['service_name'].toString(),
                'description': item['description'].toString(),
              })
          .toList();
    }
    print('Failed to load service types: ${response.body}');
    throw Exception('Failed to load service types');
  }

  /// 📅 Book service
  Future<bool> bookService(Map<String, dynamic> bookingData) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/book-service'),
      headers: headers,
      body: jsonEncode(bookingData),
    );

    print('Book service response: ${response.statusCode}, ${response.body}');
    if (response.statusCode == 200) return true;

    print('Failed to book service: ${response.body}');
    return false;
  }

  /// 📜 Maintenance history
  Future<List<Map<String, dynamic>>> getMaintenanceHistory() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/maintenance-history'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((item) => {
                'license_plate': item['license_plate'].toString(),
                'service_record_id': item['service_record_id'].toString(),
                'service_description':
                    item['service_description']?.toString() ?? 'N/A',
                'final_amount': item['final_amount']?.toString() ?? 'N/A',
                'created_datetime':
                    item['created_datetime']?.toString() ?? 'N/A',
                'is_paid': item['is_paid']?.toString() ?? 'N/A',
                'reserve_date': item['reserve_date']?.toString() ?? 'N/A',
                'start_time': item['start_time']?.toString() ?? 'N/A',
                'end_time': item['end_time']?.toString() ?? 'N/A',
                'notes': item['notes']?.toString() ?? 'N/A',
                'service_name': item['service_name']?.toString() ?? 'N/A',
              })
          .toList();
    }
    print('Failed to load maintenance history: ${response.body}');
    throw Exception('Failed to load maintenance history');
  }

  /// 📊 Current service status
  Future<List<Map<String, dynamic>>> getCurrentServiceStatus() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/current-service-status'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print('Raw API response for current-service-status: $data');
      return data
          .where((item) =>
              item['reserve_date'] != null &&
              item['start_time'] != null &&
              item['end_time'] != null)
          .map((item) => {
                'reservation_id': item['reservation_id'].toString(),
                'license_plate': item['license_plate'].toString(),
                'service_name': item['service_name'].toString(),
                'reserve_date': item['reserve_date'].toString().contains('T')
                    ? item['reserve_date'].toString().split('T')[0]
                    : item['reserve_date'].toString(),
                'start_time': item['start_time'].toString(),
                'end_time': item['end_time'].toString(),
                'duration': item['duration'].toString(),
                'status': item['status_name'].toString(),
                'final_amount': item['final_amount']?.toString() ?? '0.0',
                'is_paid': item['is_paid']?.toString() ?? 'false',
                'service_record_id': item['service_record_id']?.toString(),
              })
          .toList();
    }
    print('Failed to load current service status: ${response.body}');
    throw Exception('Failed to load current service status');
  }
}
