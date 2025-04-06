import 'package:flutter/material.dart';

class MyProfile extends StatefulWidget {
  @override
  _MyProfileState createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  String userName = "John Doe";
  String contactNumber = "+1 555-123-4567";
  String email = "john.doe@example.com";

  final List<Map<String, dynamic>> registeredVehicles = [
    {
      "number": "ABC-1234",
      "history": [
        {"date": "2023-01-15", "maintenance": "Oil Change", "price": "\$25"},
        {"date": "2023-02-20", "maintenance": "Brake Check", "price": "\$40"},
      ],
      "totalPayment": "\$65"
    },
    {
      "number": "XYZ-5678",
      "history": [
        {"date": "2023-03-10", "maintenance": "Tire Replacement", "price": "\$100"},
      ],
      "totalPayment": "\$100"
    },
  ];

  TextEditingController _contactController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _verificationController = TextEditingController();

  List<Map<String, String>> _generateMaintenanceMessages() {
    List<Map<String, String>> messages = [];
    final currentDate = DateTime.now();

    for (var vehicle in registeredVehicles) {
      for (var history in vehicle["history"]) {
        DateTime lastMaintenanceDate = DateTime.parse(history["date"]);
        String maintenanceType = history["maintenance"];

        if (maintenanceType == "Oil Change") {
          if (currentDate.difference(lastMaintenanceDate).inDays > 180) {
            messages.add({
              "title": "Oil Change Reminder - ${vehicle['number']}",
              "description": "It's been over 6 months since your last oil change",
              "recommendation": "Recommended every 6 months"
            });
          }
        } else if (maintenanceType == "Brake Check") {
          if (currentDate.difference(lastMaintenanceDate).inDays > 365) {
            messages.add({
              "title": "Brake Check Reminder - ${vehicle['number']}",
              "description": "Time for your annual brake inspection",
              "recommendation": "Recommended every 12 months"
            });
          }
        } else if (maintenanceType == "Tire Replacement") {
          if (currentDate.difference(lastMaintenanceDate).inDays > 730) {
            messages.add({
              "title": "Tire Check Reminder - ${vehicle['number']}",
              "description": "Time to check your tires' condition",
              "recommendation": "Recommended every 24 months"
            });
          }
        }
      }
    }

    if (messages.isEmpty) {
      messages.add({
        "title": "Maintenance Up to Date",
        "description": "Your vehicles are currently well-maintained",
        "recommendation": "Keep up the good work!"
      });
    }

    return messages;
  }

  void _editField(BuildContext context, String fieldType) {
    String currentValue = fieldType == 'contact' ? contactNumber : email;
    TextEditingController controller = fieldType == 'contact' ? _contactController : _emailController;
    
    controller.text = currentValue;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit ${fieldType == 'contact' ? 'Contact Number' : 'Email'}"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Enter new $fieldType"),
          keyboardType: fieldType == 'contact' ? TextInputType.phone : TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => _showVerificationDialog(context, fieldType, controller.text),
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showVerificationDialog(BuildContext context, String fieldType, String newValue) {
    _verificationController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Verification"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("A verification code has been sent to your $fieldType"),
            TextField(
              controller: _verificationController,
              decoration: InputDecoration(hintText: "Enter verification code"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (_verificationController.text == "1234") {
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
                  SnackBar(content: Text("$fieldType updated successfully")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Invalid verification code")),
                );
              }
            },
            child: Text("Verify"),
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
            Text("My Profile",
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
            SizedBox(height: 10),
            Text("Name: $userName", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Contact: $contactNumber", style: TextStyle(fontSize: 18)),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editField(context, 'contact'),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Email: $email", style: TextStyle(fontSize: 18)),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editField(context, 'email'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text("Registered Vehicles",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true, // Prevents overflow by sizing to content
              physics: NeverScrollableScrollPhysics(), // Disables inner scrolling
              itemCount: registeredVehicles.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ExpansionTile(
                    title: Text(registeredVehicles[index]["number"]),
                    subtitle: Text("Tap to view maintenance history"),
                    children: [
                      Container(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Maintenance History",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 10),
                            Table(
                              border: TableBorder.all(color: Colors.grey),
                              columnWidths: {
                                0: FlexColumnWidth(2),
                                1: FlexColumnWidth(3),
                                2: FlexColumnWidth(1),
                              },
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(color: Colors.grey[200]),
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text("Date",
                                          style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text("Maintenance",
                                          style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text("Price",
                                          style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                ...registeredVehicles[index]["history"]
                                    .map((history) => TableRow(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text(history["date"]),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text(history["maintenance"]),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text(history["price"]),
                                            ),
                                          ],
                                        ))
                                    .toList(),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Total Payment: ${registeredVehicles[index]["totalPayment"]}",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            // Maintenance Messages Section (Moved here)
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maintenance Messages',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    ...maintenanceMessages.map((message) => Column(
                          children: [
                            ListTile(
                              title: Text(
                                message["title"]!,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(message["description"]!, style: TextStyle(fontSize: 14)),
                                  SizedBox(height: 4),
                                  Text(message["recommendation"]!,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            if (message != maintenanceMessages.last) Divider(),
                          ],
                        )).toList(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20), // Extra padding at the bottom
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
