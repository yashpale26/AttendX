import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'student_list_screen.dart';

class CourseOverviewScreen extends StatefulWidget {
  const CourseOverviewScreen({super.key});

  @override
  State<CourseOverviewScreen> createState() => _CourseOverviewScreenState();
}

class _CourseOverviewScreenState extends State<CourseOverviewScreen> {
  String? selectedCourse;
  String selectedFilter = 'Overall'; // 'Day', 'Week', 'Month', 'Overall'

  // Sub-filters for Week and Month
  String selectedWeekDay = 'All Days'; // 'All Days', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  String selectedSpecificMonth = 'All Months'; // 'All Months', 'Jan', 'Feb', etc.

  final List<String> weekDays = ['All Days', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> monthsList = [
    'All Months', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Course Overview"),
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
                : (courseDocs.isNotEmpty
                ? courseDocs.first.data() as Map<String, dynamic>
                : {});

            final List enrolledStudents = courseData['students'] ?? [];
            final List courseSubjects = courseData['subjects'] ?? [];

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

                // Calculating Stats
                int totalPresent = 0;
                int totalAbsent = 0;
                Set<String> totalLectures = {};

                for (var doc in attendanceDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'Present';
                  if (status == 'Present') {
                    totalPresent++;
                  } else {
                    totalAbsent++;
                  }
                  final lectureKey = "${data['date']}_${data['timeSlot']}_${data['subject']}";
                  totalLectures.add(lectureKey);
                }

                int totalPossible = totalPresent + totalAbsent;
                double overallPercentage =
                totalPossible > 0 ? (totalPresent / totalPossible) * 100 : 0.0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Course Selection Dropdown
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

                      const SizedBox(height: 16),

                      // 2. Course Summary Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF007F5F), Color(0xFF00C9A7)],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedCourse ?? "No Course Selected",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const Divider(color: Colors.white38, height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _summaryItem("Enrolled", "${enrolledStudents.length}"),
                                _summaryItem("Lectures", "${totalLectures.length}"),
                                _summaryItem("Present", "$totalPresent"),
                                _summaryItem("Absent", "$totalAbsent"),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Overall Attendance:",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    "${overallPercentage.toStringAsFixed(2)}%",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 3. Subject Attendance Section
                      const Text(
                        "Subject Attendance",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF007F5F),
                        ),
                      ),
                      const SizedBox(height: 10),

                      courseSubjects.isEmpty
                          ? const Text(
                        "No subjects registered for this course.",
                        style: TextStyle(color: Colors.grey),
                      )
                          : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: courseSubjects.length,
                        itemBuilder: (context, index) {
                          final subject = courseSubjects[index].toString();
                          final subjectDocs = attendanceDocs.where(
                                (d) => (d.data() as Map<String, dynamic>)['subject'] == subject,
                          );

                          int subPresent = 0;
                          int subAbsent = 0;
                          Set<String> subLectures = {};

                          for (var doc in subjectDocs) {
                            final data = doc.data() as Map<String, dynamic>;
                            if ((data['status'] ?? 'Present') == 'Present') {
                              subPresent++;
                            } else {
                              subAbsent++;
                            }
                            subLectures.add("${data['date']}_${data['timeSlot']}");
                          }

                          int subTotal = subPresent + subAbsent;
                          double subPercentage =
                          subTotal > 0 ? (subPresent / subTotal) * 100 : 0.0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              title: Text(
                                subject,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "Lectures: ${subLectures.length} | P: $subPresent | A: $subAbsent",
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: subPercentage >= 75
                                      ? Colors.green.shade100
                                      : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "${subPercentage.toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    color: subPercentage >= 75
                                        ? Colors.green.shade900
                                        : Colors.red.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // 4. Attendance History & Filters
                      const Text(
                        "Attendance History",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF007F5F),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ['Day', 'Week', 'Month', 'Overall'].map((filter) {
                          final isSelected = selectedFilter == filter;
                          return ChoiceChip(
                            label: Text(filter),
                            selected: isSelected,
                            selectedColor: const Color(0xFF007F5F),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => selectedFilter = filter);
                              }
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 15),

                      // 5. Redesigned Visual Attendance Trend Graph Card
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Attendance Trend",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF007F5F),
                                        ),
                                      ),
                                      Text(
                                        "Selected view: $selectedFilter",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Sub-Filter Dropdown for Week/Month
                                  if (selectedFilter == 'Week')
                                    _buildDropdown(
                                      selectedWeekDay,
                                      weekDays,
                                          (val) => setState(() => selectedWeekDay = val!),
                                    )
                                  else if (selectedFilter == 'Month')
                                    _buildDropdown(
                                      selectedSpecificMonth,
                                      monthsList,
                                          (val) => setState(() => selectedSpecificMonth = val!),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 210,
                                child: _buildAttendanceChart(attendanceDocs),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 6. View Students Button Section
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudentListScreen(courseName: selectedCourse),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "View Students",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String currentValue,
      List<String> items,
      ValueChanged<String?> onChanged,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE6FFF5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00C9A7).withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF007F5F)),
          style: const TextStyle(
            color: Color(0xFF007F5F),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildAttendanceChart(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return const Center(child: Text("No attendance data to plot"));
    }

    Map<String, List<int>> groupedData = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateStr = data['date'] ?? '';
      final status = data['status'] ?? 'Present';

      String groupKey = dateStr;
      try {
        DateTime dt = DateFormat('yyyy-MM-dd').parse(dateStr);

        if (selectedFilter == 'Day') {
          groupKey = DateFormat('dd MMM').format(dt);
        } else if (selectedFilter == 'Week') {
          String dayName = DateFormat('E').format(dt); // Mon, Tue, Wed...
          if (selectedWeekDay != 'All Days' && dayName != selectedWeekDay) {
            continue; // Filter out if not selected week day
          }
          int weekNum = (dt.day / 7).ceil();
          groupKey = "$dayName (W$weekNum)";
        } else if (selectedFilter == 'Month') {
          String monthName = DateFormat('MMM').format(dt); // Jan, Feb...
          if (selectedSpecificMonth != 'All Months' && monthName != selectedSpecificMonth) {
            continue; // Filter out if not selected month
          }
          groupKey = DateFormat('dd MMM').format(dt);
        } else {
          groupKey = DateFormat('MMM yyyy').format(dt);
        }
      } catch (_) {}

      groupedData.putIfAbsent(groupKey, () => [0, 0]); // [Present, Total]
      groupedData[groupKey]![1] += 1;
      if (status == 'Present') {
        groupedData[groupKey]![0] += 1;
      }
    }

    List<String> keys = groupedData.keys.toList();

    if (keys.isEmpty) {
      return const Center(
        child: Text(
          "No records found for selected filter",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }

    List<FlSpot> spots = [];

    for (int i = 0; i < keys.length; i++) {
      final present = groupedData[keys[i]]![0];
      final total = groupedData[keys[i]]![1];
      final pct = total > 0 ? (present / total) * 100 : 0.0;
      spots.add(FlSpot(i.toDouble(), pct));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: 1,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < keys.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Transform.rotate(
                      angle: -0.4, // Rotates labels for clear spacing
                      child: Text(
                        keys[index],
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF007F5F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: 25,
              getTitlesWidget: (value, meta) {
                return Text(
                  "${value.toInt()}%",
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
            left: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
          ),
        ),
        minX: 0,
        maxX: (keys.length - 1).toDouble() < 0 ? 0 : (keys.length - 1).toDouble(),
        minY: 0,
        maxY: 100,
        // Target 75% Reference Line
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 75,
              color: Colors.redAccent.withOpacity(0.6),
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                labelResolver: (line) => "Target 75%",
              ),
            ),
          ],
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => const Color(0xFF007F5F),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  "${spot.y.toStringAsFixed(1)}%",
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
            isCurved: true,
            color: const Color(0xFF007F5F),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: const Color(0xFF007F5F),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF00C9A7).withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}