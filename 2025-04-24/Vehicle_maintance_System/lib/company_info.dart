import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:url_launcher/url_launcher.dart';

class CompanyInfo extends StatefulWidget {
  const CompanyInfo({super.key});

  @override
  _CompanyInfoState createState() => _CompanyInfoState();
}

class _CompanyInfoState extends State<CompanyInfo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _customersAnimation;
  late Animation<int> _servicesAnimation;
  late Animation<int> _brandsAnimation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _customersAnimation = IntTween(begin: 0, end: 100)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _servicesAnimation = IntTween(begin: 0, end: 500)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _brandsAnimation = IntTween(begin: 0, end: 600)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    if (!_hasAnimated) {
      _controller.forward(from: 0);
      setState(() {
        _hasAnimated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Your Satisfaction, Our Priority',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              _infoSection('Best Technologies', 'assets/icon-mech.png'),
              _infoSection('Best Staff', 'assets/icon-staff.png'),
              _infoSection('Best Service', 'assets/icon-service.png'),
              _infoSection('Best Price', 'assets/icon-payment.png'),
              const SizedBox(height: 20),
              VisibilityDetector(
                key: const Key('stats-section'),
                onVisibilityChanged: (visibilityInfo) {
                  if (visibilityInfo.visibleFraction > 0.5 && !_hasAnimated) {
                    _startAnimation();
                  }
                },
                child: _statsSection(),
              ),
              const SizedBox(height: 20),
              _expertiseSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoSection(String title, String imagePath) {
    final Map<String, String> descriptions = {
      'Best Technologies':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla tincidunt, est nec tincidunt ultricies, turpis mi ultrices nunc, nec tincidunt nunc libero eget nisl.',
      'Best Staff':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla tincidunt, est nec tincidunt ultricies, turpis mi ultrices nunc, nec tincidunt nunc libero eget nisl.',
      'Best Service':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla tincidunt, est nec tincidunt ultricies, turpis mi ultrices nunc, nec tincidunt nunc libero eget nisl.',
      'Best Price':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla tincidunt, est nec tincidunt ultricies, turpis mi ultrices nunc, nec tincidunt nunc libero eget nisl.',
    };

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                    radius: 20, backgroundImage: AssetImage(imagePath)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              descriptions[title] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsSection() {
    return Column(
      children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statItem(_customersAnimation, 'Registered Customers'),
                _statItem(_servicesAnimation, 'Successful Services'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16), // Space between the two cards
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center the single item
              children: [
                _statItem(_brandsAnimation, 'Top Brands'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statItem(Animation<int> animation, String label) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Text(
              '${animation.value}+',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
            );
          },
        ),
        Text(label,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _expertiseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Our Expertise',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
        const SizedBox(height: 10),
        _expertItem(
            'John Doe',
            'Owner/Manager',
            'assets/staff1.png',
            'https://linkedin.com/in/johndoe',
            'mailto:johndoe@gmail.com',
            'https://facebook.com/johndoe'),
        _expertItem(
            'Jane Doe',
            'Mechanic',
            'assets/staff2.png',
            'https://linkedin.com/in/janedoe',
            'mailto:janedoe@gmail.com',
            'https://facebook.com/janedoe'),
        _expertItem(
            'John Smith',
            'Technician',
            'assets/staff3.png',
            'https://linkedin.com/in/johnsmith',
            'mailto:johnsmith@gmail.com',
            'https://facebook.com/johnsmith'),
        _expertItem(
            'Jane Smith',
            'Technician',
            'assets/staff4.png',
            'https://linkedin.com/in/janesmith',
            'mailto:janesmith@gmail.com',
            'https://facebook.com/janesmith'),
      ],
    );
  }

  Widget _expertItem(String name, String role, String imagePath,
      String linkedinUrl, String gmailUrl, String facebookUrl) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage(imagePath),
              onBackgroundImageError: (exception, stackTrace) {
                print('Error loading image: $imagePath - $exception');
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(role,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _socialMediaButton('assets/linkedin.png', linkedinUrl),
                      const SizedBox(width: 8),
                      _socialMediaButton('assets/gmail.png', gmailUrl),
                      const SizedBox(width: 8),
                      _socialMediaButton('assets/facebook.png', facebookUrl),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialMediaButton(String imagePath, String url) {
    return BounceButton(
      imagePath: imagePath,
      url: url,
    );
  }
}

class BounceButton extends StatefulWidget {
  final String imagePath;
  final String url;

  const BounceButton({super.key, required this.imagePath, required this.url});

  @override
  _BounceButtonState createState() => _BounceButtonState();
}

class _BounceButtonState extends State<BounceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTap() async {
    print('Tapped: ${widget.imagePath}');
    _animationController.forward().then((_) {
      _animationController.reverse();
      _launchUrl();
    });
  }

  void _launchUrl() async {
    final Uri uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('Could not launch ${widget.url}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Image.asset(
              widget.imagePath,
              width: 24,
              height: 24,
            ),
          );
        },
      ),
    );
  }
}
