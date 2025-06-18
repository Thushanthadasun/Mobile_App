import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class VehicleListPage extends StatefulWidget {
  const VehicleListPage({super.key});

  @override
  _VehicleListPageState createState() => _VehicleListPageState();
}

class _VehicleListPageState extends State<VehicleListPage> {
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _maintenanceHistory = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final ApiService _apiService = ApiService();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
        backgroundColor: Colors.red,
        actions: [
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.red.withOpacity(0.7)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                    ),
                  )
                : _vehicles.isEmpty
                    ? const Center(
                        child: Text(
                          'No vehicles registered',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _vehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = _vehicles[index];
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
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
                                            Text(
                                              vehicle['license_plate'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
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
                          );
                        },
                      ),
      ),
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
}