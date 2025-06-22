import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api/v1/user';

  // 🔐 LOGIN
  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      return true;
    } else {
      print('Login failed: ${response.body}');
      return false;
    }
  }

  // 📝 SIGNUP
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

  // 👤 GET USER PROFILE
  Future<Map<String, dynamic>?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('❌ Failed to load profile: ${response.body}');
      return null;
    }
  }

  // 🚪 LOGOUT
  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // 🚗 GET VEHICLES
  Future<List<String>> getVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/vehicles'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => item['license_plate'].toString()).toList();
    } else {
      print('Failed to load vehicles: ${response.body}');
      throw Exception('Failed to load vehicles');
    }
  }

  // 🛠️ GET SERVICE TYPES
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
    } else {
      print('Failed to load service types: ${response.body}');
      throw Exception('Failed to load service types');
    }
  }

  // 📅 BOOK SERVICE
  Future<bool> bookService(Map<String, dynamic> bookingData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/book-service'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(bookingData),
    );

    print('Book service response: ${response.statusCode}, ${response.body}');

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Failed to book service: ${response.body}');
      return false;
    }
  }

  // 📜 GET MAINTENANCE HISTORY
  Future<List<Map<String, dynamic>>> getMaintenanceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/maintenance-history'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((item) => {
                'license_plate': item['license_plate'].toString(),
                'service_record_id': item['service_record_id'].toString(),
                'service_description':
                    item['service_description']?.toString() ?? 'N/A',
                'price': item['price']?.toString() ?? 'N/A',
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
    } else {
      print('Failed to load maintenance history: ${response.body}');
      throw Exception('Failed to load maintenance history');
    }
  }

  // 📊 GET CURRENT SERVICE STATUS
  Future<List<Map<String, dynamic>>> getCurrentServiceStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/current-service-status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
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
                'price': item['price']?.toString() ?? '0.0',
                'is_paid': item['is_paid']?.toString() ?? 'false',
                'service_record_id': item['service_record_id']?.toString(),
              })
          .toList();
    } else {
      print('Failed to load current service status: ${response.body}');
      throw Exception('Failed to load current service status');
    }
  }
}
