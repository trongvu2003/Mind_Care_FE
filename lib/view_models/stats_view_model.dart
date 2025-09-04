import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../services/stats_repository.dart';

class StatsViewModel extends ChangeNotifier {
  final StatsRepository repo;
  final String uid;

  StatsViewModel({required this.repo, required this.uid});

  int selectedTab = 0; // 0: Ngày, 1: Tuần, 2: Tháng
  bool isLoading = false;
  String? error;

  // dữ liệu biểu đồ
  List<double> buckets = List<double>.filled(7, 0);
  double posPct = 0; // %
  double negPct = 0; // %
  double neuPct = 0; // %

  // nhật ký gần đây trong range (5 cái đã sort )
  List<Map<String, dynamic>> recent = [];

  StreamSubscription? _sub;

  void start() {
    _listen();
  }

  void setTab(int i) {
    if (i == selectedTab) return;
    selectedTab = i;
    _listen();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<String> get xLabels =>
      _xLabels(selectedTab, _rangeStart(DateTime.now(), selectedTab));

  String titleForDate(DateTime dt, DateTime now) {
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) return 'Hôm nay';
    return '${dt.day}/${dt.month}';
  }

  String subtitleForEntry(Map<String, dynamic> m) {
    final f = (m['selectedFeeling'] as String?)?.trim();
    if (f != null && f.isNotEmpty) return 'Cảm thấy $f';

    final t = (m['textSentiment'] as String?)?.toLowerCase().trim();
    if (t == 'positive') return 'Cảm thấy tích cực';
    if (t == 'neutral') return 'Cảm thấy bình thường';
    if (t == 'negative') return 'Cảm thấy tiêu cực';

    final imgs = (m['imageEmotions'] as List?) ?? const [];
    if (imgs.isNotEmpty && imgs.first is Map) {
      final overall =
          (Map<String, dynamic>.from(imgs.first)['overallEmotion'] as String?)
              ?.toLowerCase()
              .trim();
      if (overall != null) {
        switch (overall) {
          case 'happy':
            return 'Cảm thấy vui vẻ';
          case 'sad':
            return 'Cảm thấy buồn';
          case 'angry':
            return 'Cảm thấy tức giận';
          case 'fear':
            return 'Cảm thấy lo lắng';
          case 'disgust':
            return 'Cảm thấy khó chịu';
          case 'surprise':
            return 'Cảm thấy ngạc nhiên';
          case 'neutral':
            return 'Cảm thấy bình thường';
        }
      }
    }

    final content = (m['content'] as String?) ?? '';
    if (content.isNotEmpty) {
      return content.length > 40 ? '${content.substring(0, 40)}…' : content;
    }
    return '—';
  }


  void _listen() {
    _sub?.cancel();
    isLoading = true;
    error = null;
    notifyListeners();

    final now = DateTime.now();
    final start = _rangeStart(now, selectedTab);
    final end = now;

    _sub = repo
        .streamRange(uid, start, end)
        .listen(
          (snap) {
            final docs = snap.docs;
            final entries =
                docs
                    .map((d) => d.data())
                    .where((m) => m['createdAt'] is Timestamp)
                    .map((m) => Map<String, dynamic>.from(m))
                    .toList();

            _compute(entries, selectedTab, start, end);

            isLoading = false;
            error = null;
            notifyListeners();
          },
          onError: (e) {
            isLoading = false;
            error = e.toString();
            notifyListeners();
          },
        );
  }

  void _compute(
    List<Map<String, dynamic>> entries,
    int tab,
    DateTime start,
    DateTime end,
  ) {
    buckets = _makeBuckets(entries, tab, start, end); // 7 bucket (0..1)

    final pieCounts = _sentimentCounts(entries);
    final total =
        (pieCounts['positive']! +
            pieCounts['neutral']! +
            pieCounts['negative']!);
    if (total == 0) {
      posPct = 0;
      negPct = 0;
      neuPct = 0;
    } else {
      posPct = pieCounts['positive']! / total * 100;
      negPct = pieCounts['negative']! / total * 100;
      neuPct = pieCounts['neutral']! / total * 100;
    }

    // Lấy 5 entry gần nhất trong range
    recent =
        entries..sort((a, b) {
          final ta = (a['createdAt'] as Timestamp).toDate();
          final tb = (b['createdAt'] as Timestamp).toDate();
          return tb.compareTo(ta);
        });
    if (recent.length > 5) {
      recent = recent.sublist(0, 5);
    }
  }

  // pure functions
  static DateTime _rangeStart(DateTime now, int tab) {
    if (tab == 0) {
      return DateTime(now.year, now.month, now.day);
    } else if (tab == 1) {
      final start = now.subtract(const Duration(days: 6));
      return DateTime(start.year, start.month, start.day);
    } else {
      return DateTime(now.year, now.month, 1);
    }
  }

  static List<String> _xLabels(int tab, DateTime start) {
    if (tab == 0) {
      return const ['Đêm', 'Sớm', 'Sáng', 'Trưa', 'Chiều', 'Tối', 'Khuya'];
    } else if (tab == 1) {
      return const ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];
    } else {
      return const [
        "Tuần1",
        "Tuần2",
        "Tuần3",
        "Tuần4",
        "Tuần5",
        "Tuần6",
        "Tuần7",
      ];
    }
  }

  static List<double> _makeBuckets(
    List<Map<String, dynamic>> entries,
    int tab,
    DateTime start,
    DateTime end,
  ) {
    final sums = List<double>.filled(7, 0);
    final counts = List<int>.filled(7, 0);
    final daysInMonth = DateTime(end.year, end.month + 1, 0).day;

    for (final m in entries) {
      final ts = m['createdAt'];
      if (ts is! Timestamp) continue;
      final dt = ts.toDate();

      int idx = 0;
      if (tab == 0) {
        idx = (dt.hour * 7 ~/ 24).clamp(0, 6);
      } else if (tab == 1) {
        idx = (dt.weekday - 1).clamp(0, 6);
      } else {
        idx = (((dt.day - 1) * 7) ~/ daysInMonth).clamp(0, 6);
      }

      final score = _scoreForEntry(m);
      if (score != null) {
        sums[idx] += score;
        counts[idx] += 1;
      }
    }

    return List.generate(
      7,
      (i) => counts[i] == 0 ? 0.0 : (sums[i] / counts[i]).clamp(0.0, 1.0),
    );
  }

  static double? _scoreForEntry(Map<String, dynamic> m) {
    final s = m['textSentimentScore'];
    if (s is num) return s.toDouble().clamp(0.0, 1.0);

    final t = (m['textSentiment'] as String?)?.toLowerCase().trim();
    if (t == 'positive') return 0.85;
    if (t == 'neutral') return 0.5;
    if (t == 'negative') return 0.25;

    final imgs = (m['imageEmotions'] as List?) ?? const [];
    if (imgs.isNotEmpty && imgs.first is Map) {
      final img0 = Map<String, dynamic>.from(imgs.first);
      final overall = (img0['overallEmotion'] as String?)?.toLowerCase().trim();
      if (overall != null) {
        switch (overall) {
          case 'happy':
            return 0.85;
          case 'surprise':
            return 0.6;
          case 'neutral':
            return 0.5;
          case 'sad':
          case 'angry':
          case 'fear':
          case 'disgust':
            return 0.25;
        }
      }
      final scores =
          (img0['scores'] is Map)
              ? Map<String, dynamic>.from(img0['scores'])
              : {};
      final vals = scores.values.whereType<num>().map((e) => e.toDouble());
      if (vals.isNotEmpty)
        return vals.reduce((a, b) => a > b ? a : b).clamp(0.0, 1.0);
    }

    return null;
  }

  static Map<String, int> _sentimentCounts(List<Map<String, dynamic>> entries) {
    int pos = 0, neu = 0, neg = 0;
    for (final m in entries) {
      String? s = (m['textSentiment'] as String?)?.toLowerCase().trim();
      if (s == null) {
        final imgs = (m['imageEmotions'] as List?) ?? const [];
        if (imgs.isNotEmpty && imgs.first is Map) {
          final overall =
              (Map<String, dynamic>.from(imgs.first)['overallEmotion']
                      as String?)
                  ?.toLowerCase()
                  .trim();
          if (overall != null) {
            if (overall == 'happy' || overall == 'surprise') {
              s = 'positive';
            } else if (overall == 'neutral') {
              s = 'neutral';
            } else {
              s = 'negative';
            }
          }
        }
      }
      switch (s) {
        case 'positive':
          pos++;
          break;
        case 'neutral':
          neu++;
          break;
        case 'negative':
          neg++;
          break;
      }
    }
    return {'positive': pos, 'neutral': neu, 'negative': neg};
  }
}
