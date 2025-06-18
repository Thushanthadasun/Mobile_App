import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({super.key});

  @override
  _MyProfileState createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  String userName = 'John Doe';
  String contactNumber = '+1 555-123-4567';
  String email = 'john.doe@example.com';

  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _maintenanceHistory = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final ApiService _apiService = ApiService();

  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _verificationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await Future.wait([
        _fetchVehicles(),
        _fetchMaintenanceHistory(),
      ]);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching data: $e';
      });
    }
  }

  Future<void> _fetchVehicles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please log in to view your vehicles';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:5000/api/v1/user/vehicles'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('Vehicle API Response status: ${response.statusCode}');
      print('Vehicle API Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> vehicles = jsonDecode(response.body);
        print('Parsed vehicles: $vehicles');
        setState(() {
          _vehicles = vehicles.map((vehicle) {
            String imgPath = vehicle['imgpath']?.toString() ?? '';
            String? finalImageUrl;

            if (imgPath.isNotEmpty) {
              if (imgPath.startsWith('http')) {
                finalImageUrl = imgPath;
              } else if (imgPath.startsWith('/')) {
                finalImageUrl = 'http://localhost:5000$imgPath';
              } else {
                finalImageUrl = 'http://localhost:5000/uploads/$imgPath';
              }
            }

            print('Vehicle ${vehicle['license_plate']} image path: $imgPath -> $finalImageUrl');

            return {
              'license_plate': vehicle['license_plate']?.toString() ?? 'N/A',
              'model': vehicle['model']?.toString() ?? 'N/A',
              'color': vehicle['color']?.toString() ?? 'N/A',
              'make_year': vehicle['make_year']?.toString() ?? 'N/A',
              'imgpath': finalImageUrl,
              'vehicle_type': vehicle['vehicle_type']?.toString() ?? 'N/A',
              'vehicle_brand': vehicle['vehicle_brand']?.toString() ?? 'N/A',
              'fuel_type': vehicle['fuel_type']?.toString() ?? 'N/A',
              'transmission_type': vehicle['transmission_type']?.toString() ?? 'N/A',
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load vehicles: ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      print('Error fetching vehicles: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching vehicles: $e';
      });
    }
  }

  Future<void> _fetchMaintenanceHistory() async {
    try {
      final history = await _apiService.getMaintenanceHistory();
      setState(() {
        _maintenanceHistory = history;
      });
    } catch (e) {
      print('Error fetching maintenance history: $e');
      setState(() {
        _errorMessage = 'Error fetching maintenance history: $e';
      });
    }
  }

  Widget _buildVehicleImage(String? imageUrl, String licensePlate) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.directions_car,
          color: Colors.red,
          size: 50,
        ),
      );
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[300],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          headers: {
            'Accept': 'image/*',
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Image load error for $licensePlate ($imageUrl): $error');
            print('Error details: $stackTrace');

            return Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off,
                    color: Colors.orange[600],
                    size: 30,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '404 Error',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'File not found',
                    style: TextStyle(
                      color: Colors.orange[600],
                      fontSize: 8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMaintenanceHistory(String licensePlate) {
    final vehicleHistory = _maintenanceHistory
        .where((record) => record['license_plate'] == licensePlate)
        .toList();

    if (vehicleHistory.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          'No maintenance history available',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
          child: Text(
            'Maintenance History',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ...vehicleHistory.map((record) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Service', record['service_name']),
                    _buildDetailRow('Description', record['service_description']),
                    _buildDetailRow('Date', record['reserve_date']),
                    _buildDetailRow('Time', '${record['start_time']} - ${record['end_time']}'),
                    _buildDetailRow('Price', record['price']),
                    _buildDetailRow('Paid', record['is_paid'] == 'true' ? 'Yes' : 'No'),
                    _buildDetailRow('Notes', record['notes']),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _generateMaintenanceMessages() {
    List<Map<String, String>> messages = [];
    final currentDate = DateTime.now();

    for (var vehicle in _vehicles) {
      final vehicleHistory = _maintenanceHistory
          .where((record) => record['license_plate'] == vehicle['license_plate'])
          .toList();

      for (var history in vehicleHistory) {
        DateTime lastMaintenanceDate = DateTime.parse(history['reserve_date']);
        String maintenanceType = history['service_name'];

        if (maintenanceType.toLowerCase().contains('oil change')) {
          if (currentDate.difference(lastMaintenanceDate).inDays > 180) {
            messages.add({
              'title': "Oil Change Reminder - ${vehicle['license_plate']}",
              'description': "It's been over 6 months since your last oil change",
              'recommendation': 'Recommended every 6 months'
            });
          }
        } else if (maintenanceType.toLowerCase().contains('brake')) {
          if (currentDate.difference(lastMaintenanceDate).inDays > 365) {
            messages.add({
              'title': "Brake Check Reminder - ${vehicle['license_plate']}",
              'description': 'Time for your annual brake inspection',
              'recommendation': 'Recommended every 12 months'
            });
          }
        } else if (maintenanceType.toLowerCase().contains('tire')) {
          if (currentDate.difference(lastMaintenanceDate).inDays > 730) {
            messages.add({
              'title': "Tire Check Reminder - ${vehicle['license_plate']}",
              'description': "Time to check your tires' condition",
              'recommendation': 'Recommended every 24 months'
            });
          }
        }
      }
    }

    if (messages.isEmpty) {
      messages.add({
        'title': 'Maintenance Up to Date',
        'description': 'Your vehicles are currently well-maintained',
        'recommendation': 'Keep up the good work!'
      });
    }

    return messages;
  }

  void _editField(BuildContext context, String fieldType) {
    String currentValue = fieldType == 'contact' ? contactNumber : email;
    TextEditingController controller =
        fieldType == 'contact' ? _contactController : _emailController;

    controller.text = currentValue;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text("Edit ${fieldType == 'contact' ? 'Contact Number' : 'Email'}"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Enter new $fieldType'),
          keyboardType: fieldType == 'contact'
              ? TextInputType.phone
              : TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                _showVerificationDialog(context, fieldType, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showVerificationDialog(
      BuildContext context, String fieldType, String newValue) {
    _verificationController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('A verification code has been sent to your $fieldType'),
            TextField(
              controller: _verificationController,
              decoration:
                  const InputDecoration(hintText: 'Enter verification code'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_verificationController.text == '1234') {
                setState(() {
                  if (fieldType == 'contact') {
                    contactNumber = newValue;
                  } else {
                    email = newValue;
                  }
                });
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$fieldType updated successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid verification code')),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maintenanceMessages = _generateMaintenanceMessages();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Profile',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red)),
            const SizedBox(height: 10),
            Text('Name: $userName', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Contact: $contactNumber',
                    style: const TextStyle(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editField(context, 'contact'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Email: $email', style: const TextStyle(fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editField(context, 'email'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Registered Vehicles',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = '';
                    });
                    _fetchData();
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Column(
                        children: [
                          Text(
                            _errorMessage,
                            style: const TextStyle(fontSize: 16, color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _errorMessage = '';
                              });
                              _fetchData();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                    : _vehicles.isEmpty
                        ? const Center(
                            child: Text(
                              'No vehicles registered',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _vehicles.length,
                            itemBuilder: (context, index) {
                              final vehicle = _vehicles[index];
                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ExpansionTile(
                                  title: Text(vehicle['license_plate']),
                                  subtitle: const Text('Tap to view details and maintenance history'),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildVehicleImage(
                                                vehicle['imgpath'],
                                                vehicle['license_plate'],
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    _buildDetailRow('Brand', vehicle['vehicle_brand']),
                                                    _buildDetailRow('Model', vehicle['model']),
                                                    _buildDetailRow('Type', vehicle['vehicle_type']),
                                                    _buildDetailRow('Year', vehicle['make_year']),
                                                    _buildDetailRow('Color', vehicle['color']),
                                                    _buildDetailRow('Fuel', vehicle['fuel_type']),
                                                    _buildDetailRow('Transmission', vehicle['transmission_type']),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          _buildMaintenanceHistory(vehicle['license_plate']),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Maintenance Messages',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...maintenanceMessages.map((message) => Column(
                          children: [
                            ListTile(
                              title: Text(
                                message['title']!,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(message['description']!,
                                      style: const TextStyle(fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(message['recommendation']!,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            if (message != maintenanceMessages.last)
                              const Divider(),
                          ],
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contactController.dispose();
    _emailController.dispose();
    _verificationController.dispose();
    super.dispose();
  }
}
