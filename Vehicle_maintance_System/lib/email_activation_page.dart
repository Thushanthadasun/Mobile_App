import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Keep ONE clear root for your API, without a trailing slash.
const String apiRoot = 'http://localhost:5000/api/v1';

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
    final String url =
        '$apiRoot/user/emailverify?token=${Uri.encodeComponent(widget.token)}';
    print('VERIFY → GET $url');

    try {
      final res = await http.get(Uri.parse(url));
      print('VERIFY ← ${res.statusCode} ${res.body}');

      if (res.statusCode == 200) {
        setState(() => message = "✅ Email verified successfully!");
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
        });
      } else {
        final body = res.body.isNotEmpty ? res.body : 'No body';
        setState(() => message = "❌ Verification failed:\n$body");
      }
    } catch (e) {
      setState(() => message = "❌ Network error:\n$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Email Verification"),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
