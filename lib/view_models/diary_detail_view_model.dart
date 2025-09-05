import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/diary_entry.dart';
import '../services/diary_repository.dart';

class DiaryDetailViewModel extends ChangeNotifier {
  final DiaryRepository repo;
  final String uid;
  final String diaryId;

  DiaryDetailViewModel({
    required this.repo,
    required this.uid,
    required this.diaryId,
  });

  StreamSubscription<DiaryEntry?>? _sub;
  DiaryEntry? entry;
  bool loading = true;
  String? error;

  void start() {
    loading = true;
    error = null;
    notifyListeners();

    _sub?.cancel();
    _sub = repo
        .streamDiaryById(uid, diaryId)
        .listen(
          (e) {
            entry = e;
            loading = false;
            error = null;
            notifyListeners();
          },
          onError: (e) {
            loading = false;
            error = e.toString();
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
