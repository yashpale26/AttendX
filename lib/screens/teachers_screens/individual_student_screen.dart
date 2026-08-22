import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IndividualStudentScreen extends StatefulWidget {
  final String studentName;
  final String studentEmail;
  final String courseName;

  const IndividualStudentScreen({
    super.key,
    required this.studentName,
    required this.studentEmail,
    required this.courseName,
  });

  @override
  State<IndividualStudentScreen> createState() => _IndividualStudentScreenState();
}

class _IndividualStudentScreenState extends State<IndividualStudentScreen> {
  String selectedFilter = 'Overall'; // 'Day', 'Week', 'Month', 'Overall'

  // Sub-filters for Week and Month
  String selectedWeekDay = 'All Days'; // 'All Days', 'Mon', 'Tue', etc.
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
        title: const Text("Student Attendance"),
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
          stream: FirebaseFirestore.instance
              .collection('attendance')
              .where('course', isEqualTo: widget.courseName)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allDocs = snapshot.data?.docs ?? [];

            // Filter docs for this specific student by email or name
            final studentDocs = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final sId = data['studentId'] ?? data['studentEmail'] ?? '';
              final sName = data['studentName'] ?? '';
              return sId == widget.studentEmail ||
                  sId == widget.studentName ||
                  sName == widget.studentName ||
                  (widget.studentEmail.isNotEmpty && sId.toString().contains(widget.studentEmail));
            }).toList();

            // Calculate overall & subject-wise stats
            int totalLectures = studentDocs.length;
            int totalPresent = 0;
            int totalAbsent = 0;

            Map<String, Map<String, int>> subjectStats = {};
            List<Map<String, dynamic>> rawRecords = [];

            for (var doc in studentDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'Present';
              final subject = data['subject'] ?? 'General';
              final session = data['lecture'] ?? data['session'] ?? 'Lecture';

              DateTime date = DateTime.now();
              String dateStr = data['date']?.toString() ?? '';
              if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
                date = (data['timestamp'] as Timestamp).toDate();
                dateStr = DateFormat('yyyy-MM-dd').format(date);
              } else if (dateStr.isNotEmpty) {
                date = DateTime.tryParse(dateStr) ?? DateTime.now();
              }

              if (status == 'Present') {
                totalPresent++;
              } else {
                totalAbsent++;
              }

              // Subject stats aggregation
              subjectStats.putIfAbsent(subject, () => {'total': 0, 'present': 0, 'absent': 0});
              subjectStats[subject]!['total'] = subjectStats[subject]!['total']! + 1;
              if (status == 'Present') {
                subjectStats[subject]!['present'] = subjectStats[subject]!['present']! + 1;
              } else {
                subjectStats[subject]!['absent'] = subjectStats[subject]!['absent']! + 1;
              }

              rawRecords.add({
                'date': date,
                'dateStr': dateStr,
                'subject': subject,
                'session': session,
                'status': status,
              });
            }

            // Sort history descending by date
            rawRecords.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

            final double overallPct = totalLectures > 0 ? (totalPresent / totalLectures) * 100 : 0.0;

            // Filter history records based on selected timeframes & subfilters
            final now = DateTime.now();
            final filteredRecords = rawRecords.where((rec) {
              final d = rec['date'] as DateTime;

              if (selectedFilter == 'Day') {
                return d.year == now.year && d.month == now.month && d.day == now.day;
              } else if (selectedFilter == 'Week') {
                final diff = now.difference(d).inDays;
                bool inWeek = diff >= 0 && diff <= 7;
                if (!inWeek) return false;
                if (selectedWeekDay != 'All Days') {
                  String dayName = DateFormat('E').format(d);
                  return dayName == selectedWeekDay;
                }
                return true;
              } else if (selectedFilter == 'Month') {
                bool inMonth = d.year == now.year && d.month == now.month;
                if (!inMonth) return false;
                if (selectedSpecificMonth != 'All Months') {
                  String monthName = DateFormat('MMM').format(d);
                  return monthName == selectedSpecificMonth;
                }
                return true;
              }
              return true; // Overall
            }).toList();

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 1. Student Profile Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF007F5F), Color(0xFF00C9A7)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.white,
                              child: Text(
                                widget.studentName.isNotEmpty
                                    ? widget.studentName[0].toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF007F5F),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.studentName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (widget.studentEmail.isNotEmpty)
                                    Text(
                                      widget.studentEmail,
                                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                  Text(
                                    "Course: ${widget.courseName}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white38, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Overall Attendance",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${overallPct.toStringAsFixed(1)}%",
                                style: TextStyle(
                                  color: overallPct >= 75 ? const Color(0xFF007F5F) : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Overall Attendance Summary Cards
                Row(
                  children: [
                    _buildStatCard("Total", "$totalLectures", Colors.blue.shade700),
                    const SizedBox(width: 8),
                    _buildStatCard("Present", "$totalPresent", Colors.green.shade700),
                    const SizedBox(width: 8),
                    _buildStatCard("Absent", "$totalAbsent", Colors.red.shade700),
                    const SizedBox(width: 8),
                    _buildStatCard("% Rate", "${overallPct.toStringAsFixed(0)}%", const Color(0xFF007F5F)),
                  ],
                ),

                const SizedBox(height: 20),

                // 3. Subject-wise Attendance Section
                const Text(
                  "Subject-wise Attendance",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF007F5F)),
                ),
                const SizedBox(height: 8),
                subjectStats.isEmpty
                    ? const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("No subject records found.", style: TextStyle(color: Colors.grey)),
                  ),
                )
                    : Column(
                  children: subjectStats.entries.map((e) {
                    final subName = e.key;
                    final sTotal = e.value['total']!;
                    final sPresent = e.value['present']!;
                    final sAbsent = e.value['absent']!;
                    final sPct = sTotal > 0 ? (sPresent / sTotal) * 100 : 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  subName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  "${sPct.toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: sPct >= 75 ? const Color(0xFF007F5F) : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Lectures: $sTotal", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                Text("Present: $sPresent", style: TextStyle(fontSize: 12, color: Colors.green.shade800)),
                                Text("Absent: $sAbsent", style: TextStyle(fontSize: 12, color: Colors.red.shade800)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: sTotal > 0 ? sPresent / sTotal : 0,
                              backgroundColor: Colors.grey.shade200,
                              color: sPct >= 75 ? const Color(0xFF007F5F) : Colors.orange,
                              minHeight: 6,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // 4. Attendance History & ChoiceChip Filters (Matched UI from Course Overview)
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

                // 5. Visual Attendance Trend Graph Card with Dropdowns (Matched UI from Course Overview)
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
                          child: _buildStudentAttendanceChart(rawRecords),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 6. Detailed History Records
                filteredRecords.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text("No detailed records available.", style: TextStyle(color: Colors.grey))),
                )
                    : Column(
                  children: filteredRecords.map((rec) {
                    final DateTime d = rec['date'];
                    final bool isPresent = rec['status'] == 'Present';
                    final formattedDate = "${d.day}/${d.month}/${d.year}";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          isPresent ? Icons.check_circle : Icons.cancel,
                          color: isPresent ? const Color(0xFF007F5F) : Colors.red,
                        ),
                        title: Text(
                          "${rec['subject']} (${rec['session']})",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Date: $formattedDate"),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPresent ? Colors.green.shade100 : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            rec['status'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isPresent ? Colors.green.shade900 : Colors.red.shade900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
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

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentAttendanceChart(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      return const Center(child: Text("No attendance data to plot"));
    }

    // Use a Map to group records and track their earliest date for chronological sorting
    Map<String, List<int>> groupedData = {};
    Map<String, DateTime> keyDates = {};

    for (var rec in records) {
      final DateTime dt = rec['date'] as DateTime;
      final status = rec['status'] ?? 'Present';

      String groupKey = DateFormat('yyyy-MM-dd').format(dt);

      if (selectedFilter == 'Day') {
        groupKey = DateFormat('dd MMM').format(dt);
      } else if (selectedFilter == 'Week') {
        String dayName = DateFormat('E').format(dt);
        if (selectedWeekDay != 'All Days' && dayName != selectedWeekDay) {
          continue;
        }
        int weekNum = (dt.day / 7).ceil();
        groupKey = "$dayName (W$weekNum)";
      } else if (selectedFilter == 'Month') {
        String monthName = DateFormat('MMM').format(dt);
        if (selectedSpecificMonth != 'All Months' && monthName != selectedSpecificMonth) {
          continue;
        }
        groupKey = DateFormat('dd MMM').format(dt);
      } else {
        groupKey = DateFormat('MMM yyyy').format(dt);
      }

      groupedData.putIfAbsent(groupKey, () => [0, 0]);
      groupedData[groupKey]![1] += 1;
      if (status == 'Present') {
        groupedData[groupKey]![0] += 1;
      }

      // Keep track of the actual DateTime for accurate chronological sorting
      if (!keyDates.containsKey(groupKey) || dt.isBefore(keyDates[groupKey]!)) {
        keyDates[groupKey] = dt;
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

    // Sort x-axis labels chronologically (oldest date -> newest date)
    keys.sort((a, b) => keyDates[a]!.compareTo(keyDates[b]!));

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
                      angle: -0.4,
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