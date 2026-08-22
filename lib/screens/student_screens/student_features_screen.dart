import 'package:flutter/material.dart';
import 'my_attendance_screen.dart';
import 'my_courses_subjects_screen.dart';

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.82,
          children: [
            _featureCard(
              context,
              "assets/images/my_attendance.png", // image path left blank for later
              "My Attendance",
              "View Attendance Record",
              const MyAttendanceScreen(),
            ),
            _featureCard(
              context,
              "assets/images/my_coursesANDsubjects.png", // image path left blank for later
              "My Courses & Subjects",
              "View Enrolled Courses",
              const MyCoursesSubjectsScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureCard(
      BuildContext context,
      String imagePath,
      String title,
      String desc,
      Widget screen,
      ) {
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
            colors: [Color(0xFF004AAD), Color(0xFF007CF0)],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 90,
              width: 90,
              child: imagePath.isNotEmpty
                  ? Image.asset(imagePath, fit: BoxFit.contain)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}