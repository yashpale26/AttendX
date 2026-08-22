import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/feature_app_bar.dart';
import 'add_student_screen.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  List<Map<String, dynamic>> studentList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  // Fetch student accounts from Firestore filtered by role or email matching "student"
  Future<void> _fetchStudents() async {
    setState(() => isLoading = true);
    try {
      final QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('users').get();

      List<Map<String, dynamic>> fetched = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id;
        String role = (data['role'] ?? '').toString().toLowerCase();
        String email = (data['email'] ?? '').toString().toLowerCase();

        // Filter student role accounts or emails containing "student"
        if (role == 'student' || email.contains('student')) {
          fetched.add(data);
        }
      }

      setState(() {
        studentList = fetched;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching students: $e")),
        );
      }
    }
  }

  // Refresh student list and show notification
  Future<void> _refreshStudents() async {
    await _fetchStudents();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Refreshed successfully"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Remove student from Firestore user collection
  Future<void> _deleteStudent(String docId, String email) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).delete();
      await _fetchStudents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Account ($email) removed successfully from list"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to remove user: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: featureAppBar("Manage Students", context),
      body: Column(
        children: [
          // Scrollable student list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : studentList.isEmpty
                ? const Center(child: Text("No student users found."))
                : ListView.builder(
              itemCount: studentList.length,
              itemBuilder: (context, index) {
                final student = studentList[index];
                final String email = student['email'] ?? 'No Email';
                final String name = student['name'] ?? '';

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF00C9A7),
                      foregroundColor: Colors.white,
                      child: Text("${index + 1}"),
                    ),
                    title: Text(
                      email,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: name.isNotEmpty ? Text(name) : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Delete Account"),
                            content: Text(
                                "Are you sure you want to delete $email from the student list?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _deleteStudent(
                                      student['docId'], email);
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                child: const Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Action Bar: Add & Refresh Buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                )
              ],
            ),
            child: Row(
              children: [
                // Add Button (Green Gradient)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF007F5F), Color(0xFF00C9A7)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddStudentUsersScreen(),
                          ),
                        );
                        _fetchStudents(); // Auto refresh on returning
                      },
                      icon: const Icon(Icons.person_add, color: Colors.white),
                      label: const Text("Add", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Refresh Button (Blue Gradient)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE6F0FF), Color(0xFFCFE2FF)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _refreshStudents,
                      icon: const Icon(Icons.refresh, color: Color(0xFF007CF0)),
                      label: const Text("Refresh", style: TextStyle(color: Color(0xFF007CF0), fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}