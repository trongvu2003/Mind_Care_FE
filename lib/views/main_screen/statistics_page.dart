import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../theme/app_colors.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int selectedTab = 0; // 0: Ngày, 1: Tuần, 2: Tháng

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Thống kê cảm xúc",
          style: TextStyle(
            color: AppColors.title,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Tabs Ngày / Tuần / Tháng
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  ["Ngày", "Tuần", "Tháng"].asMap().entries.map((entry) {
                    final idx = entry.key;
                    final label = entry.value;
                    return GestureDetector(
                      onTap: () => setState(() => selectedTab = idx),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient:
                              selectedTab == idx
                                  ? const LinearGradient(
                                    colors: [AppColors.title, Colors.cyan],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                  : null,
                          color:
                              selectedTab == idx ? null : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow:
                              selectedTab == idx
                                  ? [
                                    BoxShadow(
                                      color: Colors.teal.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                  : [],
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color:
                                selectedTab == idx
                                    ? Colors.white
                                    : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 20),

            /// Biểu đồ đường
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine:
                            (value) => FlLine(
                              color: Colors.grey.shade300,
                              strokeWidth: 1,
                            ),
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: Colors.grey.shade400,
                          width: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1, // cách đều các điểm theo index
                            getTitlesWidget: (value, _) {
                              const days = [
                                "T2",
                                "T3",
                                "T4",
                                "T5",
                                "T6",
                                "T7",
                                "CN",
                              ];
                              if (value.toInt() >= 0 &&
                                  value.toInt() < days.length) {
                                return Text(
                                  days[value.toInt()],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              }
                              return const Text("");
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 25, // hiển thị cách nhau 25
                            reservedSize: 32,
                            getTitlesWidget: (value, _) {
                              if (value % 25 == 0 && value <= 100) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 12),
                                );
                              }
                              return const Text("");
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      minY: 0,
                      maxY: 100, // Giới hạn từ 0 -> 100
                      minX: 0,
                      maxX: 6, // index từ 0 -> 6 (T2 -> CN)
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 20),
                            FlSpot(1, 35),
                            FlSpot(2, 25),
                            FlSpot(3, 80),
                            FlSpot(4, 60),
                            FlSpot(5, 75),
                            FlSpot(6, 50),
                          ],
                          isCurved: true,
                          gradient: const LinearGradient(
                            colors: [Colors.cyan, Colors.teal],
                          ),
                          barWidth: 4,
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.cyan.withOpacity(0.3),
                                Colors.teal.withOpacity(0.1),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Phân loại",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 120,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: 50,
                              color: Colors.blue,
                              title: "50%",
                              radius: 40,
                              titleStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            PieChartSectionData(
                              value: 22,
                              color: Colors.orange,
                              title: "22%",
                              radius: 40,
                            ),
                            PieChartSectionData(
                              value: 28,
                              color: Colors.grey,
                              title: "28%",
                              radius: 40,
                            ),
                          ],
                          centerSpaceRadius: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text("🟦  Tích cực - 50%"),
                          SizedBox(height: 6),
                          Text("🟧  Tiêu cực - 22%"),
                          SizedBox(height: 6),
                          Text("⬜  Trung lập - 28%"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// Nhật ký gần đây
            const Text(
              "Nhật ký",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Column(
              children: const [
                _DiaryCard(title: "Hôm nay", subtitle: "Cảm thấy vui vẻ"),
                _DiaryCard(title: "10 tháng 8", subtitle: "Một ngày tồi tệ"),
                _DiaryCard(title: "8 tháng 8", subtitle: "Bình thường"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _DiaryCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        leading: const Icon(Icons.edit_note, color: Colors.teal),
      ),
    );
  }
}
