import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'individual_student_screen.dart';

class StudentListScreen extends StatefulWidget {
  final String? courseName;

  const StudentListScreen({super.key, this.courseName});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  late TextEditingController _searchController;
  String activeSearchQuery = ''; // Applied only on button click or submitted
  String? selectedCourse;
  String selectedFilter = 'All'; // 'All', 'Above 75%', 'Below 75%', 'Below 50%'

  final List<String> filterOptions = ['All', 'Above 75%', 'Below 75%', 'Below 50%'];

  @override
  void initState() {
    super.initState();
    selectedCourse = widget.courseName;
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _executeSearch() {
    setState(() {
      activeSearchQuery = _searchController.text.trim();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      activeSearchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Students"),
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('course_lists').snapshots(),
          builder: (context, courseSnapshot) {
            if (courseSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final courseDocs = courseSnapshot.data?.docs ?? [];
            final courses = courseDocs
                .map((d) => (d.data() as Map<String, dynamic>)['course'] as String?)
                .whereType<String>()
                .toSet()
                .toList();

            if (courses.isNotEmpty && (selectedCourse == null || !courses.contains(selectedCourse))) {
              selectedCourse = courses.first;
            }

            final matchedDocs = courseDocs.where(
                  (doc) => (doc.data() as Map<String, dynamic>)['course'] == selectedCourse,
            );

            final Map<String, dynamic> courseData = matchedDocs.isNotEmpty
                ? matchedDocs.first.data() as Map<String, dynamic>
                : {};

            final List enrolledStudents = courseData['students'] ?? [];

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('attendance')
                  .where('course', isEqualTo: selectedCourse)
                  .snapshots(),
              builder: (context, attendanceSnapshot) {
                if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final attendanceDocs = attendanceSnapshot.data?.docs ?? [];

                // Calculate per-student attendance stats
                Map<String, Map<String, int>> studentStats = {};

                for (var doc in attendanceDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final studentId = data['studentId'] ?? data['studentEmail'] ?? data['studentName'] ?? '';
                  final status = data['status'] ?? 'Present';

                  if (studentId.toString().isNotEmpty) {
                    studentStats.putIfAbsent(studentId.toString(), () => {'present': 0, 'total': 0});
                    studentStats[studentId.toString()]!['total'] = studentStats[studentId.toString()]!['total']! + 1;
                    if (status == 'Present') {
                      studentStats[studentId.toString()]!['present'] = studentStats[studentId.toString()]!['present']! + 1;
                    }
                  }
                }

                // Parse student list
                List<Map<String, dynamic>> parsedStudentList = [];

                for (var student in enrolledStudents) {
                  String name = '';
                  String email = '';
                  String key = '';

                  if (student is Map) {
                    name = student['name'] ?? '';
                    email = student['email'] ?? '';
                    key = email.isNotEmpty ? email : name;
                  } else {
                    key = student.toString();
                    if (key.contains('@')) {
                      email = key;
                      name = key.split('@').first;
                    } else {
                      name = key;
                    }
                  }

                  int present = studentStats[key]?['present'] ?? studentStats[email]?['present'] ?? studentStats[name]?['present'] ?? 0;
                  int total = studentStats[key]?['total'] ?? studentStats[email]?['total'] ?? studentStats[name]?['total'] ?? 0;
                  double pct = total > 0 ? (present / total) * 100 : 0.0;

                  parsedStudentList.add({
                    'name': name.isEmpty ? email : name,
                    'email': email,
                    'percentage': pct,
                    'present': present,
                    'total': total,
                  });
                }

                // Filter Student List in-memory only against activeSearchQuery
                final filteredList = parsedStudentList.where((student) {
                  final nameMatch = student['name'].toString().toLowerCase().contains(activeSearchQuery.toLowerCase());
                  final emailMatch = student['email'].toString().toLowerCase().contains(activeSearchQuery.toLowerCase());
                  final matchesSearch = nameMatch || emailMatch;

                  double pct = student['percentage'];
                  bool matchesFilter = true;

                  if (selectedFilter == 'Above 75%') {
                    matchesFilter = pct >= 75;
                  } else if (selectedFilter == 'Below 75%') {
                    matchesFilter = pct < 75;
                  } else if (selectedFilter == 'Below 50%') {
                    matchesFilter = pct < 50;
                  }

                  return matchesSearch && matchesFilter;
                }).toList();

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // 1. Course Selection Dropdown Card
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCourse,
                            isExpanded: true,
                            hint: const Text("Select Course"),
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF007F5F)),
                            items: courses.map((course) {
                              return DropdownMenuItem<String>(
                                value: course,
                                child: Text(
                                  course,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF007F5F),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedCourse = val;
                              });
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 2. Selected Course Summary Card
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF007F5F), Color(0xFF00C9A7)],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedCourse ?? "No Course Selected",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Enrolled Students: ${enrolledStudents.length}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.school, color: Colors.white, size: 32),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 3. Search Field with explicit Search Icon Button on the right
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _executeSearch(),
                        decoration: InputDecoration(
                          hintText: "Search student name or email...",
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (activeSearchQuery.isNotEmpty || _searchController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: _clearSearch,
                                ),
                              IconButton(
                                icon: const Icon(Icons.search, color: Color(0xFF007F5F)),
                                onPressed: _executeSearch,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 4. Attendance Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: filterOptions.map((filter) {
                          final isSelected = selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(filter),
                              selected: isSelected,
                              selectedColor: const Color(0xFF007F5F),
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF007F5F),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => selectedFilter = filter);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 5. Scrollable Student List
                    filteredList.isEmpty
                        ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          "No students match your criteria.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                        : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final student = filteredList[index];
                        final double pct = student['percentage'];

                        Color indicatorBg = Colors.green.shade100;
                        Color indicatorText = Colors.green.shade900;

                        if (pct < 50) {
                          indicatorBg = Colors.red.shade100;
                          indicatorText = Colors.red.shade900;
                        } else if (pct < 75) {
                          indicatorBg = Colors.orange.shade100;
                          indicatorText = Colors.orange.shade900;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => IndividualStudentScreen(
                                      studentName: student['name'],
                                      studentEmail: student['email'],
                                      courseName: selectedCourse ?? widget.courseName ?? '',
                                    ),
                                  ),
                                );
                              },
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF007F5F),
                              foregroundColor: Colors.white,
                              radius: 18,
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              student['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: student['email'].toString().isNotEmpty
                                ? Text(
                              student['email'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            )
                                : null,
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: indicatorBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${pct.toStringAsFixed(1)}%",
                                style: TextStyle(
                                  color: indicatorText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}