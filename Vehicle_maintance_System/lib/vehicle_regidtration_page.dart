import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  String _vehicleType = 'Car';
  String _makeBrand = 'Toyota';
  String _transmissionType = 'Select Transmission';
  String _fuelType = 'Select Fuel Type';
  XFile? _uploadedImage; // Changed to XFile for image_picker

  final List<String> _vehicleTypes = ['Car', 'Van', 'Jeep', 'Lorry', 'Cab', 'Bicycle'];
  final List<String> _makeBrands = ['Toyota', 'BMW', 'Volvo', 'Nissan', 'Mercedes Benz', 'TATA', 'Honda', 'Micro', 'Jaguar'];

  final ImagePicker _picker = ImagePicker();

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
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      setState(() {
        _uploadedImage = image;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final vehicleDetails = {
        'license_plate': _licensePlateController.text,
        'model': _modelController.text,
        'color': _colorController.text,
        'make_year': _makeYearController.text,
        'vehicle_type': _vehicleType,
        'make_brand': _makeBrand,
        'transmission_type': _transmissionType,
        'fuel_type': _fuelType,
        'uploaded_image': _uploadedImage?.path ?? '',
      };
      print('Vehicle Details: $vehicleDetails');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vehicle registered successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vehicle Information Form'),
        backgroundColor: Colors.grey[200],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _licensePlateController,
                      decoration: InputDecoration(labelText: 'Vehicle Registration Number', hintText: 'Enter License Plate'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the license plate';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _vehicleType,
                      decoration: InputDecoration(labelText: 'Vehicle Type'),
                      items: _vehicleTypes.map((String value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _vehicleType = newValue!;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a vehicle type';
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
                      value: _makeBrand,
                      decoration: InputDecoration(labelText: 'Make (Brand)'),
                      items: _makeBrands.map((String value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _makeBrand = newValue!;
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
                      decoration: InputDecoration(labelText: 'Model', hintText: 'e.g., Civic, Corolla'),
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
                      decoration: InputDecoration(labelText: 'Color', hintText: 'e.g., Red, Blue'),
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
                      decoration: InputDecoration(labelText: 'Year of Manufacture', hintText: 'e.g., 2022'),
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
                      value: _transmissionType,
                      decoration: InputDecoration(labelText: 'Transmission Type'),
                      items: ['Select Transmission', 'Manual', 'Automatic'].map((String value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _transmissionType = newValue!;
                        });
                      },
                      validator: (value) {
                        if (value == 'Select Transmission') {
                          return 'Please select a transmission type';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _fuelType,
                      decoration: InputDecoration(labelText: 'Fuel Type'),
                      items: ['Select Fuel Type', 'Petrol', 'Diesel', 'Electric', 'Hybrid'].map((String value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _fuelType = newValue!;
                        });
                      },
                      validator: (value) {
                        if (value == 'Select Fuel Type') {
                          return 'Please select a fuel type';
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
                    child: Column(
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