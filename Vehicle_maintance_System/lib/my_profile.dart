import 'package:flutter/material.dart';
import 'api_service.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({super.key});

  @override
  _MyProfileState createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  String userName = '';
  String contactNumber = '';
  String email = '';
  bool loading = true;

  final List<Map<String, dynamic>> registeredVehicles = [
    {
      'number': 'ABC-1234',
      'history': [
        {'date': '2023-01-15', 'maintenance': 'Oil Change', 'price': '\$25'},
        {'date': '2023-02-20', 'maintenance': 'Brake Check', 'price': '\$40'},
      ],
      'totalPayment': '\$65'
    },
    {
      'number': 'XYZ-5678',
      'history': [
        {
          'date': '2023-03-10',
          'maintenance': 'Tire Replacement',
          'price': '\$100'
        },
      ],
      'totalPayment': '\$100'
    },
  ];

  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _verificationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final data = await ApiService().getUserProfile();
    if (data != null) {
      setState(() {
        userName = '${data['fname']} ${data['lname']}'; // ✅ fixed here
        contactNumber = data['mobile']; // ✅ fixed here
        email = data['email'];
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  List<Map<String, String>> _generateMaintenanceMessages() {
    List<Map<String, String>> messages = [];
    final currentDate = DateTime.now();

    for (var vehicle in registeredVehicles) {
      for (var history in vehicle['history']) {
        DateTime lastMaintenanceDate = DateTime.parse(history['date']);
        String maintenanceType = history['maintenance'];

        if (maintenanceType == 'Oil Change' &&
            currentDate.difference(lastMaintenanceDate).inDays > 180) {
          messages.add({
            'title': "Oil Change Reminder - ${vehicle['number']}",
            'description': "It's been over 6 months since your last oil change",
            'recommendation': 'Recommended every 6 months'
          });
        } else if (maintenanceType == 'Brake Check' &&
            currentDate.difference(lastMaintenanceDate).inDays > 365) {
          messages.add({
            'title': "Brake Check Reminder - ${vehicle['number']}",
            'description': 'Time for your annual brake inspection',
            'recommendation': 'Recommended every 12 months'
          });
        } else if (maintenanceType == 'Tire Replacement' &&
            currentDate.difference(lastMaintenanceDate).inDays > 730) {
          messages.add({
            'title': "Tire Check Reminder - ${vehicle['number']}",
            'description': "Time to check your tires' condition",
            'recommendation': 'Recommended every 24 months'
          });
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
                    SnackBar(content: Text('$fieldType updated successfully')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid verification code')));
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

    return loading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
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
                      Text('Email: $email',
                          style: const TextStyle(fontSize: 18)),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editField(context, 'email'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Maintenance Messages',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                                        fontSize: 12, color: Colors.grey[600])),
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
