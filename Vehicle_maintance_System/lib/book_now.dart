import 'package:flutter/material.dart';
import 'package:car_service_app/api_service.dart';
import 'package:intl/intl.dart';
import 'payment_webview.dart';

class BookNow extends StatefulWidget {
  const BookNow({super.key});

  @override
  _BookNowState createState() => _BookNowState();
}

class _BookNowState extends State<BookNow> {
  final Set<String> _paidServiceRecords = {};
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> _fetchServiceStatus() async {
    return await _api.getCurrentServiceStatus();
  }

  // ---- Payment Handler ----
  void _handlePayment(
      BuildContext context, String reservationIdStr, double price) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment'),
        content: Text('Do you want to pay Rs ${price.toStringAsFixed(2)} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final reservationId = int.tryParse(reservationIdStr);
              await _startPayHerePayment(context, reservationId, price);
            },
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }

  // ---- Start PayHere ----
  Future<void> _startPayHerePayment(
    BuildContext context,
    int? reservationId,
    double finalAmount,
  ) async {
    if (reservationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid reservation id')),
      );
      return;
    }
    if (finalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Final amount not set yet')),
      );
      return;
    }

    try {
      // 1) Ask backend for PayHere payload
      final payload = await _api.createPayment(reservationId);
      final actionUrl = payload['action'] as String;
      final fields = Map<String, String>.from(payload['fields'] as Map);

      // 2) Open PayHere checkout (auto-posts the form)
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PaymentWebView(actionUrl: actionUrl, fields: fields),
      ));

      // 3) After returning, refresh UI (IPN will flip is_paid=true on server)
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Payment flow finished. Updating status...')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment error: $e')),
      );
    }
  }

  // ---- Safe date parsing (kept for future use) ----
  DateTime? _parseDateTime(String date, String time) {
    try {
      String normalizedDate = date.contains('T') ? date.split('T')[0] : date;
      final dateParts = normalizedDate.split('-');
      if (dateParts.length == 3) {
        normalizedDate =
            '${dateParts[0]}-${dateParts[1].padLeft(2, '0')}-${dateParts[2].padLeft(2, '0')}';
      }

      String normalizedTime = time.contains('.') ? time.split('.')[0] : time;
      final timeParts = normalizedTime.split(':');
      if (timeParts.length >= 2) {
        normalizedTime =
            '${timeParts[0].padLeft(2, '0')}:${timeParts[1].padLeft(2, '0')}:${timeParts.length > 2 ? timeParts[2] : '00'}';
      }

      return DateTime.parse('$normalizedDate $normalizedTime');
    } catch (e) {
      // ignore parse errors for UI
      return null;
    }
  }

  // ---- UI ----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Service'),
        backgroundColor: Colors.red,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Service Status',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: _fetchServiceStatus(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return const Text(
                                      'Error loading service status',
                                      style: TextStyle(color: Colors.red));
                                } else if (snapshot.hasData) {
                                  // Hide already paid
                                  final services =
                                      snapshot.data!.where((service) {
                                    final bool isPaid =
                                        (service['is_paid'] == true) ||
                                            (service['is_paid']
                                                    ?.toString()
                                                    .toLowerCase() ==
                                                'true') ||
                                            _paidServiceRecords.contains(
                                                service['service_record_id']);
                                    return !isPaid;
                                  }).toList();

                                  if (services.isEmpty) {
                                    return Text(
                                        'No active or pending services found',
                                        style:
                                            TextStyle(color: Colors.grey[600]));
                                  }

                                  return ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: services.length,
                                    itemBuilder: (context, index) {
                                      final s = services[index];

                                      final serviceRecordId =
                                          s['service_record_id']?.toString() ??
                                              '';
                                      final reservationIdStr = s[
                                              'reservation_id']
                                          ?.toString(); // << use this for payments
                                      final price = double.tryParse(
                                              s['final_amount']?.toString() ??
                                                  '0.0') ??
                                          0.0;

                                      final reserveDate =
                                          s['reserve_date']?.toString() ?? '';
                                      final startTime =
                                          s['start_time']?.toString() ?? '';
                                      final endTime =
                                          s['end_time']?.toString() ?? '';

                                      // (optional) parse if you want to compute progress
                                      _parseDateTime(reserveDate, startTime);
                                      _parseDateTime(reserveDate, endTime);

                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    'Vehicle: ${s['license_plate']}',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Text(
                                                    'Service: ${s['service_name']}'),
                                                Text('Date: $reserveDate'),
                                                Text(
                                                    'Time: $startTime - $endTime'),
                                                Text(
                                                    'Total Cost: Rs ${price.toStringAsFixed(2)}'),
                                                const SizedBox(height: 10),
                                                if ((reservationIdStr ??
                                                        serviceRecordId)
                                                    .isNotEmpty)
                                                  Center(
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        // Prefer reservation_id; fallback to service_record_id if needed
                                                        final idForPayment =
                                                            reservationIdStr ??
                                                                serviceRecordId;
                                                        _handlePayment(
                                                            context,
                                                            idForPayment,
                                                            price);
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                      child:
                                                          const Text('Pay Now'),
                                                    ),
                                                  ),
                                              ]),
                                        ),
                                      );
                                    },
                                  );
                                }
                                return const Text('No data available');
                              },
                            ),
                          ]),
                    ),
                  ),
                ]),
          ),
        ),
      ),
    );
  }
}
