import 'package:flutter/material.dart';
import 'company_info.dart';
import 'home_page.dart';
import 'my_profile.dart';
import 'book_now.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'email_activation_page.dart'; // ✅ Import your new email activation page

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const HomePage(),
        '/book_now': (context) => const BookNow(),
      },
      // ✅ Handle dynamic token-based route for email verification
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '');
        if (uri.path == '/signup/emailactivation' &&
            uri.queryParameters.containsKey('token')) {
          final token = uri.queryParameters['token']!;
          return MaterialPageRoute(
            builder: (context) => EmailActivationPage(token: token),
          );
        }
        return null; // fallback to default routes
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    HomePageContent(),
    CompanyInfo(),
    MyProfile(),
    const BookNow(),
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
          height: 40,
          child: Image.asset('assets/logo.png'),
        ),
        centerTitle: true,
        backgroundColor: Colors.red.withOpacity(0.7),
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
                  colors: [Colors.red.withOpacity(0.7), Colors.white],
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
            colors: [Colors.red.withOpacity(0.7), Colors.white],
          ),
        ),
        child: Center(
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.info), label: 'Company Info'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'My Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.book_online), label: 'Book Now'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _drawerItem(
      BuildContext context, IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: Colors.red.withOpacity(0.7)),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        if (index >= 0) {
          setState(() {
            _selectedIndex = index;
          });
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
    );
  }
}
