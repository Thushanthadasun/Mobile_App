import 'package:flutter/material.dart';

class LogoSlider extends StatefulWidget {
  const LogoSlider({super.key});

  @override
  _LogoSliderState createState() => _LogoSliderState();
}

class _LogoSliderState extends State<LogoSlider>
    with SingleTickerProviderStateMixin {
  final List<String> logos = [
    'assets/logo1.png',
    'assets/logo2.png',
    'assets/logo3.png',
    'assets/logo4.png',
    'assets/logo5.png',
    'assets/logo6.png',
    'assets/logo7.png',
    'assets/logo8.png',
    'assets/logo9.png',
    'assets/logo10.png',
    'assets/logo11.png',
    'assets/logo12.png',
  ];

  late ScrollController _scrollController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..addListener(() {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;

        if (currentScroll >= maxScroll) {
          _scrollController.jumpTo(0);
        }

        _scrollController.jumpTo(
          _animationController.value * maxScroll,
        );
      });

    _startAutoScroll();
  }

  void _startAutoScroll() {
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors
                  .grey[200], // Matches white background with subtle contrast
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Text(
              'Our Brands',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800], // Darker text for contrast
                letterSpacing: 1.2,
              ),
            ),
          ),

          // Logo Slider
          SizedBox(
            height: 100,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logos.length * 2,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        logos[index % logos.length],
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Usage in your main widget:
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white, // Matching background
      body: Column(
        children: [
          SizedBox(height: 20),
          LogoSlider(),
          SizedBox(height: 20),
          // Other widgets...
        ],
      ),
    );
  }
}
