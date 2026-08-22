import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_features_screen.dart';
import 'student_profile_screen.dart';

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
class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const Color primaryBlue = Color(0xFF004AAD);

  @override
  Widget build(BuildContext context) {
    final String currentStudentEmail = _auth.currentUser?.email ?? 'student@attendx.com';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE6F0FF), Color(0xFFCFE2FF)], // light blue
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        color: primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Welcome Section
              Text(
                "Welcome, Student 👋",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                currentStudentEmail,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 18),

              // Firebase Real-time Calculations
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('course_lists').snapshots(),
                builder: (context, courseSnap) {
                  final courseDocs = courseSnap.data?.docs ?? [];

                  // Extract course and subject names where student email is present
                  final Set<String> enrolledCourses = {};
                  final Set<String> enrolledSubjects = {};

                  for (var doc in courseDocs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final List students = data['students'] ?? [];
                    if (students.contains(currentStudentEmail)) {
                      if (data['courseName'] != null) {
                        enrolledCourses.add(data['courseName'].toString());
                      }
                      final List subjects = data['subjects'] ?? [];
                      for (var sub in subjects) {
                        enrolledSubjects.add(sub.toString());
                      }
                    }
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('attendance')
                        .where('studentEmail', isEqualTo: currentStudentEmail)
                        .snapshots(),
                    builder: (context, attendanceSnap) {
                      final attendanceDocs = attendanceSnap.data?.docs ?? [];

                      int totalPresent = 0;
                      int totalLectures = attendanceDocs.length;
                      final Map<String, int> subjectTotal = {};
                      final Map<String, int> subjectPresent = {};

                      for (var doc in attendanceDocs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final String subject = data['subject'] ?? 'General';
                        final String status = data['status'] ?? 'Absent';

                        subjectTotal[subject] = (subjectTotal[subject] ?? 0) + 1;

                        if (status == 'Present') {
                          totalPresent++;
                          subjectPresent[subject] = (subjectPresent[subject] ?? 0) + 1;
                        }
                      }

                      final double overallPercentage = totalLectures > 0
                          ? (totalPresent / totalLectures) * 100
                          : 0.0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 2. Overall Attendance Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF004AAD), Color(0xFF007CF0)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withAlpha(30),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "Overall Attendance",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${overallPercentage.toStringAsFixed(1)}%",
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "$totalPresent Present / $totalLectures Lectures",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 3 & 4. Course Count & Subject Count
                          Row(
                            children: [
                              Expanded(
                                child: _statCard(
                                  "📚 Courses",
                                  "${enrolledCourses.length}",
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _statCard(
                                  "📖 Subjects",
                                  "${enrolledSubjects.length}",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 5. Subject Attendance Section
                          Text(
                            "Subject Attendance",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          const SizedBox(height: 10),

                          if (subjectTotal.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "No subject records found.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          else
                            Column(
                              children: subjectTotal.entries.map((entry) {
                                final subName = entry.key;
                                final subTotal = entry.value;
                                final subPres = subjectPresent[subName] ?? 0;
                                final double pct = subTotal > 0 ? (subPres / subTotal) : 0.0;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(10),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              subName,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            "${(pct * 100).toStringAsFixed(0)}%",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: primaryBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                        value: pct,
                                        backgroundColor: Colors.blue.shade50,
                                        valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue),
                                        minHeight: 6,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),

              // 6. Recent Attendance Section
              Text(
                "Recent Attendance",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('attendance')
                    .where('studentEmail', isEqualTo: currentStudentEmail)
                    .orderBy('createdAt', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryBlue),
                    );
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
                        "No recent attendance records available.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final String subject = data['subject'] ?? 'Subject';
                      final String date = data['date'] ?? '';
                      final String timeSlot = data['timeSlot'] ?? '';
                      final String status = data['status'] ?? 'Absent';
                      final bool isPresent = status == 'Present';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          title: Text(
                            subject,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            "$date • $timeSlot",
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPresent ? Colors.green.shade700 : Colors.red.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
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
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            count,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}