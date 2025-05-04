import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EmailActivationPage extends StatefulWidget {
  final String token;
  const EmailActivationPage({Key? key, required this.token}) : super(key: key);

  @override
  _EmailActivationPageState createState() => _EmailActivationPageState();
}

class _EmailActivationPageState extends State<EmailActivationPage> {
  String message = "Verifying email...";

  @override
  void initState() {
    super.initState();
    verifyEmail();
  }

  Future<void> verifyEmail() async {
    final response = await http.get(Uri.parse(
      'http://192.168.1.147:5000/api/v1/user/emailVerify?token=${widget.token}',
    ));

    if (response.statusCode == 200) {
      setState(() {
        message = "✅ Email verified successfully!";
      });
    } else {
      setState(() {
        message = "❌ Verification failed: ${response.body}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Email Verification")),
      body: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
