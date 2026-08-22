import 'package:flutter/material.dart';
import '../../widgets/feature_app_bar.dart';
import 'create_attendance_screen.dart';
import 'view_attendance_screen.dart';

class ManageAttendanceScreen extends StatelessWidget {
  const ManageAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: featureAppBar("Manage Attendance", context),
      body: Container(
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
              _attendanceCard(
                context,
                "assets/images/create_attendance.png", // 👈 Update with your image path
                "Create Attendance",
                "Take New Attendance",
                const CreateAttendanceScreen(),
              ),
              _attendanceCard(
                context,
                "assets/images/view_attendance.png", // 👈 Update with your image path
                "View Attendance",
                "View Saved Records",
                const ViewAttendanceScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attendanceCard(BuildContext context, String imagePath, String title,
      String desc, Widget screen) {
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
                imagePath,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}