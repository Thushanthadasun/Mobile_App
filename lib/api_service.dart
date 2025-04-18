import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ✅ Use your actual IP address found from ipconfig
  static const String baseUrl = 'http://192.168.1.182:8080/api/v1/user';

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

      final token = data['token']; // ✅ Make sure your backend returns 'token'
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      return true;
    } else {
      print("Login failed: ${response.body}");
      return false;
    }
  }

  // 📝 SIGNUP
  Future<bool> signup(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

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
      print("Failed to load profile: ${response.body}");
      return null;
    }
  }

  // 🚪 LOGOUT
  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
