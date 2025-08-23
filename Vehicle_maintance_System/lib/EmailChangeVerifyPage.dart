import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EmailChangeVerifyPage extends StatefulWidget {
  const EmailChangeVerifyPage({Key? key}) : super(key: key);

  @override
  State<EmailChangeVerifyPage> createState() => _EmailChangeVerifyPageState();
}

class _EmailChangeVerifyPageState extends State<EmailChangeVerifyPage> {
  String message = "🔄 Verifying email change...";
  bool verified = false;

  @override
  void initState() {
    super.initState();
    final token = Uri.base.queryParameters['token'];
    if (token != null && token.isNotEmpty) {
      verifyEmailChange(token);
    } else {
      setState(() {
        message = "❌ Invalid verification link";
      });
    }
  }

  Future<void> verifyEmailChange(String token) async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:5000/api/v1/user/email-change-verify?token=$token"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          message = "✅ Your email has been successfully updated!";
          verified = true;
        });
      } else {
        setState(() {
          message = "❌ Verification failed: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        message = "⚠️ Error occurred: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Email Change Verification")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                verified ? Icons.check_circle_outline : Icons.email_outlined,
                color: verified ? Colors.green : Colors.blue,
                size: 72,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              if (verified)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text("Go to Login"),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
