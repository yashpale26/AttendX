import 'package:flutter/material.dart';
import 'course_overview_screen.dart';
import 'student_list_screen.dart';
// import 'individual_student_screen.dart';

class ViewAttendanceScreen extends StatelessWidget {
  const ViewAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Attendance"),
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
                "assets/images/course_overview.png", // 👈 Update with your image path
                "Course Overview",
                "View Course Stats",
                const CourseOverviewScreen(),
              ),
              _attendanceCard(
                context,
                "assets/images/student_list.png", // 👈 Update with your image path
                "Student List",
                "View Students",
                const StudentListScreen(),
              ),
              // _attendanceCard(
              //   context,
              //   "assets/images/individual_student.png", // 👈 Update with your image path
              //   "Individual Student",
              //   "View Student Profile",
              //   const IndividualStudentScreen(studentName: '', studentEmail: '', courseName: '',),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attendanceCard(
      BuildContext context,
      String imagePath,
      String title,
      String desc,
      Widget targetScreen,
      ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => targetScreen),
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
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image,
                    size: 50,
                    color: Colors.white70,
                  );
                },
              ),
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