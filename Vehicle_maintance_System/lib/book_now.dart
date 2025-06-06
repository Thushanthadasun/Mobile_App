import 'package:flutter/material.dart';

class BookNow extends StatefulWidget {
  const BookNow({super.key});

  @override
  _BookNowState createState() => _BookNowState();
}

class _BookNowState extends State<BookNow> {
  bool _isPaymentCompleted = false;

  Future<Map<String, dynamic>> _fetchServiceStatus() async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'hasActiveBooking': true,
      'estimatedTime': 120,
      'progressPercentage': 75,
      'totalCost': 150.0,
    };
  }

  void _handlePayment(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment'),
        content: const Text('Processing payment of \$150.00... (Placeholder)'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isPaymentCompleted = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment completed successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Confirm Payment'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Service'),
        backgroundColor: Colors.red,
      ),
      body: Container(
        decoration: const BoxDecoration( // CHANGE: Fixed 'Hannah' to 'decoration'
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red,
              Colors.white,
            ],
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<Map<String, dynamic>>(
                          future: _fetchServiceStatus(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return const Text('Error loading service status', style: TextStyle(color: Colors.red));
                            } else if (snapshot.hasData) {
                              final data = snapshot.data!;
                              if (!data['hasActiveBooking']) {
                                return Text('No active bookings found', style: TextStyle(color: Colors.grey[600]));
                              }
                              final estimatedTime = data['estimatedTime'] as int;
                              final progressPercentage = data['progressPercentage'] as int;
                              final totalCost = data['totalCost'] as double;
                              final remainingTime = (estimatedTime * (1 - progressPercentage / 100)).round();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Estimated Time: ${estimatedTime ~/ 60}h ${estimatedTime % 60}m', style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 10),
                                  Text('Total Cost: \$${totalCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Progress: $progressPercentage%', style: const TextStyle(fontSize: 16)),
                                      Text(
                                        progressPercentage == 100 ? 'Completed' : '$remainingTime min remaining',
                                        style: TextStyle(fontSize: 16, color: progressPercentage == 100 ? Colors.green : Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  LinearProgressIndicator(
                                    value: progressPercentage / 100,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                                  ),
                                  const SizedBox(height: 10),
                                  if (_isPaymentCompleted)
                                    const Text('Payment Completed', style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold))
                                  else
                                    ElevatedButton(
                                      onPressed: progressPercentage == 100 ? null : () => _handlePayment(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        minimumSize: const Size(100, 40),
                                      ),
                                      child: const Text('Pay Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              );
                            }
                            return Text('No data available', style: TextStyle(color: Colors.grey[600]));
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Special Offers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        OfferItem(
                          title: 'Annual Service Discount',
                          description: '20% off on complete car checkup',
                          validUntil: 'Valid until April 15, 2025',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterServicePage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('REGISTER FOR SERVICE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OfferItem extends StatelessWidget {
  final String title;
  final String description;
  final String validUntil;

  const OfferItem({super.key, required this.title, required this.description, required this.validUntil});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(description),
          const SizedBox(height: 2),
          Text(validUntil, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

class RegisterServicePage extends StatefulWidget {
  final String? preSelectedService;

  const RegisterServicePage({super.key, this.preSelectedService});

  @override
  _RegisterServicePageState createState() => _RegisterServicePageState();
}

class _RegisterServicePageState extends State<RegisterServicePage> {
  final _formKey = GlobalKey<FormState>();
  String vehicleNumber = '';
  final List<String> selectedServices = [];
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  final List<Map<String, String>> services = [
    {"title": "Mechanical Repair", "short_description": "Fixing mechanical issues with precision."},
    {"title": "Collision Repair", "short_description": "Restoring vehicles after accidents."},
    {"title": "Lubricant Services", "short_description": "Essential lubrication for engine longevity."},
    {"title": "Interior Services", "short_description": "Keeping your car's interior spotless."},
    {"title": "Exterior Services", "short_description": "Polishing and protecting your car's body."},
    {"title": "Engine Tune-up", "short_description": "Enhancing engine performance and efficiency."},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedService != null && services.any((service) => service['title'] == widget.preSelectedService)) {
      selectedServices.add(widget.preSelectedService!);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Service'),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Vehicle Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Vehicle Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vehicle number';
                  }
                  return null;
                },
                onSaved: (value) {
                  vehicleNumber = value!;
                },
              ),
              const SizedBox(height: 20),
              const Text('Select Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  final isChecked = selectedServices.contains(service['title']);
                  return CheckboxListTile(
                    title: Text(service['title']!),
                    subtitle: Text(service['short_description']!),
                    value: isChecked,
                    activeColor: Colors.red,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedServices.add(service['title']!);
                        } else {
                          selectedServices.remove(service['title']);
                        }
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text('Preferred Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Select Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                ),
              ),
              const SizedBox(height: 15),
              InkWell(
                onTap: () => _selectTime(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Select Time',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  child: Text("${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}"),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (selectedServices.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select at least one service'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    _formKey.currentState!.save();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Booking registered successfully for: ${selectedServices.join(', ')}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text('SUBMIT BOOKING', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}