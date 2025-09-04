import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/image_emotion.dart';
import '../services/api_service.dart';
import '../services/diary_repository.dart';
import '../services/upload_service.dart';

class NewDiaryViewModel extends ChangeNotifier {
  final DiaryRepository repo;
  final AIService ai;

  NewDiaryViewModel({required this.repo, required this.ai});

  // draft state
  String content = '';
  String? feeling;
  final List<File> localImages = [];

  // UI state
  bool saving = false;
  String? error;

  void setContent(String v) {
    content = v;
    notifyListeners();
  }

  void setFeeling(String? v) {
    feeling = v;
    notifyListeners();
  }

  void addLocalImages(List<File> files, {int maxImages = 5}) {
    final remain = maxImages - localImages.length;
    localImages.addAll(files.take(remain));
    notifyListeners();
  }

  void removeLocalAt(int index) {
    localImages.removeAt(index);
    notifyListeners();
  }

  bool get canSave => content.trim().isNotEmpty || localImages.isNotEmpty;

  Future<String> save({bool analyzeImages = false}) async {
    if (!canSave) throw Exception('Vui lòng nhập nội dung hoặc chọn ảnh');

    saving = true;
    error = null;
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

      final urls = <String>[];
      for (final f in localImages) {
        final up = await UploadService.uploadImage(f);
        if (up['url'] == null) throw Exception(up['error'] ?? 'Upload failed');
        urls.add(up['url']!);
      }

      // Phân tích text
      String sentiment = '';
      double sentimentScore = 0;
      if (content.trim().isNotEmpty) {
        final s = await ai.analyzeText(content.trim());
        sentiment = (s['label'] ?? '').toString();
        final sc = s['score'];
        sentimentScore = sc is num ? sc.toDouble() : 0;
      }

      // Phân tích ảnh (gọi /analyze/image từng ảnh)
      final imageEmotions = <ImageEmotion>[];
      if (analyzeImages) {
        for (int i = 0; i < localImages.length; i++) {
          final res = await ai.analyzeImage(localImages[i]);
          final faces = (res['faces'] as List?) ?? [];
          for (final f in faces) {
            final m = Map<String, dynamic>.from(f);
            final scores =
                (m['scores'] as Map?)?.map(
                  (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
                ) ??
                {};
            final label = (m['label'] ?? '').toString();
            final score = (scores[label] ?? 0);
            final box =
                ((m['box'] as List?) ?? [])
                    .map((e) => (e as num).toDouble())
                    .toList();
            imageEmotions.add(
              ImageEmotion(
                label: label,
                score: score,
                box: box,
                scores: scores,
                imageUrl: urls[i],
              ),
            );
          }
        }
      }

      // Firestore
      final id = await repo.createDiary(
        uid: uid,
        content: content.trim(),
        selectedFeeling: feeling,
        imageUrls: urls,
        textSentiment: sentiment,
        textSentimentScore: sentimentScore,
        imageEmotions: imageEmotions,
      );

      // clear draft
      content = '';
      feeling = null;
      localImages.clear();
      saving = false;
      notifyListeners();
      return id;
    } catch (e) {
      saving = false;
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
