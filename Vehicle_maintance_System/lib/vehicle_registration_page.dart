import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Import for MediaType
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VehicleRegistrationPage extends StatefulWidget {
  @override
  _VehicleRegistrationPageState createState() => _VehicleRegistrationPageState();
}

class _VehicleRegistrationPageState extends State<VehicleRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _licensePlateController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _makeYearController = TextEditingController();
  String? _vehicleTypeId;
  String? _vehicleBrandId;
  String? _transmissionTypeId;
  String? _fuelTypeId;
  XFile? _uploadedImage;

  List<Map<String, String>> _vehicleTypes = [];
  List<Map<String, String>> _vehicleBrands = [];
  List<Map<String, String>> _transmissionTypes = [
    {'transmission_type_id': '1', 'transmission_type': 'Auto'},
    {'transmission_type_id': '2', 'transmission_type': 'Manual'},
  ];
  List<Map<String, String>> _fuelTypes = [
    {'fuel_type_id': '1', 'fuel_type': 'Petrol'},
    {'fuel_type_id': '2', 'fuel_type': 'Diesel'},
    {'fuel_type_id': '3', 'fuel_type': 'Electric'},
  ];

  final ImagePicker _picker = ImagePicker();
  final String baseUrl = 'http://localhost:5000/api/v1/user';

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    try {
      print('Fetching dropdown data...');
      final vehicleTypesResponse = await http.get(Uri.parse('$baseUrl/loadVehicleTypes'));
      final vehicleBrandsResponse = await http.get(Uri.parse('$baseUrl/loadVehicleBrands'));

      print('Vehicle types response: ${vehicleTypesResponse.statusCode}, ${vehicleTypesResponse.body}');
      print('Vehicle brands response: ${vehicleBrandsResponse.statusCode}, ${vehicleBrandsResponse.body}');

      if (vehicleTypesResponse.statusCode == 200) {
        final List<dynamic> typesData = jsonDecode(vehicleTypesResponse.body);
        setState(() {
          _vehicleTypes = typesData.map((item) => {
                'vehicle_type_id': item['vehicle_type_id'].toString(),
                'vehicle_type': item['vehicle_type'].toString(),
              }).toList();
          _vehicleTypeId = _vehicleTypes.isNotEmpty ? _vehicleTypes[0]['vehicle_type_id'] : null;
        });
      } else {
        throw Exception('Failed to load vehicle types: ${vehicleTypesResponse.statusCode}, ${vehicleTypesResponse.body}');
      }

      if (vehicleBrandsResponse.statusCode == 200) {
        final List<dynamic> brandsData = jsonDecode(vehicleBrandsResponse.body);
        setState(() {
          _vehicleBrands = brandsData.map((item) => {
                'vehicle_brand_id': item['vehicle_brand_id'].toString(),
                'vehicle_brand': item['vehicle_brand'].toString(),
              }).toList();
          _vehicleBrandId = _vehicleBrands.isNotEmpty ? _vehicleBrands[0]['vehicle_brand_id'] : null;
        });
      } else {
        throw Exception('Failed to load vehicle brands: ${vehicleBrandsResponse.statusCode}, ${vehicleBrandsResponse.body}');
      }

      setState(() {
        _transmissionTypeId = _transmissionTypes[0]['transmission_type_id'];
        _fuelTypeId = _fuelTypes[0]['fuel_type_id'];
      });
    } catch (e) {
      print('Error fetching dropdown data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching dropdown data: $e')),
      );
    }
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _makeYearController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      print('Picking image...');
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];
        final extension = image.name.split('.').last.toLowerCase();
        if (!allowedExtensions.contains(extension)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select a JPG, JPEG, PNG, or GIF image')),
          );
          return;
        }
        setState(() {
          _uploadedImage = image;
        });
        print('Image selected: ${image.name}, path: ${image.path}');
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        print('Submitting form to $baseUrl/register-vehicle...');
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');

        if (token == null) {
          print('No token found');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please log in to register a vehicle')),
          );
          return;
        }

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/register-vehicle'),
        );

        request.headers['Authorization'] = 'Bearer $token';
        print('Authorization header: Bearer $token');

        request.fields['licensePlate'] = _licensePlateController.text;
        request.fields['vehicleType'] = _vehicleTypeId!;
        request.fields['make'] = _vehicleBrandId!;
        request.fields['model'] = _modelController.text;
        request.fields['color'] = _colorController.text;
        request.fields['year'] = _makeYearController.text;
        request.fields['transmission'] = _transmissionTypeId!;
        request.fields['fuelType'] = _fuelTypeId!;
        print('Form fields: ${request.fields}');

        if (_uploadedImage != null) {
          try {
            final bytes = await _uploadedImage!.readAsBytes();
            final fileName = _uploadedImage!.name;
            request.files.add(
              http.MultipartFile.fromBytes(
                'vehicleImage',
                bytes,
                filename: fileName,
                contentType: MediaType('image', fileName.split('.').last.toLowerCase()),
              ),
            );
            print('Image added: $fileName, size: ${bytes.length} bytes');
          } catch (e) {
            print('Error reading image: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error reading image: $e')),
            );
            return;
          }
        } else {
          print('No image selected');
        }

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();
        print('Response status: ${response.statusCode}, body: $responseBody');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(responseBody);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'])),
          );
          // Clear form
          _licensePlateController.clear();
          _modelController.clear();
          _colorController.clear();
          _makeYearController.clear();
          setState(() {
            _uploadedImage = null;
            _vehicleTypeId = _vehicleTypes.isNotEmpty ? _vehicleTypes[0]['vehicle_type_id'] : null;
            _vehicleBrandId = _vehicleBrands.isNotEmpty ? _vehicleBrands[0]['vehicle_brand_id'] : null;
            _transmissionTypeId = _transmissionTypes[0]['transmission_type_id'];
            _fuelTypeId = _fuelTypes[0]['fuel_type_id'];
          });
        } else {
          String errorMessage = 'Failed to register vehicle';
          if (responseBody.trim().startsWith('<!DOCTYPE html>')) {
            errorMessage = 'Server error: Invalid file format. Please upload a JPG, JPEG, PNG, or GIF image.';
          } else {
            try {
              final responseData = jsonDecode(responseBody);
              errorMessage = responseData['message'] ?? errorMessage;
            } catch (_) {
              errorMessage = 'Unexpected server response';
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } catch (e) {
        print('Error submitting form: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting form: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vehicle Registration'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _licensePlateController,
                decoration: InputDecoration(
                  labelText: 'License Plate',
                  hintText: 'e.g., ABC-1234',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the license plate';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _vehicleTypeId,
                decoration: InputDecoration(labelText: 'Vehicle Type'),
                items: _vehicleTypes.map((Map<String, String> type) {
                  return DropdownMenuItem<String>(
                    value: type['vehicle_type_id'],
                    child: Text(type['vehicle_type']!),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _vehicleTypeId = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a vehicle type';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _vehicleBrandId,
                      decoration: InputDecoration(labelText: 'Make (Brand)'),
                      items: _vehicleBrands.map((Map<String, String> brand) {
                        return DropdownMenuItem<String>(
                          value: brand['vehicle_brand_id'],
                          child: Text(brand['vehicle_brand']!),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _vehicleBrandId = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a make';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _modelController,
                      decoration: InputDecoration(
                        labelText: 'Model',
                        hintText: 'e.g., Civic, Corolla',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the model';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _colorController,
                      decoration: InputDecoration(
                        labelText: 'Color',
                        hintText: 'e.g., Red, Blue',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the color';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _makeYearController,
                      decoration: InputDecoration(
                        labelText: 'Year of Manufacture',
                        hintText: 'e.g., 2022',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the year';
                        }
                        final year = int.tryParse(value);
                        if (year == null || year < 1900 || year > DateTime.now().year) {
                          return 'Please enter a valid year';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _transmissionTypeId,
                      decoration: InputDecoration(labelText: 'Transmission Type'),
                      items: _transmissionTypes.map((Map<String, String> type) {
                        return DropdownMenuItem<String>(
                          value: type['transmission_type_id'],
                          child: Text(type['transmission_type']!),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _transmissionTypeId = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a transmission type';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _fuelTypeId,
                      decoration: InputDecoration(labelText: 'Fuel Type'),
                      items: _fuelTypes.map((Map<String, String> type) {
                        return DropdownMenuItem<String>(
                          value: type['fuel_type_id'],
                          child: Text(type['fuel_type']!),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _fuelTypeId = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a fuel type';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload Vehicle Image',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.image),
                    label: Text('Choose Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _uploadedImage != null
                        ? 'Selected: ${_uploadedImage!.name}'
                        : 'No image selected',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Submit Registration',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}