import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../services/stats_repository.dart';
import '../../view_models/stats_view_model.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: _appBar(),
        body: const Center(child: Text('Bạn chưa đăng nhập')),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => StatsViewModel(repo: StatsRepository(), uid: uid)..start(),
      child: const _StatisticsView(),
    );
  }

  static AppBar _appBar() => AppBar(
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
  );
}

class _StatisticsView extends StatelessWidget {
  const _StatisticsView();

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsViewModel>(
      builder: (context, vm, _) {
        final labels = vm.xLabels;
        final spots = List.generate(
          7,
          (i) => FlSpot(i.toDouble(), vm.buckets[i] * 100.0),
        );

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: StatisticsPage._appBar(),
          body:
              vm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tabs
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              ["Ngày", "Tuần", "Tháng"].asMap().entries.map((
                                entry,
                              ) {
                                final idx = entry.key;
                                final label = entry.value;
                                final selected = vm.selectedTab == idx;
                                return GestureDetector(
                                  onTap: () => vm.setTab(idx),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient:
                                          selected
                                              ? const LinearGradient(
                                                colors: [
                                                  AppColors.title,
                                                  Colors.cyan,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                              : null,
                                      color:
                                          selected
                                              ? null
                                              : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow:
                                          selected
                                              ? [
                                                BoxShadow(
                                                  color: Colors.teal
                                                      .withOpacity(0.3),
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
                                            selected
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

                        // Line chart (giữ nguyên UI)
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
                                        interval: 1,
                                        getTitlesWidget: (value, _) {
                                          final idx = value.toInt();
                                          if (idx >= 0 && idx < labels.length) {
                                            return Text(
                                              labels[idx],
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
                                        interval: 25,
                                        reservedSize: 32,
                                        getTitlesWidget: (value, _) {
                                          if (value % 25 == 0 && value <= 100) {
                                            return Text(
                                              value.toInt().toString(),
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            );
                                          }
                                          return const Text("");
                                        },
                                      ),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  minY: 0,
                                  maxY: 100,
                                  minX: 0,
                                  maxX: 6,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots,
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
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
                                          value: vm.posPct,
                                          color: Colors.blue,
                                          title:
                                              "${vm.posPct.toStringAsFixed(0)}%",
                                          radius: 40,
                                          titleStyle: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        PieChartSectionData(
                                          value: vm.negPct,
                                          color: Colors.orange,
                                          title:
                                              "${vm.negPct.toStringAsFixed(0)}%",
                                          radius: 40,
                                        ),
                                        PieChartSectionData(
                                          value: vm.neuPct,
                                          color: Colors.grey,
                                          title:
                                              "${vm.neuPct.toStringAsFixed(0)}%",
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "🟦  Tích cực - ${vm.posPct.toStringAsFixed(0)}%",
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "🟧  Tiêu cực - ${vm.negPct.toStringAsFixed(0)}%",
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "⬜  Trung lập - ${vm.neuPct.toStringAsFixed(0)}%",
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          "Nhật ký",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children:
                              vm.recent.map((m) {
                                final dt =
                                    (m['createdAt'] as Timestamp).toDate();
                                return _DiaryCard(
                                  title: vm.titleForDate(dt, DateTime.now()),
                                  subtitle: vm.subtitleForEntry(m),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
        );
      },
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
