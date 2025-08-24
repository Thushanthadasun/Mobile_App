import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:car_service_app/api_service.dart';

class PasswordResetConfirmationPage extends StatefulWidget {
  final String token;
  const PasswordResetConfirmationPage({Key? key, required this.token}) : super(key: key);

  @override
  State<PasswordResetConfirmationPage> createState() => _PasswordResetConfirmationPageState();
}

class _PasswordResetConfirmationPageState extends State<PasswordResetConfirmationPage> {
  String message = "🔄 Confirming password reset...";

  @override
  void initState() {
    super.initState();
    confirmPasswordReset();
  }

  Future<void> confirmPasswordReset() async {
    try {
      final String apiUrl = ApiService.baseUrl + '/confirm-password-reset?token=${widget.token}';
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        setState(() {
          message = "✅ Password reset successfully!";
        });

        // Auto-redirect to login after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
      } else {
        setState(() {
          message = "❌ Password reset failed:\n${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        message = "❌ Error contacting server:\n$e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Password Reset Confirmation"),
        backgroundColor: Colors.red.withOpacity(0.8),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.withOpacity(0.2), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}