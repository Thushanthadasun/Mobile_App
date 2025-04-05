import 'package:company_app/logo_slider.dart';
import 'package:flutter/material.dart';

class HomePageContent extends StatelessWidget {
  final List<Map<String, String>> services = [
    {"title": "Mechanical Repair", "short_description": "Fixing mechanical issues with precision.", "long_description": "Our expert technicians handle all kinds of mechanical repairs, including engine diagnostics, transmission issues, and brake system overhauls. We use high-quality parts and advanced tools to ensure your vehicle runs smoothly.", "image": "assets/mech-service.jpg"},
    {"title": "Collision Repair", "short_description": "Restoring vehicles after accidents.", "long_description": "We specialize in repairing accident damage, from minor dents to major structural repairs. Our state-of-the-art facility ensures your car is restored to its pre-accident condition with precision and care.", "image": "assets/collision-service.jpeg"},
    {"title": "Wash and Grooming", "short_description": "Premium cleaning and grooming services.", "long_description": "We provide thorough interior and exterior cleaning, including waxing, polishing, and vacuuming. Our services help maintain your vehicle's aesthetics and value.", "image": "assets/wash-service.jpg"},
    {"title": "Wheel Services", "short_description": "Alignment and balancing for smooth rides.", "long_description": "Our wheel services include tire rotation, balancing, alignment, and replacement. Proper wheel maintenance improves fuel efficiency and ensures a smooth ride.", "image": "assets/wheel-service.webp"},
    {"title": "Lubricant Services", "short_description": "Essential lubrication for engine longevity.", "long_description": "Regular oil changes and lubrication services are crucial for engine health. We use high-quality oils and lubricants to ensure smooth performance and reduce wear and tear.", "image": "assets/lubricant-service.png"},
    {"title": "Interior Services", "short_description": "Keeping your car's interior spotless.", "long_description": "Our interior detailing services include deep cleaning, odor removal, and upholstery restoration, ensuring a fresh and comfortable driving experience.", "image": "assets/interior-service.jpg"},
    {"title": "Exterior Services", "short_description": "Polishing and protecting your car's body.", "long_description": "We offer paint protection, waxing, and scratch removal to maintain your car's shine and protect it from environmental damage.", "image": "assets/exterior-service.jpg"},
    {"title": "Engine Tune-up", "short_description": "Enhancing engine performance and efficiency.", "long_description": "Our tune-up services include spark plug replacement, fuel system cleaning, and engine diagnostics to optimize performance and fuel efficiency.", "image": "assets/tuneup-service.jpeg"},
  ];

  void _showDescription(BuildContext context, String title, String longDescription, String image) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          children: [
            Image.asset(image, width: 100, height: 100, fit: BoxFit.cover),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(longDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Our Services",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                // Services List
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: ClipOval(
                          child: Image.asset(
                            services[index]["image"]!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          services[index]["title"]!,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(services[index]["short_description"]!),
                        onTap: () => _showDescription(
                          context,
                          services[index]["title"]!,
                          services[index]["long_description"]!,
                          services[index]["image"]!,
                        ),
                      ),
                    );
                  },
                ),
                
                // Booking Section
                SizedBox(height: 30),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Register ",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                              TextSpan(
                                text: "and",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              TextSpan(
                                text: " Book Appointment ",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                              TextSpan(
                                text: "Today!",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Features with ticks - now takes full width since image is removed
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "You can explore the features that we provide with fun and have their own functions each feature.",
                                  style: TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                                SizedBox(height: 10),
                                _buildFeatureItem("Convenient Online & Mobile Booking"),
                                _buildFeatureItem("Real-Time Service Tracking"),
                                _buildFeatureItem("Comprehensive Service History"),
                                _buildFeatureItem("Timely Reminders & Notifications"),
                                _buildFeatureItem("Secure Payments & Exclusive Offers"),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Book Now button - Shortened and centered
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to book_now.dart
                            Navigator.pushNamed(context, '/book_now');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "BOOK NOW",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                LogoSlider(), // Logo Slider added at the bottom
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom circular red tick with white check
          Container(
            margin: EdgeInsets.only(top: 2, right: 8),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.check,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
