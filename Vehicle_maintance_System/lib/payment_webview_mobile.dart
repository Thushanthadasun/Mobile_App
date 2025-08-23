import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebView extends StatefulWidget {
  final String actionUrl;
  final Map<String, String> fields;

  const PaymentWebView(
      {super.key, required this.actionUrl, required this.fields});

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _loading = true;

  String _html() {
    final inputs = widget.fields.entries.map((e) {
      final n = const HtmlEscape().convert(e.key);
      final v = const HtmlEscape().convert(e.value);
      return '<input type="hidden" name="$n" value="$v" />';
    }).join();
    return '''
<!doctype html><html><body onload="document.forms[0].submit();">
<form method="post" action="${widget.actionUrl}">
$inputs
<noscript><button type="submit">Continue</button></noscript>
</form></body></html>''';
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
      ))
      ..loadHtmlString(_html());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Secure Payment')),
      body: Stack(children: [
        WebViewWidget(controller: _controller),
        if (_loading) const Center(child: CircularProgressIndicator()),
      ]),
    );
  }
}
