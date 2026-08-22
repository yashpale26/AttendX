import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'export_attendance_screen.dart';
import '../slr_screens/login_screen.dart';

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

// 🟢 HOME (Dynamic Firebase Dashboard)
class TeacherHome extends StatefulWidget {
  const TeacherHome({super.key});

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const Color primaryGreen = Color(0xFF007F5F);

  @override
  Widget build(BuildContext context) {
    final String currentTeacherEmail = _auth.currentUser?.email ?? 'teacher@attendx.com';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE6FFF5), Color(0xFFC8F7E8)],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        color: primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Text(
                "Welcome, Teacher 👋",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                currentTeacherEmail,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade700,
                ),
              ),
              const SizedBox(height: 18),

              // Dynamic Firestore Statistics Cards
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('course_lists').snapshots(),
                builder: (context, courseSnap) {
                  final courseDocs = courseSnap.data?.docs ?? [];
                  final int totalCourses = courseDocs.length;

                  // Extract all unique students across courses
                  final Set<String> studentEmails = {};
                  final Set<String> subjectNames = {};

                  for (var doc in courseDocs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final List students = data['students'] ?? [];
                    final List subjects = data['subjects'] ?? [];

                    for (var s in students) {
                      studentEmails.add(s.toString());
                    }
                    for (var sub in subjects) {
                      subjectNames.add(sub.toString());
                    }
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('attendance').snapshots(),
                    builder: (context, attendanceSnap) {
                      final attendanceDocs = attendanceSnap.data?.docs ?? [];

                      // Count unique lecture sessions by date + course + subject + lectureNo
                      final Set<String> uniqueLectures = {};
                      for (var doc in attendanceDocs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final key = "${data['course']}_${data['subject']}_${data['date']}_${data['lectureNo']}";
                        uniqueLectures.add(key);
                      }

                      final int totalLectures = uniqueLectures.length;
                      final int totalStudents = studentEmails.isNotEmpty ? studentEmails.length : 0;
                      final int totalSubjects = subjectNames.isNotEmpty ? subjectNames.length : 0;

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _statCard("👥 Students", "$totalStudents")),
                              const SizedBox(width: 12),
                              Expanded(child: _statCard("📚 Courses", "$totalCourses")),
                            ],
                          ),
                          const SizedBox(width: 12, height: 12),
                          Row(
                            children: [
                              Expanded(child: _statCard("📖 Subjects", "$totalSubjects")),
                              const SizedBox(width: 12),
                              Expanded(child: _statCard("📝 Lectures", "$totalLectures")),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),

              // Recent Attendance Section
              Text(
                "Recent Attendance",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade900,
                ),
              ),
              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('attendance')
                    .orderBy('createdAt', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: primaryGreen));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "No recent attendance recorded.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  // Group recent document entries into single session blocks
                  final Map<String, List<Map<String, dynamic>>> groupedSessions = {};
                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final sessionKey = "${data['course']}_${data['subject']}_${data['date']}_${data['lectureNo']}";
                    groupedSessions.putIfAbsent(sessionKey, () => []).add(data);
                  }

                  final String latestKey = groupedSessions.keys.first;
                  final List<Map<String, dynamic>> latestSessionLogs = groupedSessions[latestKey]!;
                  final Map<String, dynamic> sampleLog = latestSessionLogs.first;

                  final int presentCount = latestSessionLogs.where((d) => (d['status'] ?? 'Present') == 'Present').length;
                  final double pct = (presentCount / latestSessionLogs.length) * 100;

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  sampleLog['course'] ?? 'Course',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "Attendance: ${pct.toStringAsFixed(0)}%",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sampleLog['subject'] ?? 'Subject',
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                "${sampleLog['date'] ?? ''} • ${sampleLog['timeSlot'] ?? ''}",
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Quick Access Navigation
              Text(
                "Quick Access",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade900,
                ),
              ),
              const SizedBox(height: 10),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.2,
                children: [
                  _quickAccessButton(context, "Students", Icons.group_rounded, const ManageStudentsScreen()),
                  _quickAccessButton(context, "Courses", Icons.book_rounded, const ManageCoursesScreen()),
                  _quickAccessButton(context, "Attendance", Icons.fact_check_rounded, const ManageAttendanceScreen()),
                  _quickAccessButton(context, "Export", Icons.ios_share_rounded, const ExportAttendanceScreen()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String count) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            count,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryGreen),
          ),
        ],
      ),
    );
  }

  Widget _quickAccessButton(BuildContext context, String label, IconData icon, Widget screen) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF007F5F), Color(0xFF00C9A7)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
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
    final String currentTeacherEmail = FirebaseAuth.instance.currentUser?.email ?? 'Teacher Account';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE6FFF5), Color(0xFFC8F7E8)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF007F5F), Color(0xFF00C9A7)],
                  ),
                ),
                child: const Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                "Teacher Account",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                currentTeacherEmail,
                style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 30),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
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
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          "Logout",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}