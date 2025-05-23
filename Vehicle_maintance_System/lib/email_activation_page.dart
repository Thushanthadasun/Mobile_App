import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EmailActivationPage extends StatefulWidget {
  final String token;
  const EmailActivationPage({Key? key, required this.token}) : super(key: key);

  @override
  State<EmailActivationPage> createState() => _EmailActivationPageState();
}

class _EmailActivationPageState extends State<EmailActivationPage> {
  String message = "🔄 Verifying your email...";

  @override
  void initState() {
    super.initState();
    verifyEmail();
  }

  Future<void> verifyEmail() async {
    print("📦 Received token in Flutter: ${widget.token}");

    try {
      final response = await http.get(Uri.parse(
        'http://localhost:5000/api/v1/user/emailverify?token=${widget.token}',
      ));

      if (response.statusCode == 200) {
        setState(() {
          message = "✅ Email verified successfully!";
        });

        // Auto-redirect to login after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
      } else {
        setState(() {
          message = "❌ Verification failed:\n${response.body}";
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
        title: const Text("Email Verification"),
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
