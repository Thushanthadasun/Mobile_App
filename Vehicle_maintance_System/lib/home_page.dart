import 'logo_slider.dart';
import 'package:company_app/book_now.dart'; 
import 'package:flutter/material.dart';

class HomePageContent extends StatelessWidget {
  final List<Map<String, String>> services = [
    {"title": "Mechanical Repair", "short_description": "Fixing mechanical issues with precision.", "long_description": "Our expert technicians handle all kinds of mechanical repairs, including engine diagnostics, transmission issues, and brake system overhauls. We use high-quality parts and advanced tools to ensure your vehicle runs smoothly.", "image": "assets/mech-service.jpg"},
    {"title": "Collision Repair", "short_description": "Restoring vehicles after accidents.", "long_description": "We specialize in repairing accident damage, from minor dents to major structural repairs. Our state-of-the-art facility ensures your car is restored to its pre-accident condition with precision and care.", "image": "assets/collision-service.jpeg"},
    {"title": "Lubricant Services", "short_description": "Essential lubrication for engine longevity.", "long_description": "Regular oil changes and lubrication services are crucial for engine health. We use high-quality oils and lubricants to ensure smooth performance and reduce wear and tear.", "image": "assets/lubricant-service.png"},
    {"title": "Interior Services", "short_description": "Keeping your car's interior spotless.", "long_description": "Our interior detailing services include deep cleaning, odor removal, and upholstery restoration, ensuring a fresh and comfortable driving experience.", "image": "assets/interior-service.jpg"},
    {"title": "Exterior Services", "short_description": "Polishing and protecting your car's body.", "long_description": "We offer paint protection, waxing, and scratch removal to maintain your car's shine and protect it from environmental damage.", "image": "assets/exterior-service.jpg"},
    {"title": "Engine Tune-up", "short_description": "Enhancing engine performance and efficiency.", "long_description": "Our tune-up services include spark plug replacement, fuel system cleaning, and engine diagnostics to optimize performance and fuel efficiency.", "image": "assets/tuneup-service.jpeg"},
  ];

  HomePageContent({super.key});

  void _showDescription(
    BuildContext context,
    String title,
    String longDescription,
    String image,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          children: [
            Image.asset(image, width: 100, height: 100, fit: BoxFit.cover),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(longDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
          const Text(
            'Our Services',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: ClipOval(
                          child: Image.asset(
                            services[index]['image']!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          services[index]['title']!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(services[index]['short_description']!),
                        onTap: () => _showDescription(
                          context,
                          services[index]['title']!,
                          services[index]['long_description']!,
                          services[index]['image']!,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
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
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Register ',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red),
                              ),
                              TextSpan(
                                text: 'and',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                              TextSpan(
                                text: ' Book Appointment ',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red),
                              ),
                              TextSpan(
                                text: 'Today!',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'You can explore the features that we provide with fun and have their own functions each feature.',
                            style:
                                TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          const SizedBox(height: 10),
                          _buildFeatureItem(
                              'Convenient Online & Mobile Booking'),
                          _buildFeatureItem('Real-Time Service Tracking'),
                          _buildFeatureItem('Comprehensive Service History'),
                          _buildFeatureItem('Timely Reminders & Notifications'),
                          _buildFeatureItem(
                              'Secure Payments & Exclusive Offers'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/book_now');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'BOOK NOW',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const LogoSlider(),
                const SizedBox(height: 20),
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
          Container(
            margin: const EdgeInsets.only(top: 2, right: 8),
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.check, size: 12, color: Colors.white),
            ),
          ),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
