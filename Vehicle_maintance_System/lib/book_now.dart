import 'package:flutter/material.dart';
import 'package:car_service_app/api_service.dart';
import 'package:intl/intl.dart';

class BookNow extends StatefulWidget {
  const BookNow({super.key});

  @override
  _BookNowState createState() => _BookNowState();
}

class _BookNowState extends State<BookNow> {
  final Set<String> _paidServiceRecords = {};

  Future<List<Map<String, dynamic>>> _fetchServiceStatus() async {
    final apiService = ApiService();
    return await apiService.getCurrentServiceStatus();
  }

  void _handlePayment(BuildContext context, String serviceRecordId, double price) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment'),
        content: Text('Processing payment of \$${price.toStringAsFixed(2)}... (Placeholder)'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _paidServiceRecords.add(serviceRecordId);
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

  // Helper function to parse date and time safely
  DateTime? _parseDateTime(String date, String time) {
    try {
      // Handle ISO 8601 format (e.g., '2025-06-10T18:30:00.000Z')
      String normalizedDate = date;
      if (date.contains('T')) {
        normalizedDate = date.split('T')[0];
      }

      // Normalize date format (e.g., '2025-5-25' -> '2025-05-25')
      final dateParts = normalizedDate.split('-');
      if (dateParts.length == 3) {
        normalizedDate = '${dateParts[0]}-${dateParts[1].padLeft(2, '0')}-${dateParts[2].padLeft(2, '0')}';
      }

      // Normalize time format (e.g., '9:00' -> '09:00:00', or remove milliseconds)
      String normalizedTime = time;
      if (time.contains('.')) {
        normalizedTime = time.split('.')[0];
      }
      final timeParts = normalizedTime.split(':');
      if (timeParts.length >= 2) {
        normalizedTime = '${timeParts[0].padLeft(2, '0')}:${timeParts[1].padLeft(2, '0')}:${timeParts.length > 2 ? timeParts[2] : '00'}';
      }

      final dateTimeString = '$normalizedDate $normalizedTime';
      print('Parsing DateTime: $dateTimeString');
      return DateTime.parse(dateTimeString);
    } catch (e) {
      print('Error parsing DateTime: $date $time, Error: $e');
      return null;
    }
  }

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
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _fetchServiceStatus(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              print('FutureBuilder Error: ${snapshot.error}');
                              return const Text('Error loading service status', style: TextStyle(color: Colors.red));
                            } else if (snapshot.hasData) {
                              // Filter out paid services
                              final services = snapshot.data!.where((service) {
                                final isPaid = service['is_paid'].toLowerCase() == 'true' || _paidServiceRecords.contains(service['service_record_id']);
                                return !isPaid;
                              }).toList();
                              if (services.isEmpty) {
                                return Text('No active or pending services found', style: TextStyle(color: Colors.grey[600]));
                              }
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: services.length,
                                itemBuilder: (context, index) {
                                  final service = services[index];
                                  print('Processing service: $service');
                                  final isPending = service['status'] == 'Pending';
                                  final isOngoing = service['status'] == 'Ongoing';
                                  final isCompleted = service['status'] == 'Completed';
                                  final duration = int.tryParse(service['duration']?.toString() ?? '0') ?? 0;
                                  final price = double.tryParse(service['price']?.toString() ?? '0.0') ?? 0.0;
                                  final startTime = service['start_time']?.toString() ?? '';
                                  final endTime = service['end_time']?.toString() ?? '';
                                  final reserveDate = service['reserve_date']?.toString() ?? '';
                                  final serviceRecordId = service['service_record_id']?.toString() ?? '';

                                  // Parse date and time
                                  final startDateTime = _parseDateTime(reserveDate, startTime);
                                  final endDateTime = _parseDateTime(reserveDate, endTime);

                                  // Skip rendering if date parsing fails
                                  if (startDateTime == null || endDateTime == null) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8.0),
                                      child: Text('Invalid service date/time data', style: TextStyle(color: Colors.red)),
                                    );
                                  }

                                  // Calculate progress based on allocated time
                                  double progress = 0.0;
                                  final now = DateTime.now();
                                  
                                  if (isCompleted) {
                                    progress = 1.0;
                                  } else if (isOngoing) {
                                    // Check if current time is within the service window
                                    if (now.isAfter(startDateTime) && now.isBefore(endDateTime)) {
                                      final totalServiceDuration = endDateTime.difference(startDateTime).inMinutes;
                                      final elapsedTime = now.difference(startDateTime).inMinutes;
                                      progress = totalServiceDuration > 0 ? (elapsedTime / totalServiceDuration).clamp(0.0, 1.0) : 0.0;
                                    } else if (now.isAfter(endDateTime)) {
                                      // Service should be completed but status hasn't updated yet
                                      progress = 1.0;
                                    }
                                  } else if (isPending) {
                                    progress = 0.0;
                                  }
                                  
                                  final progressPercentage = (progress * 100).round();
                                  final totalServiceDuration = endDateTime.difference(startDateTime).inMinutes;
                                  final remainingTime = ((1 - progress) * totalServiceDuration).round();

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Vehicle: ${service['license_plate']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        Text('Service: ${service['service_name']}', style: const TextStyle(fontSize: 16)),
                                        Text('Date: $reserveDate', style: const TextStyle(fontSize: 16)),
                                        Text('Time: $startTime - $endTime', style: const TextStyle(fontSize: 16)),
                                        Text('Total Cost: \$${price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Progress: $progressPercentage%', style: const TextStyle(fontSize: 16)),
                                            Text(
                                              isCompleted
                                                  ? 'Completed'
                                                  : isOngoing
                                                      ? '$remainingTime min remaining'
                                                      : 'Pending',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: isCompleted ? Colors.green : Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: Colors.grey[300],
                                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                                        ),
                                        const SizedBox(height: 10),
                                        if (isCompleted && serviceRecordId.isNotEmpty)
                                          Center(
                                            child: ElevatedButton(
                                              onPressed: () => _handlePayment(context, serviceRecordId, price),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                minimumSize: const Size(100, 40),
                                              ),
                                              child: const Text('Pay Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        const Divider(height: 20),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }
                            return Text('No data available', style: TextStyle(color: Colors.grey[600]));
                          },
                        ),
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
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterServicePage()));
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
  String? vehicleNumber;
  final List<String> selectedServices = [];
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
  List<String> vehicles = [];
  List<Map<String, String>> services = [];
  bool isLoading = true;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final apiService = ApiService();
      final fetchedVehicles = await apiService.getVehicles();
      final fetchedServices = await apiService.getServiceTypes();
      setState(() {
        vehicles = fetchedVehicles;
        services = fetchedServices;
        vehicleNumber = vehicles.isNotEmpty ? vehicles[0] : null;
        isLoading = false;
        if (widget.preSelectedService != null) {
          final matchedService = services.firstWhere(
            (service) => service['title']!.toLowerCase() == widget.preSelectedService!.toLowerCase(),
            orElse: () => <String, String>{},
          );
          if (matchedService.isNotEmpty) {
            selectedServices.add(matchedService['title']!);
          }
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
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
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (_formKey.currentState!.validate()) {
      if (selectedServices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a service'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (vehicleNumber == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a vehicle'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final bookingData = {
        'vehicleNumber': vehicleNumber,
        'services': selectedServices,
        'preferredDate': DateFormat('yyyy-MM-dd').format(selectedDate),
        'preferredTime': selectedTime.format(context),
        'notes': _notesController.text.trim(),
      };

      final success = await ApiService().bookService(bookingData);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking registered successfully for: ${selectedServices.join(', ')}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This time slot is not available for booking'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Register Service'),
          backgroundColor: Colors.red,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
              DropdownButtonFormField<String>(
                value: vehicleNumber,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car),
                ),
                items: vehicles.map((vehicle) {
                  return DropdownMenuItem<String>(
                    value: vehicle,
                    child: Text(vehicle),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    vehicleNumber = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a vehicle';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('Select Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    subtitle: Text(service['description']!),
                    value: isChecked,
                    activeColor: Colors.red,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedServices.clear();
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
                  child: Text(selectedTime.format(context)),
                ),
              ),
              const SizedBox(height: 15),
              const Text('Additional Notes (Optional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                  hintText: 'Enter any additional notes (optional)',
                ),
                maxLines: 3,
                maxLength: 500,
                validator: (value) {
                  if (value != null && value.length > 500) {
                    return 'Notes cannot exceed 500 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('SUBMIT BOOKING', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}