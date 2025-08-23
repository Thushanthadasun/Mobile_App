import 'package:flutter/material.dart';
import 'package:car_service_app/api_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  bool agreeToTerms = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.withOpacity(0.7), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16.0 : 24.0,
                  vertical: 16.0,
                ),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isSmallScreen ? double.infinity : 450,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Image.asset(
                              'assets/logo.png',
                              width: isSmallScreen ? 120 : 150,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.account_circle,
                                  size: isSmallScreen ? 120 : 150,
                                  color: Colors.red,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Register now',
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        if (isSmallScreen)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              nameField(
                                  "First Name", "John", _firstNameController),
                              const SizedBox(height: 16),
                              nameField(
                                  "Last Name", "Doe", _lastNameController),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                  child: nameField("First Name", "John",
                                      _firstNameController)),
                              const SizedBox(width: 16),
                              Expanded(
                                  child: nameField(
                                      "Last Name", "Doe", _lastNameController)),
                            ],
                          ),
                        const SizedBox(height: 16),
                        buildTextField("Email address", 'Enter your email',
                            _emailController, TextInputType.emailAddress),
                        const SizedBox(height: 16),
                        buildTextField("Mobile Number", '+94701111222',
                            _mobileController, TextInputType.phone),
                        const SizedBox(height: 16),
                        buildPasswordField("Password", _passwordController),
                        const SizedBox(height: 16),
                        buildPasswordField(
                            "Re-enter Password", _confirmPasswordController),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: agreeToTerms,
                                onChanged: (value) {
                                  setState(() {
                                    agreeToTerms = value ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                                child: Text('Agree to terms and conditions',
                                    style: TextStyle(fontSize: 14))),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () async {
                              String fname = _firstNameController.text;
                              String lname = _lastNameController.text;
                              String email = _emailController.text;
                              String mobile = _mobileController.text;
                              String password = _passwordController.text;
                              String confirmPassword =
                                  _confirmPasswordController.text;

                              if ([
                                fname,
                                lname,
                                email,
                                mobile,
                                password,
                                confirmPassword
                              ].any((e) => e.isEmpty)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Please fill in all fields')));
                                return;
                              }
                              if (password != confirmPassword) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Passwords do not match')));
                                return;
                              }
                              if (!agreeToTerms) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Please agree to terms')));
                                return;
                              }

                              Map<String, dynamic> userData = {
                                "fname": fname,
                                "lname": lname,
                                "email": email,
                                "mobile": mobile,
                                "password": password,
                              };

                              print(
                                  "Sending user data: $userData"); // Debug log
                              bool success =
                                  await ApiService().signup(userData);
                              print("Signup success: $success"); // Debug log

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Registered successfully!')));
                                Navigator.pushReplacementNamed(
                                    context, '/login');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Registration failed')));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Register',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget nameField(
      String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget buildTextField(String label, String hint,
      TextEditingController controller, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget buildPasswordField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Enter password',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget buildDividerWithOr() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('or',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        ),
        Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
      ],
    );
  }
}
