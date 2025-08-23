// lib/payment_webview.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:html' as html;

class PaymentWebView extends StatelessWidget {
  final String actionUrl;
  final Map<String, String> fields;

  const PaymentWebView({
    super.key,
    required this.actionUrl,
    required this.fields,
  });

  String _html() {
    final inputs = fields.entries.map((e) {
      final n = const HtmlEscape().convert(e.key);
      final v = const HtmlEscape().convert(e.value);
      return '<input type="hidden" name="$n" value="$v" />';
    }).join();
    return '''
<!doctype html><html><body onload="document.forms[0].submit();">
<form method="post" action="$actionUrl">
$inputs
<noscript><button type="submit">Continue</button></noscript>
</form></body></html>''';
  }

  @override
  Widget build(BuildContext context) {
    final htmlContent = _html();
    final blob = html.Blob([htmlContent], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);

    // 👉 opens PayHere checkout in a new browser tab
    html.window.open(url, "_blank");

    return const Scaffold(
      body: Center(child: Text("Redirecting to Payment...")),
    );
  }
}

/*import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:html' as html;

class PaymentWebView extends StatelessWidget {
  final String actionUrl;
  final Map<String, String> fields;

  const PaymentWebView(
      {super.key, required this.actionUrl, required this.fields});

  String _html() {
    final inputs = fields.entries.map((e) {
      final n = const HtmlEscape().convert(e.key);
      final v = const HtmlEscape().convert(e.value);
      return '<input type="hidden" name="$n" value="$v" />';
    }).join();
    return '''
<!doctype html><html><body onload="document.forms[0].submit();">
<form method="post" action="$actionUrl">
$inputs
<noscript><button type="submit">Continue</button></noscript>
</form></body></html>''';
  }

  @override
  Widget build(BuildContext context) {
    // For Flutter Web: open PayHere checkout in new tab
    final htmlContent = _html();
    final blob = html.Blob([htmlContent], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, "_blank");

    return const Scaffold(
      body: Center(child: Text("Redirecting to Payment...")),
    );
  }
}
*/
