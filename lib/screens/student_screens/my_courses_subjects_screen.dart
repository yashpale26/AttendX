import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyCoursesSubjectsScreen extends StatefulWidget {
  const MyCoursesSubjectsScreen({super.key});

  @override
  State<MyCoursesSubjectsScreen> createState() =>
      _MyCoursesSubjectsScreenState();
}

class _MyCoursesSubjectsScreenState extends State<MyCoursesSubjectsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Color primaryBlue = Color(0xFF004AAD);
  static const Color secondaryBlue = Color(0xFF007CF0);

  @override
  Widget build(BuildContext context) {
    final String currentStudentEmail = _auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Courses & Subjects"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, secondaryBlue],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE6F0FF), Color(0xFFCFE2FF)],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('course_lists')
              .where('students', arrayContains: currentStudentEmail)
              .snapshots(),
          builder: (context, courseSnapshot) {
            if (courseSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryBlue),
              );
            }

            final courseDocs = courseSnapshot.data?.docs ?? [];

            if (courseDocs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "You are not enrolled in any course yet.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }

            return StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('attendance')
                  .where('studentEmail', isEqualTo: currentStudentEmail)
                  .snapshots(),
              builder: (context, attendanceSnapshot) {
                if (attendanceSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  );
                }

                final attendanceDocs = attendanceSnapshot.data?.docs ?? [];

                // Calculate Subject Attendance Statistics
                final Map<String, List<int>> subjectStats = {};
                for (var doc in attendanceDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final subject = data['subject']?.toString() ?? '';
                  final status = data['status']?.toString() ?? 'Absent';

                  if (subject.isNotEmpty) {
                    subjectStats.putIfAbsent(subject, () => [0, 0]);
                    subjectStats[subject]![1] += 1; // Total
                    if (status == 'Present') {
                      subjectStats[subject]![0] += 1; // Present
                    }
                  }
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: courseDocs.length,
                  itemBuilder: (context, index) {
                    final courseData =
                    courseDocs[index].data() as Map<String, dynamic>;
                    final String courseName =
                        courseData['course']?.toString() ?? 'Enrolled Course';

                    // Updated to fetch teacherEmail dynamically from Firestore document
                    final String teacherEmail = courseData['teacherEmail']?.toString() ??
                        courseData['teacher_email']?.toString() ??
                        courseData['createdBy']?.toString() ??
                        'N/A';
                    final List subjects = courseData['subjects'] ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Course Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [primaryBlue, secondaryBlue],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                courseName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.email_outlined,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "Teacher: $teacherEmail",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        // ... (remaining subjects list UI remains unchanged)

                        // Subjects List
                        if (subjects.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0, bottom: 16.0),
                            child: Text(
                              "No subjects assigned to this course.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: subjects.length,
                            itemBuilder: (context, subIndex) {
                              final String subjectName =
                              subjects[subIndex].toString();
                              final stats = subjectStats[subjectName] ?? [0, 0];
                              final int present = stats[0];
                              final int total = stats[1];
                              final double percentage =
                              total > 0 ? (present / total) * 100 : 0.0;

                              final bool isEligible = percentage >= 75.0;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              subjectName,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: total == 0
                                                  ? Colors.grey.shade100
                                                  : (isEligible
                                                  ? Colors.green.shade50
                                                  : Colors.red.shade50),
                                              borderRadius:
                                              BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              total == 0
                                                  ? "N/A"
                                                  : "${percentage.toStringAsFixed(1)}%",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: total == 0
                                                    ? Colors.grey
                                                    : (isEligible
                                                    ? Colors.green.shade700
                                                    : Colors.red.shade700),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Attendance: $present / $total Lectures",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: total > 0 ? (present / total) : 0,
                                          backgroundColor: Colors.grey.shade200,
                                          color: isEligible
                                              ? secondaryBlue
                                              : Colors.redAccent,
                                          minHeight: 6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}