import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    StudentHome(),
    StudentFeatures(),
    StudentProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student's Dashboard"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF004AAD), Color(0xFF007CF0)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF004AAD), Color(0xFF007CF0)],
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          currentIndex: _currentIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
            BottomNavigationBarItem(icon: Icon(Icons.extension), label: "Features"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}

// 🔵 HOME
class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE6F0FF), Color(0xFFCFE2FF)], // light blue
        ),
      ),
      child: const Center(
        child: Text(
          "Student Dashboard Home",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

// 🔵 FEATURES
class StudentFeatures extends StatelessWidget {
  const StudentFeatures({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE6F0FF), Color(0xFFCFE2FF)],
        ),
      ),
      child: const Center(
        child: Text(
          "Student Features",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

// 🔵 PROFILE
class StudentProfile extends StatelessWidget {
  const StudentProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE6F0FF), Color(0xFFCFE2FF)],
        ),
      ),
      child: Center(
        child: GestureDetector(
          onTap: () async {
            await FirebaseAuth.instance.signOut();

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
            );
          },
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text("Logout"),
            ),
          ),
        ),
      ),
    );
  }
}