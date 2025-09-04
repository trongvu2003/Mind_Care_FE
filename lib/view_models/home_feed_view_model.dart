import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/diary_entry.dart';
import '../services/diary_repository.dart';

class HomeFeedViewModel extends ChangeNotifier {
  final DiaryRepository repo;
  final String uid;

  HomeFeedViewModel({required this.repo, required this.uid});

  StreamSubscription? _sub;
  bool isLoading = true;
  String? error;
  List<DiaryEntry> today = [];
  List<DiaryEntry> thisMonth = [];
  Map<int, List<DiaryEntry>> byYear = {};

  void start() {
    isLoading = true;
    error = null;
    notifyListeners();

    _sub?.cancel();
    _sub = repo
        .streamUserDiaries(uid)
        .listen(
          (entries) {
            _group(entries);
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

  void _group(List<DiaryEntry> list) {
    final now = DateTime.now();
    today = [];
    thisMonth = [];
    byYear = {};

    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    bool sameMonth(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month;

    for (final e in list) {
      if (sameDay(e.createdAt, now)) {
        today.add(e);
      } else if (sameMonth(e.createdAt, now)) {
        thisMonth.add(e);
      } else {
        byYear.putIfAbsent(e.createdAt.year, () => []);
        byYear[e.createdAt.year]!.add(e);
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
