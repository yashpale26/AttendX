import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:excel_plus/excel_plus.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/feature_app_bar.dart';

enum ExportType { entireCourse, individualStudent }

enum AttendancePeriod { overall, thisMonth, thisWeek, customRange }

class ExportAttendanceScreen extends StatefulWidget {
  const ExportAttendanceScreen({super.key});

  @override
  State<ExportAttendanceScreen> createState() => _ExportAttendanceScreenState();
}

class _ExportAttendanceScreenState extends State<ExportAttendanceScreen> {
  // Theme Color Palette
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightBackground = Color(0xFFF1F8E9);
  static const Color cardBorderColor = Color(0xFFC8E6C9);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Selected Options
  DocumentSnapshot? selectedCourseDoc;
  ExportType selectedExportType = ExportType.entireCourse;
  String? selectedStudentEmail;
  AttendancePeriod selectedPeriod = AttendancePeriod.overall;
  DateTimeRange? customDateRange;

  bool isExporting = false;

  @override
  Widget build(BuildContext context) {
    final String currentTeacherEmail = _auth.currentUser?.email ?? 'Teacher';

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: featureAppBar("Export Attendance", context),
      body: StreamBuilder<QuerySnapshot>(
        // Pointing directly to your exact Firestore collection: 'course_lists'
        stream: _firestore.collection('course_lists').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryGreen));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error loading courses: ${snapshot.error}"));
          }

          final courseDocs = snapshot.data?.docs ?? [];

          if (courseDocs.isEmpty) {
            return const Center(
              child: Text(
                "No courses found in 'course_lists'.\nPlease add courses to continue.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          // Auto-select first course if selection is null or out of sync
          if (selectedCourseDoc == null ||
              !courseDocs.any((doc) => doc.id == selectedCourseDoc!.id)) {
            selectedCourseDoc = courseDocs.first;
          }

          final Map<String, dynamic> selectedCourseData =
          selectedCourseDoc!.data() as Map<String, dynamic>;

          // Extract Course Details (handling field variations)
          final String courseTitle = selectedCourseData['courseName'] ??
              selectedCourseData['course'] ??
              selectedCourseData['name'] ??
              selectedCourseDoc!.id;

          final List<dynamic> rawStudents = selectedCourseData['students'] ?? [];
          final List<String> studentList = rawStudents.map((e) => e.toString()).toList();

          final List<dynamic> rawSubjects = selectedCourseData['subjects'] ?? [];
          final List<String> subjectList = rawSubjects.map((e) => e.toString()).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Course Selection Card
                _buildSectionCard(
                  title: "Select Course",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<DocumentSnapshot>(
                            isExpanded: true,
                            value: courseDocs.firstWhere((d) => d.id == selectedCourseDoc!.id),
                            items: courseDocs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name = data['courseName'] ??
                                  data['course'] ??
                                  data['name'] ??
                                  doc.id;
                              return DropdownMenuItem<DocumentSnapshot>(
                                value: doc,
                                child: Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              );
                            }).toList(),
                            onChanged: (doc) {
                              if (doc != null) {
                                setState(() {
                                  selectedCourseDoc = doc;
                                  selectedStudentEmail = null;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Live Attendance Stats Stream based on field 'course'
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('attendance')
                            .where('course', isEqualTo: courseTitle)
                            .snapshots(),
                        builder: (context, attendanceSnapshot) {
                          final attendanceLogs = attendanceSnapshot.data?.docs ?? [];

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: cardBorderColor),
                            ),
                            child: Column(
                              children: [
                                _buildSummaryRow("Course Name:", courseTitle),
                                _buildSummaryRow("Enrolled Students:", "${studentList.length}"),
                                _buildSummaryRow("Total Attendance Entries:", "${attendanceLogs.length}"),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Export Type Selection
                _buildSectionCard(
                  title: "Export Type",
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildExportTypeCard(
                              type: ExportType.entireCourse,
                              icon: Icons.groups_rounded,
                              title: "Entire Course",
                              subtitle: "All Students",
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildExportTypeCard(
                              type: ExportType.individualStudent,
                              icon: Icons.person_rounded,
                              title: "Individual",
                              subtitle: "One Student",
                            ),
                          ),
                        ],
                      ),
                      if (selectedExportType == ExportType.individualStudent) ...[
                        const SizedBox(height: 16),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Select Student Email",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: studentList.contains(selectedStudentEmail)
                                  ? selectedStudentEmail
                                  : null,
                              hint: const Text("Choose Enrolled Student"),
                              items: studentList.map((email) {
                                return DropdownMenuItem<String>(
                                  value: email,
                                  child: Text(email),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedStudentEmail = val;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Period Filter Card
                _buildSectionCard(
                  title: "Attendance Period",
                  child: Column(
                    children: [
                      RadioListTile<AttendancePeriod>(
                        dense: true,
                        title: const Text("Overall (All Time)"),
                        value: AttendancePeriod.overall,
                        groupValue: selectedPeriod,
                        activeColor: primaryGreen,
                        onChanged: (val) => setState(() => selectedPeriod = val!),
                      ),
                      RadioListTile<AttendancePeriod>(
                        dense: true,
                        title: const Text("This Month"),
                        value: AttendancePeriod.thisMonth,
                        groupValue: selectedPeriod,
                        activeColor: primaryGreen,
                        onChanged: (val) => setState(() => selectedPeriod = val!),
                      ),
                      RadioListTile<AttendancePeriod>(
                        dense: true,
                        title: const Text("This Week"),
                        value: AttendancePeriod.thisWeek,
                        groupValue: selectedPeriod,
                        activeColor: primaryGreen,
                        onChanged: (val) => setState(() => selectedPeriod = val!),
                      ),
                      RadioListTile<AttendancePeriod>(
                        dense: true,
                        title: Text(
                          customDateRange == null
                              ? "Custom Date Range"
                              : "Custom: ${customDateRange!.start.toString().split(' ')[0]} to ${customDateRange!.end.toString().split(' ')[0]}",
                        ),
                        value: AttendancePeriod.customRange,
                        groupValue: selectedPeriod,
                        activeColor: primaryGreen,
                        onChanged: (val) async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              customDateRange = picked;
                              selectedPeriod = AttendancePeriod.customRange;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Configuration Summary Card
                _buildSectionCard(
                  title: "Export Configuration Summary",
                  child: Column(
                    children: [
                      _buildSummaryRow("Course", courseTitle),
                      if (selectedExportType == ExportType.individualStudent &&
                          selectedStudentEmail != null)
                        _buildSummaryRow("Selected Student", selectedStudentEmail!),
                      _buildSummaryRow("Export Mode",
                          selectedExportType == ExportType.entireCourse ? "Entire Course" : "Single Student"),
                      _buildSummaryRow("Period", selectedPeriod.name.toUpperCase()),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Export Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                  onPressed: (selectedExportType == ExportType.individualStudent &&
                      selectedStudentEmail == null) ||
                      isExporting
                      ? null
                      : () => _generateAndShareExcel(
                    courseTitle: courseTitle,
                    teacherEmail: currentTeacherEmail,
                    studentList: studentList,
                    subjectList: subjectList,
                  ),
                  child: isExporting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : Text(
                    selectedExportType == ExportType.entireCourse
                        ? "EXPORT ENTIRE COURSE TO EXCEL"
                        : "EXPORT STUDENT ATTENDANCE",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Dynamic Excel Generation matching your Firestore schema ---

  Future<void> _generateAndShareExcel({
    required String courseTitle,
    required String teacherEmail,
    required List<String> studentList,
    required List<String> subjectList,
  }) async {
    setState(() => isExporting = true);

    try {
      Query query = _firestore.collection('attendance').where('course', isEqualTo: courseTitle);

      final now = DateTime.now();
      if (selectedPeriod == AttendancePeriod.thisWeek) {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day)));
      } else if (selectedPeriod == AttendancePeriod.thisMonth) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(now.year, now.month, 1)));
      } else if (selectedPeriod == AttendancePeriod.customRange && customDateRange != null) {
        query = query
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(customDateRange!.start))
            .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(customDateRange!.end.add(const Duration(days: 1))));
      }

      final attendanceSnap = await query.get();
      final attendanceDocs = attendanceSnap.docs;

      final excel = Excel.createExcel();

      // 1. Remove default 'Sheet1'
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      final DateTime currentNow = DateTime.now();
      final String dateStr = "${currentNow.day}-${currentNow.month}-${currentNow.year}";

      if (selectedExportType == ExportType.entireCourse) {
        // Sheet 1: Attendance Log
        final Sheet sheet1 = excel['Attendance Log'];
        _appendHeader(sheet1, "ATTENDX - ATTENDANCE LOG", {
          "Course": courseTitle,
          "Total Records": "${attendanceDocs.length}",
          "Export Date": dateStr,
        });

        sheet1.appendRow([
          TextCellValue('Date'),
          TextCellValue('Subject'),
          TextCellValue('Lecture No.'),
          TextCellValue('Time Slot'),
          TextCellValue('Student Email'),
          TextCellValue('Status'),
        ]);

        for (var doc in attendanceDocs) {
          final data = doc.data() as Map<String, dynamic>;
          sheet1.appendRow([
            TextCellValue(data['date'] ?? ''),
            TextCellValue(data['subject'] ?? ''),
            TextCellValue("${data['lectureNo'] ?? ''}"),
            TextCellValue(data['timeSlot'] ?? ''),
            TextCellValue(data['studentEmail'] ?? ''),
            TextCellValue(data['status'] ?? 'Present'),
          ]);
        }

        // 2. Set generous column widths for Sheet 1
        sheet1.setColumnWidth(0, 16.0);
        sheet1.setColumnWidth(1, 22.0);
        sheet1.setColumnWidth(2, 16.0);
        sheet1.setColumnWidth(3, 24.0);
        sheet1.setColumnWidth(4, 30.0);
        sheet1.setColumnWidth(5, 16.0);

        // Sheet 2: Student Summary
        final Sheet sheet2 = excel['Student Summary'];
        sheet2.appendRow([
          TextCellValue('Sr. No.'),
          TextCellValue('Student Email'),
          TextCellValue('Present Count'),
          TextCellValue('Total Recorded Sessions'),
          TextCellValue('Attendance %'),
        ]);

        for (int i = 0; i < studentList.length; i++) {
          final email = studentList[i];
          final studentLogs = attendanceDocs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return data['studentEmail'] == email;
          }).toList();

          final presentCount = studentLogs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return (data['status'] ?? 'Present') == 'Present';
          }).length;

          final totalRecorded = studentLogs.length;
          final double pct = totalRecorded == 0 ? 0 : (presentCount / totalRecorded) * 100;

          sheet2.appendRow([
            IntCellValue(i + 1),
            TextCellValue(email),
            IntCellValue(presentCount),
            IntCellValue(totalRecorded),
            TextCellValue("${pct.toStringAsFixed(2)}%"),
          ]);
        }

        // 2. Set generous column widths for Sheet 2
        sheet2.setColumnWidth(0, 12.0);
        sheet2.setColumnWidth(1, 30.0);
        sheet2.setColumnWidth(2, 18.0);
        sheet2.setColumnWidth(3, 24.0);
        sheet2.setColumnWidth(4, 18.0);

      } else {
        // Individual Student Report
        final Sheet sheet1 = excel['Student Report'];
        _appendHeader(sheet1, "ATTENDX - INDIVIDUAL STUDENT REPORT", {
          "Student": selectedStudentEmail!,
          "Course": courseTitle,
          "Generated Date": dateStr,
        });

        sheet1.appendRow([
          TextCellValue('Date'),
          TextCellValue('Subject'),
          TextCellValue('Lecture No.'),
          TextCellValue('Time Slot'),
          TextCellValue('Status'),
        ]);

        final studentDocs = attendanceDocs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['studentEmail'] == selectedStudentEmail;
        }).toList();

        for (var doc in studentDocs) {
          final data = doc.data() as Map<String, dynamic>;
          sheet1.appendRow([
            TextCellValue(data['date'] ?? ''),
            TextCellValue(data['subject'] ?? ''),
            TextCellValue("${data['lectureNo'] ?? ''}"),
            TextCellValue(data['timeSlot'] ?? ''),
            TextCellValue(data['status'] ?? 'Present'),
          ]);
        }

        sheet1.setColumnWidth(0, 16.0);
        sheet1.setColumnWidth(1, 22.0);
        sheet1.setColumnWidth(2, 16.0);
        sheet1.setColumnWidth(3, 24.0);
        sheet1.setColumnWidth(4, 16.0);
      }

      final directory = await getTemporaryDirectory();
      final safeCourseName = courseTitle.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final String filePath = '${directory.path}/Attendance_$safeCourseName.xlsx';

      final List<int>? fileBytes = excel.encode();
      if (fileBytes != null) {
        final File file = File(filePath);
        await file.writeAsBytes(fileBytes, flush: true);

        if (mounted) {
          final xFile = XFile(filePath);
          await Share.shareXFiles([xFile], text: 'Attendance Export for $courseTitle');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export records: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isExporting = false);
    }
  }

  // --- UI Layout Helpers ---

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen),
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportTypeCard({
    required ExportType type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final bool isSelected = selectedExportType == type;
    return InkWell(
      onTap: () => setState(() => selectedExportType = type),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primaryGreen : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? primaryGreen : Colors.grey),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? primaryGreen : Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _appendHeader(Sheet sheet, String title, Map<String, String> info) {
    sheet.appendRow([TextCellValue(title)]);
    sheet.appendRow([]);
    info.forEach((k, v) => sheet.appendRow([TextCellValue("$k:"), TextCellValue(v)]));
    sheet.appendRow([]);
  }
}