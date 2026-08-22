import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyAttendanceScreen extends StatefulWidget {
  const MyAttendanceScreen({super.key});

  @override
  State<MyAttendanceScreen> createState() => _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends State<MyAttendanceScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String selectedPeriodFilter = 'Overall'; // 'Overall', 'This Month', 'This Week'
  String selectedSubjectFilter = 'All Subjects';

  static const Color primaryBlue = Color(0xFF004AAD);
  static const Color secondaryBlue = Color(0xFF007CF0);

  @override
  Widget build(BuildContext context) {
    final String currentStudentEmail = _auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Attendance"),
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
              .collection('attendance')
              .where('studentEmail', isEqualTo: currentStudentEmail)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryBlue),
              );
            }

            final allDocs = snapshot.data?.docs ?? [];

            // Calculate Overall Metrics across all records
            int totalOverallPresent = 0;
            int totalOverallLectures = allDocs.length;
            final Set<String> subjectsSet = {};
            final Map<String, List<int>> subjectStats = {}; // subject -> [Present, Total]

            for (var doc in allDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final subject = data['subject']?.toString() ?? 'General';
              final status = data['status']?.toString() ?? 'Absent';

              subjectsSet.add(subject);
              subjectStats.putIfAbsent(subject, () => [0, 0]);
              subjectStats[subject]![1] += 1;

              if (status == 'Present') {
                totalOverallPresent++;
                subjectStats[subject]![0] += 1;
              }
            }

            final double overallPercentage = totalOverallLectures > 0
                ? (totalOverallPresent / totalOverallLectures) * 100
                : 0.0;

            final List<String> subjectDropdownItems = ['All Subjects', ...subjectsSet];

            // Apply Filters (Period & Subject)
            final DateTime now = DateTime.now();
            final filteredDocs = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final String subject = data['subject']?.toString() ?? '';
              final String dateStr = data['date']?.toString() ?? '';

              // Subject Filter
              if (selectedSubjectFilter != 'All Subjects' &&
                  subject != selectedSubjectFilter) {
                return false;
              }

              // Period Filter
              try {
                final DateTime docDate = DateFormat('yyyy-MM-dd').parse(dateStr);
                if (selectedPeriodFilter == 'This Month') {
                  if (docDate.month != now.month || docDate.year != now.year) {
                    return false;
                  }
                } else if (selectedPeriodFilter == 'This Week') {
                  final DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                  final DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
                  if (docDate.isBefore(startOfWeek) || docDate.isAfter(endOfWeek)) {
                    return false;
                  }
                }
              } catch (_) {}

              return true;
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Overall Attendance Metric Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryBlue, secondaryBlue],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
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
                          "$totalOverallPresent / $totalOverallLectures Lectures",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Attendance Trend Graph Section
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
                          const Text(
                            "Attendance Trend",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Filter: $selectedPeriodFilter • $selectedSubjectFilter",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 200,
                            child: _buildAttendanceChart(filteredDocs),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Subject Attendance Summary Table
                  const Text(
                    "Subject Attendance Summary",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (subjectStats.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "No subject data found.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2.2),
                            1: FlexColumnWidth(1),
                            2: FlexColumnWidth(1),
                            3: FlexColumnWidth(1),
                            4: FlexColumnWidth(1.2),
                          },
                          children: [
                            TableRow(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryBlue, secondaryBlue],
                                ),
                              ),
                              children: const [
                                _TableHeader("Subject"),
                                _TableHeader("Lectures"),
                                _TableHeader("Present"),
                                _TableHeader("Absent"),
                                _TableHeader("%"),
                              ],
                            ),
                            ...subjectStats.entries.map((entry) {
                              final sub = entry.key;
                              final present = entry.value[0];
                              final total = entry.value[1];
                              final absent = total - present;
                              final pct = total > 0 ? (present / total) * 100 : 0.0;

                              return TableRow(
                                children: [
                                  _TableCell(sub, isBold: true),
                                  _TableCell("$total"),
                                  _TableCell("$present"),
                                  _TableCell("$absent"),
                                  _TableCell("${pct.toStringAsFixed(1)}%"),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // 4. Filters Section
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Period",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildDropdown(
                              selectedPeriodFilter,
                              ['Overall', 'This Month', 'This Week'],
                                  (val) => setState(() => selectedPeriodFilter = val!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Subject",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildDropdown(
                              selectedSubjectFilter,
                              subjectDropdownItems,
                                  (val) => setState(() => selectedSubjectFilter = val!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 5. Attendance History Logs List
                  const Text(
                    "Attendance History",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (filteredDocs.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "No attendance history matches the selected filters.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final data = filteredDocs[index].data() as Map<String, dynamic>;
                        final String subject = data['subject']?.toString() ?? 'Subject';
                        final String date = data['date']?.toString() ?? '';
                        final String timeSlot = data['timeSlot']?.toString() ?? '';
                        final String lectureNo = data['lectureNo']?.toString() ?? '${filteredDocs.length - index}';
                        final String status = data['status']?.toString() ?? 'Absent';
                        final bool isPresent = status == 'Present';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              "Lecture $lectureNo - $subject",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
                                isPresent ? "✓ Present" : "✕ Absent",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isPresent ? Colors.green.shade700 : Colors.red.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryBlue.withAlpha(50)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(currentValue) ? currentValue : items.first,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: primaryBlue),
          style: const TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildAttendanceChart(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return const Center(
        child: Text(
          "No records found for selected filter",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }

    Map<String, List<int>> groupedData = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dateStr = data['date']?.toString() ?? '';
      final status = data['status']?.toString() ?? 'Present';

      String groupKey = dateStr;
      try {
        DateTime dt = DateFormat('yyyy-MM-dd').parse(dateStr);
        groupKey = DateFormat('dd MMM').format(dt);
      } catch (_) {}

      groupedData.putIfAbsent(groupKey, () => [0, 0]);
      groupedData[groupKey]![1] += 1;
      if (status == 'Present') {
        groupedData[groupKey]![0] += 1;
      }
    }

    List<String> keys = groupedData.keys.toList();

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
              color: Colors.grey.withAlpha(50),
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
                      angle: -0.4,
                      child: Text(
                        keys[index],
                        style: const TextStyle(
                          fontSize: 10,
                          color: primaryBlue,
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
            bottom: BorderSide(color: Colors.grey.withAlpha(60), width: 1),
            left: BorderSide(color: Colors.grey.withAlpha(60), width: 1),
          ),
        ),
        minX: 0,
        maxX: (keys.length - 1).toDouble() < 0 ? 0 : (keys.length - 1).toDouble(),
        minY: 0,
        maxY: 100,
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 75,
              color: Colors.redAccent.withAlpha(150),
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
            getTooltipColor: (spot) => primaryBlue,
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
            color: primaryBlue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: primaryBlue,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: secondaryBlue.withAlpha(50),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String title;
  const _TableHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String value;
  final bool isBold;
  const _TableCell(this.value, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Text(
        value,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.black87,
          fontSize: 12,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}