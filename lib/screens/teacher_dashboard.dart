import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'export_attendance_screen.dart';
import 'login_screen.dart';

// Import individual feature screens
import 'manage_attendance_screen.dart';
import 'manage_courses_screen.dart';
import 'manage_student_screen.dart';


class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TeacherHome(),
    TeacherFeatures(),
    TeacherProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher's Dashboard"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF007F5F), Color(0xFF00C9A7)],
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
            colors: [Color(0xFF007F5F), Color(0xFF00C9A7)],
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

// 🟢 HOME
class TeacherHome extends StatelessWidget {
  const TeacherHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE6FFF5), Color(0xFFC8F7E8)], // light green
        ),
      ),
      child: const Center(
        child: Text(
          "Teacher Dashboard Home",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

// 🟢 FEATURES
class TeacherFeatures extends StatelessWidget {
  const TeacherFeatures({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE6FFF5), Color(0xFFC8F7E8)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.82,
          children: [
            _featureCard(context, "assets/images/manage_student.png", "Manage Students", "Add / Edit Students", const ManageStudentsScreen()),
            _featureCard(context, "assets/images/manage_course_subject.png", "Manage Courses & Subjects", "Add / Edit Courses & Subjects", const ManageCoursesScreen()),
            _featureCard(context, "assets/images/manage_attendance.png", "Manage Attendance", "Track Attendance", const ManageAttendanceScreen()),
            _featureCard(context, "assets/images/manage_export.png", "Export", "Export Attendance", const ExportAttendanceScreen()),
          ],
        ),
      ),
    );
  }
}

Widget _featureCard(BuildContext context, String imagePath, String title, String desc, Widget screen) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
    },
    child: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFF007F5F), Color(0xFF00C9A7)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 90,
            width: 90,
            child: Image.asset(
              imagePath, fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(desc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    ),
  );
}

// 🟢 PROFILE
class TeacherProfile extends StatelessWidget {
  const TeacherProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE6FFF5), Color(0xFFC8F7E8)],
        ),
      ),
      child: Center(
        child: GestureDetector(
          onTap: () async {
            await FirebaseAuth.instance.signOut();

            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            }
          },
          child: const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text("Logout"),
            ),
          ),
        ),
      ),
    );
  }
}