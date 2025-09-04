import 'package:cloud_firestore/cloud_firestore.dart';
import 'image_emotion.dart';

double _numToDouble(Object? v) =>
    v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

class DiaryEntry {
  final String id;
  final String uid;
  final String content;
  final String? selectedFeeling;
  final List<String> imageUrls;
  final String textSentiment;
  final double textSentimentScore; // 0..1
  final List<ImageEmotion> imageEmotions;
  final DateTime createdAt;
  final String? summary;
  final List<String> suggestions;

  DiaryEntry({
    required this.id,
    required this.uid,
    required this.content,
    required this.selectedFeeling,
    required this.imageUrls,
    required this.textSentiment,
    required this.textSentimentScore,
    required this.imageEmotions,
    required this.createdAt,
    this.summary,
    this.suggestions = const [],
  });

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'content': content,
    'selectedFeeling': selectedFeeling,
    'imageUrls': imageUrls,
    'textSentiment': textSentiment,
    'textSentimentScore': textSentimentScore,
    'imageEmotions': imageEmotions.map((e) => e.toMap()).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
    'summary': summary,
    'suggestions': suggestions,
  };

  factory DiaryEntry.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final m = snap.data() ?? {};
    final ts = m['createdAt'];
    final createdAt = ts is Timestamp ? ts.toDate() : DateTime.now();

    return DiaryEntry(
      id: snap.id,
      uid: (m['uid'] ?? '').toString(),
      content: (m['content'] ?? '').toString(),
      selectedFeeling: m['selectedFeeling'] as String?,
      imageUrls:
          (m['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      textSentiment: (m['textSentiment'] ?? '').toString(),
      textSentimentScore: _numToDouble(m['textSentimentScore']),
      imageEmotions:
          ((m['imageEmotions'] as List?) ?? [])
              .map((e) => ImageEmotion.fromMap(Map<String, dynamic>.from(e)))
              .toList(),
      createdAt: createdAt,
      summary: m['summary']?.toString(),
      suggestions: List<String>.from(m['suggestions'] ?? []),
    );
  }

  factory DiaryEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    final ts = m['createdAt'];
    final createdAt = ts is Timestamp ? ts.toDate() : DateTime.now();

    return DiaryEntry(
      id: doc.id,
      uid: (m['uid'] ?? '').toString(),
      content: (m['content'] ?? '').toString(),
      selectedFeeling: m['selectedFeeling'] as String?,
      imageUrls:
          (m['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      textSentiment: (m['textSentiment'] ?? '').toString(),
      textSentimentScore: _numToDouble(m['textSentimentScore']),
      imageEmotions:
          ((m['imageEmotions'] as List?) ?? [])
              .map((e) => ImageEmotion.fromMap(Map<String, dynamic>.from(e)))
              .toList(),
      createdAt: createdAt,
      summary: m['summary']?.toString(),
      suggestions: List<String>.from(m['suggestions'] ?? []),
    );
  }
}
