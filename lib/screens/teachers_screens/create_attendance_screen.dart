import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CreateAttendanceScreen extends StatefulWidget {
  const CreateAttendanceScreen({super.key});

  @override
  State<CreateAttendanceScreen> createState() => _CreateAttendanceScreenState();
}

class _CreateAttendanceScreenState extends State<CreateAttendanceScreen> {
  // Selected values
  String? selectedDocId;
  String? selectedCourseTitle;
  String? selectedSubject;

  List<String> availableSubjects = [];
  List<String> fetchedStudentEmails = [];

  // Attendance status mapping: Email -> 'Present' / 'Absent'
  Map<String, String> attendanceStatuses = {};

  // Time & Date State
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  DateTime selectedDate = DateTime.now();

  // Lecture Number Controller
  final TextEditingController _lectureNoController = TextEditingController();

  bool isSaving = false;

  @override
  void dispose() {
    _lectureNoController.dispose();
    super.dispose();
  }

  // Pick Start & End Time
  Future<void> _selectTimeRange() async {
    final TimeOfDay? pickedStart = await showTimePicker(
      context: context,
      initialTime: startTime ?? const TimeOfDay(hour: 10, minute: 0),
      helpText: "Select Start Time",
    );

    if (pickedStart != null) {
      if (!mounted) return;
      final TimeOfDay? pickedEnd = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: (pickedStart.hour + 1) % 24,
          minute: pickedStart.minute,
        ),
        helpText: "Select End Time",
      );

      if (pickedEnd != null) {
        setState(() {
          startTime = pickedStart;
          endTime = pickedEnd;
        });
      }
    }
  }

  // Pick Date
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Handle Course Selection & Update Subjects/Students List
  void _onCourseSelected(String? docId, List<QueryDocumentSnapshot> docs) {
    if (docId == null) return;

    final doc = docs.firstWhere((element) => element.id == docId);
    final data = doc.data() as Map<String, dynamic>;
    final List subjects = data['subjects'] ?? [];
    final List students = data['students'] ?? [];

    setState(() {
      selectedDocId = docId;
      selectedCourseTitle = data['course'] ?? '';
      selectedSubject = null; // reset subject selection
      availableSubjects = List<String>.from(subjects);
      fetchedStudentEmails = List<String>.from(students);

      // Default all students to "Present"
      attendanceStatuses = {
        for (var email in fetchedStudentEmails) email: 'Present'
      };
    });
  }

  // Save Attendance Records to Firestore
  Future<void> _markAttendance() async {
    if (selectedCourseTitle == null || selectedCourseTitle!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a course list")),
      );
      return;
    }

    if (selectedSubject == null || selectedSubject!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a subject")),
      );
      return;
    }

    if (_lectureNoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter lecture number")),
      );
      return;
    }

    if (startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select lecture time range")),
      );
      return;
    }

    if (fetchedStudentEmails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No students found in selected course list")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      final String timeSlot =
          "${startTime!.format(context)} to ${endTime!.format(context)}";
      final int? lectureNo = int.tryParse(_lectureNoController.text.trim());

      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Create an individual record for each student for querying later
      for (String email in fetchedStudentEmails) {
        DocumentReference docRef =
        FirebaseFirestore.instance.collection('attendance').doc();

        batch.set(docRef, {
          'studentEmail': email,
          'course': selectedCourseTitle,
          'subject': selectedSubject,
          'lectureNo': lectureNo ?? _lectureNoController.text.trim(),
          'date': formattedDate,
          'timestamp': Timestamp.fromDate(selectedDate),
          'timeSlot': timeSlot,
          'status': attendanceStatuses[email] ?? 'Present',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Attendance marked successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      // Reset selection state
      setState(() {
        selectedDocId = null;
        selectedCourseTitle = null;
        selectedSubject = null;
        availableSubjects.clear();
        fetchedStudentEmails.clear();
        attendanceStatuses.clear();
        startTime = null;
        endTime = null;
        _lectureNoController.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to mark attendance: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    final String timeText = (startTime != null && endTime != null)
        ? "${startTime!.format(context)} to ${endTime!.format(context)}"
        : "Select Time Range";

    // Summary Analytics Calculations
    final int totalStudents = fetchedStudentEmails.length;
    final int presentCount =
        attendanceStatuses.values.where((status) => status == 'Present').length;
    final int absentCount =
        attendanceStatuses.values.where((status) => status == 'Absent').length;
    final double attendancePercentage =
    totalStudents > 0 ? (presentCount / totalStudents) * 100 : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Attendance"),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Select Saved Course List
            const Text(
              "Names of Saved Course List",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('course_lists')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text(
                    "No saved course lists available.",
                    style: TextStyle(color: Colors.grey),
                  );
                }

                final docs = snapshot.data!.docs;

                // Validate if selectedDocId still exists in the fetched documents
                final bool docExists = docs.any((doc) => doc.id == selectedDocId);
                final String? dropdownValue = docExists ? selectedDocId : null;

                return DropdownButtonFormField<String>(
                  value: dropdownValue,
                  hint: const Text("Select Saved Course List"),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['course'] ?? 'Untitled Course';
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(title),
                    );
                  }).toList(),
                  onChanged: (docId) => _onCourseSelected(docId, docs),
                );
              },
            ),

            const SizedBox(height: 18),

            // 2. Select Subject Dropdown
            const Text(
              "Select Subject",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: selectedSubject,
              hint: Text(availableSubjects.isEmpty
                  ? "Select Course First"
                  : "Select Subject"),
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: availableSubjects.map((subject) {
                return DropdownMenuItem<String>(
                  value: subject,
                  child: Text(subject),
                );
              }).toList(),
              onChanged: availableSubjects.isEmpty
                  ? null
                  : (val) {
                setState(() => selectedSubject = val);
              },
            ),

            const SizedBox(height: 18),

            // NEW: Lecture No Field
            const Text(
              "Lecture No.",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _lectureNoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "e.g. 1",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.format_list_numbered),
                contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),

            const SizedBox(height: 18),

            // 3. Time Picker Field
            const Text(
              "Lecture Time Range",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _selectTimeRange,
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                child: Text(
                  timeText,
                  style: TextStyle(
                    color: startTime == null ? Colors.grey.shade600 : Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 4. Date Picker Field
            const Text(
              "Select Date",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                child: Text(formattedDate),
              ),
            ),

            const SizedBox(height: 24),

            // 5. Student List Header & Rows
            const Text(
              "Students List",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (fetchedStudentEmails.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Text(
                  "Select a course list above to populate students.",
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE6FFF5),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text("Sr.No",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            child: Text("Student Email",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(
                            width: 140,
                            child: Center(
                              child: Text("Status",
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),

                    // Student Rows
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: fetchedStudentEmails.length,
                      separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final email = fetchedStudentEmails[index];
                        final currentStatus =
                            attendanceStatuses[email] ?? 'Present';

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 40,
                                child: Text("${index + 1}"),
                              ),
                              Expanded(
                                child: Text(
                                  email,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 140,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Present Radio
                                    Row(
                                      children: [
                                        Radio<String>(
                                          value: 'Present',
                                          groupValue: currentStatus,
                                          activeColor: const Color(0xFF007F5F),
                                          visualDensity: VisualDensity.compact,
                                          onChanged: (val) {
                                            setState(() {
                                              attendanceStatuses[email] = val!;
                                            });
                                          },
                                        ),
                                        const Text("P",
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(width: 8),

                                    // Absent Radio
                                    Row(
                                      children: [
                                        Radio<String>(
                                          value: 'Absent',
                                          groupValue: currentStatus,
                                          activeColor: Colors.redAccent,
                                          visualDensity: VisualDensity.compact,
                                          onChanged: (val) {
                                            setState(() {
                                              attendanceStatuses[email] = val!;
                                            });
                                          },
                                        ),
                                        const Text("A",
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

            // NEW: Attendance Summary Section
            if (fetchedStudentEmails.isNotEmpty) ...[
              const SizedBox(height: 18),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Attendance Summary",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF007F5F),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Students:",
                              style: TextStyle(fontSize: 13)),
                          Text("$totalStudents",
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Present:",
                              style: TextStyle(fontSize: 13)),
                          Text("$presentCount",
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Absent:", style: TextStyle(fontSize: 13)),
                          Text("$absentCount",
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent)),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Attendance:",
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                          Text("${attendancePercentage.toStringAsFixed(2)}%",
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF007F5F))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 6. Mark Attendance Button
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
                  onPressed: isSaving ? null : _markAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Mark Attendance",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}