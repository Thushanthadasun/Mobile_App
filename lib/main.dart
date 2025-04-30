import 'package:flutter/material.dart';
import 'company_info.dart';
import 'home_page.dart';
import 'my_profile.dart';
import 'book_now.dart';
import 'login_page.dart'; // Import the login page
import 'signup_page.dart'; // Import the signup page

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login', // Set the initial route to login
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const HomePage(),
        '/book_now': (context) => BookNow(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    HomePageContent(),
    CompanyInfo(),
    MyProfile(),  // Now loads MyProfile
    BookNow(),  // Now loads BookNow
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          height: 60,
          child: Image.asset('assets/logo.png'),
        ),
        centerTitle: true,
        // ignore: deprecated_member_use
        backgroundColor: const Color.fromARGB(255, 245, 215, 213).withOpacity(0.7),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  // ignore: deprecated_member_use
                  colors: [Colors.white, Colors.red.withOpacity(0.7)],
                ),
              ),
              child: Center(
                child: SizedBox(
                  height: 60,
                  child: Image.asset('assets/logo.png'),
                ),
              ),
            ),
            _drawerItem(context, Icons.home, 'Home', 0),
            _drawerItem(context, Icons.info, 'Company Info', 1),
            _drawerItem(context, Icons.person, 'My Profile', 2),
            _drawerItem(context, Icons.book_online, 'Book Now', 3),
            _drawerItem(context, Icons.logout, 'Log Out', -1),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // ignore: deprecated_member_use
            colors: [Colors.white, Colors.red.withOpacity(0.7)],
          ),
        ),
        child: Center(
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Company Info'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'My Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.book_online), label: 'Book Now'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, int index) {
  return ListTile(
    // ignore: deprecated_member_use
    leading: Icon(icon, color: Colors.red.withOpacity(0.7)),
    title: Text(title),
    onTap: () {
      Navigator.pop(context); // Close the drawer
      if (index >= 0) {
        setState(() {
          _selectedIndex = index;
        });
      } else {
        // Log out case: Navigate to login page
        Navigator.pushReplacementNamed(context, '/login');
      }
    },
  );
}

}