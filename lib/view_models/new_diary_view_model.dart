import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/diary_repository.dart';
import '../models/image_emotion.dart';

class NewDiaryViewModel extends ChangeNotifier {
  final DiaryRepository repo;
  final AIService ai;
  NewDiaryViewModel({required this.repo, required this.ai});

  String content = '';
  String? feeling;
  List<File> localImages = [];
  bool saving = false;
  String? error;

  bool get canSave => content.trim().isNotEmpty || localImages.isNotEmpty;

  void setContent(String v) {
    content = v;
    notifyListeners();
  }

  void setFeeling(String? v) {
    feeling = v;
    notifyListeners();
  }

  void addLocalImages(List<File> files) {
    localImages.addAll(files);
    notifyListeners();
  }

  void removeLocalAt(int i) {
    localImages.removeAt(i);
    notifyListeners();
  }

  Future<String> save({bool analyzeImages = true}) async {
    if (!canSave) throw Exception('Hãy nhập nội dung hoặc chọn ảnh');
    saving = true;
    error = null;
    notifyListeners();

    try {
      // AI phân tích text
      final textAi = await ai.analyzeText(content.isEmpty ? ' ' : content);
      final textSentiment = (textAi['sentiment'] ?? 'neutral').toString();
      final textScore = (textAi['score'] ?? 0).toDouble();

      // Upload ảnh & AI ảnh
      final urls = <String>[];
      final imgEmotions = <ImageEmotion>[];

      for (final f in localImages) {
        final url = await repo.uploadImageAndGetUrl(f);
        urls.add(url);

        if (analyzeImages) {
          final imgAi = await ai.analyzeImage(f);
          imgEmotions.add(
            ImageEmotion(
              url: url,
              overallEmotion: (imgAi['overallEmotion'] ?? 'neutral').toString(),
              confidence: (imgAi['confidence'] ?? 0).toDouble(),
              scores: Map<String, double>.from(
                (imgAi['scores'] ?? {}).map(
                  (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
                ),
              ),
            ),
          );
        }
      }

      //Firestore
      final id = await repo.addDiaryEntry(
        content: content.trim(),
        selectedFeeling: feeling,
        imageUrls: urls,
        textSentiment: textSentiment,
        textSentimentScore: textScore,
        imageEmotions: imgEmotions,
      );

      // Reset local (tuỳ ý)
      content = '';
      feeling = null;
      localImages = [];
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
