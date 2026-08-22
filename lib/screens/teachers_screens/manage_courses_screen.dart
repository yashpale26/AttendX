import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/feature_app_bar.dart';

class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  // Pre-populated courses list
  List<String> availableCourses = [
    "MSC Artificial Intelligence",
    "MSC Data Science",
    "MSC Information Technology",
  ];

  // Selected state for form
  String? selectedCourse;
  List<String> availableSubjects = [];
  List<String> selectedSubjects = [];

  // Students list from manage student screen logic
  List<Map<String, dynamic>> allStudents = [];
  List<String> selectedStudentEmails = [];

  bool isLoadingStudents = true;
  bool isSavingList = false;

  // Editing state ID (if editing existing list)
  String? editingDocId;

  final TextEditingController _customCourseController = TextEditingController();
  final TextEditingController _customSubjectController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  @override
  void dispose() {
    _customCourseController.dispose();
    _customSubjectController.dispose();
    super.dispose();
  }

  // Fetch student accounts using same logic from ManageStudentsScreen
  Future<void> _fetchStudents() async {
    setState(() => isLoadingStudents = true);
    try {
      final QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('users').get();

      List<Map<String, dynamic>> fetched = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id;
        String role = (data['role'] ?? '').toString().toLowerCase();
        String email = (data['email'] ?? '').toString().toLowerCase();

        if (role == 'student' || email.contains('student')) {
          fetched.add(data);
        }
      }

      setState(() {
        allStudents = fetched;
        isLoadingStudents = false;
      });
    } catch (e) {
      setState(() => isLoadingStudents = false);
    }
  }

  // Dialog to add a custom course
  void _showAddCourseDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add New Course"),
        content: TextField(
          controller: _customCourseController,
          decoration: const InputDecoration(
            labelText: "Course Name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _customCourseController.clear();
              Navigator.pop(ctx);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              String newCourse = _customCourseController.text.trim();
              if (newCourse.isNotEmpty) {
                setState(() {
                  if (!availableCourses.contains(newCourse)) {
                    availableCourses.add(newCourse);
                  }
                  selectedCourse = newCourse;
                });
                _customCourseController.clear();
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C9A7),
            ),
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Dialog to add a new subject
  void _showAddSubjectDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add New Subject"),
        content: TextField(
          controller: _customSubjectController,
          decoration: const InputDecoration(
            labelText: "Subject Name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _customSubjectController.clear();
              Navigator.pop(ctx);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              String newSub = _customSubjectController.text.trim();
              if (newSub.isNotEmpty) {
                setState(() {
                  if (!availableSubjects.contains(newSub)) {
                    availableSubjects.add(newSub);
                  }
                  if (!selectedSubjects.contains(newSub)) {
                    selectedSubjects.add(newSub);
                  }
                });
                _customSubjectController.clear();
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C9A7),
            ),
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Save or Update list in Firestore
  Future<void> _saveCourseList() async {
    if (selectedCourse == null || selectedCourse!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a course")),
      );
      return;
    }

    if (selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one subject")),
      );
      return;
    }

    if (selectedStudentEmails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one student")),
      );
      return;
    }

    setState(() => isSavingList = true);

    try {
      final data = {
        'course': selectedCourse,
        'subjects': selectedSubjects,
        'students': selectedStudentEmails,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (editingDocId != null) {
        await FirebaseFirestore.instance
            .collection('course_lists')
            .doc(editingDocId)
            .update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('course_lists').add(data);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(editingDocId != null
              ? "Course list updated successfully!"
              : "New course list created successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      _clearForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving list: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isSavingList = false);
    }
  }

  void _clearForm() {
    setState(() {
      selectedCourse = null;
      selectedSubjects.clear();
      selectedStudentEmails.clear();
      editingDocId = null;
    });
  }

  // Delete saved list from Firestore
  Future<void> _deleteCourseList(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('course_lists')
          .doc(docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Course list deleted successfully!"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete list: $e")),
        );
      }
    }
  }

  // Load selected list into form for editing
  void _editCourseList(Map<String, dynamic> docData, String docId) {
    setState(() {
      editingDocId = docId;
      selectedCourse = docData['course'];
      selectedSubjects = List<String>.from(docData['subjects'] ?? []);
      selectedStudentEmails = List<String>.from(docData['students'] ?? []);

      for (var sub in selectedSubjects) {
        if (!availableSubjects.contains(sub)) {
          availableSubjects.add(sub);
        }
      }

      if (selectedCourse != null &&
          !availableCourses.contains(selectedCourse)) {
        availableCourses.add(selectedCourse!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: featureAppBar("Manage Courses & Subjects", context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Course Selection Dropdown + Add Course
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Course Selection",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _showAddCourseDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add Course"),
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              value: selectedCourse,
              hint: const Text("Select Course"),
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: availableCourses.map((course) {
                return DropdownMenuItem(
                  value: course,
                  child: Text(course),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => selectedCourse = val);
              },
            ),

            const SizedBox(height: 20),

            // 2. Subjects Selection Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Subjects Selection",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _showAddSubjectDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add Subject"),
                ),
              ],
            ),
            if (availableSubjects.isEmpty)
              const Text(
                "No subjects added yet. Click 'Add Subject' to create choices.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              )
            else
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: availableSubjects.map((subject) {
                  final isSelected = selectedSubjects.contains(subject);
                  return FilterChip(
                    label: Text(subject),
                    selected: isSelected,
                    selectedColor: const Color(0xFF00C9A7).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF007F5F),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          selectedSubjects.add(subject);
                        } else {
                          selectedSubjects.remove(subject);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

            const SizedBox(height: 20),

            // 3. Students Selection List Section
            const Text(
              "Select Students",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: isLoadingStudents
                  ? const Center(child: CircularProgressIndicator())
                  : allStudents.isEmpty
                  ? const Center(child: Text("No students available"))
                  : ListView.builder(
                itemCount: allStudents.length,
                itemBuilder: (context, index) {
                  final student = allStudents[index];
                  final String email = student['email'] ?? 'No Email';
                  final bool isSelected =
                  selectedStudentEmails.contains(email);

                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(email),
                    dense: true,
                    activeColor: const Color(0xFF00C9A7),
                    onChanged: (bool? checked) {
                      setState(() {
                        if (checked == true) {
                          selectedStudentEmails.add(email);
                        } else {
                          selectedStudentEmails.remove(email);
                        }
                      });
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // 4. Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007F5F), Color(0xFF00C9A7)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: isSavingList ? null : _saveCourseList,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: isSavingList
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    editingDocId != null
                        ? "Update List"
                        : "Save / Create List",
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Divider(thickness: 1.5),
            const SizedBox(height: 10),

            // 5. Saved Lists Section
            const Text(
              "Saved Course Lists",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('course_lists')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text(
                    "No saved lists found.",
                    style: TextStyle(color: Colors.grey),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;

                    final String courseTitle = data['course'] ?? 'No Title';
                    final List subjects = data['subjects'] ?? [];
                    final List students = data['students'] ?? [];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          "Title: $courseTitle",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF007F5F),
                          ),
                        ),
                        subtitle: Text(
                          "Subjects: ${subjects.join(', ')}",
                          style: const TextStyle(fontSize: 13),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Students List:",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                const SizedBox(height: 6),
                                ...students.asMap().entries.map((entry) {
                                  return Text(
                                    "${entry.key + 1}. ${entry.value}",
                                    style: const TextStyle(fontSize: 13),
                                  );
                                }),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () =>
                                          _editCourseList(data, docId),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _deleteCourseList(docId),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}