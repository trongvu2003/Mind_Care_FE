import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/diary_entry.dart';
import '../models/image_emotion.dart';

class DiaryRepository {
  final FirebaseFirestore _fire;
  final bool useUserSubcollection;

  DiaryRepository({FirebaseFirestore? fire, this.useUserSubcollection = true})
    : _fire = fire ?? FirebaseFirestore.instance;

  Stream<List<DiaryEntry>> streamUserDiaries(String uid, {int limit = 200}) {
    Query<Map<String, dynamic>> q;
    if (useUserSubcollection) {
      q = _fire
          .collection('users')
          .doc(uid)
          .collection('diaries')
          .orderBy('createdAt', descending: true)
          .limit(limit);
    } else {
      q = _fire
          .collection('diaries')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(limit);
    }
    return q.snapshots().map(
      (s) => s.docs.map((d) => DiaryEntry.fromSnapshot(d)).toList(),
    );
  }

  Future<String> createDiary({
    required String uid,
    required String content,
    String? selectedFeeling,
    List<String> imageUrls = const [],
    String textSentiment = '',
    double textSentimentScore = 0,
    List<ImageEmotion> imageEmotions = const [],
  }) async {
    final col =
        useUserSubcollection
            ? _fire.collection('users').doc(uid).collection('diaries')
            : _fire.collection('diaries');
    final doc = col.doc();

    await doc.set({
      'uid': uid,
      'content': content,
      'selectedFeeling': selectedFeeling,
      'imageUrls': imageUrls,
      'textSentiment': textSentiment,
      'textSentimentScore': textSentimentScore,
      'imageEmotions': imageEmotions.map((e) => e.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }
}
