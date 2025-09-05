import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/diary_entry.dart';
import '../models/image_emotion.dart';
import '../services/upload_service.dart';

class DiaryRepository {
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  final bool useUserSubcollection;

  DiaryRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    this.useUserSubcollection = true,
  }) : db = firestore ?? FirebaseFirestore.instance,
       auth = firebaseAuth ?? FirebaseAuth.instance;

  Future<String> uploadImageAndGetUrl(File file) async {
    final res = await UploadService.uploadImage(file);
    final url = res['url'];
    if (url != null && url.isNotEmpty) return url;
    throw Exception(res['error'] ?? 'Upload failed');
  }

  Future<String> addDiaryEntry({
    required String content,
    String? selectedFeeling,
    required List<String> imageUrls,
    required String textSentiment,
    required double textSentimentScore,
    required List<ImageEmotion> imageEmotions,
    DateTime? createdAt,
    String? summary,
    List<String> suggestions = const [],
  }) async {
    final uid = auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('Not logged in');
    }

    final data = <String, dynamic>{
      'uid': uid,
      'content': content,
      'selectedFeeling': selectedFeeling,
      'imageUrls': imageUrls,
      'textSentiment': textSentiment,
      'textSentimentScore': textSentimentScore,
      'imageEmotions': imageEmotions.map((e) => e.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'summary': summary,
      'suggestions': suggestions,
    };

    if (useUserSubcollection) {
      final ref = await db
          .collection('users')
          .doc(uid)
          .collection('diaries')
          .add(data);
      return ref.id;
    } else {
      final ref = await db.collection('diaries').add(data);
      return ref.id;
    }
  }

  Stream<List<DiaryEntry>> streamUserDiaries(String uid) {
    if (uid.isEmpty) {
      return const Stream<List<DiaryEntry>>.empty();
    }

    final Query<Map<String, dynamic>> baseQuery =
        useUserSubcollection
            ? db.collection('users').doc(uid).collection('diaries')
            : db.collection('diaries').where('uid', isEqualTo: uid);

    return baseQuery
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => DiaryEntry.fromDoc(doc)).toList(),
        );
  }

  Stream<DiaryEntry?> streamDiaryById(String uid, String diaryId) {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('diaries')
        .doc(diaryId);

    return docRef.snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return DiaryEntry.fromDoc(snapshot);
    });
  }

  CollectionReference<Map<String, dynamic>> _col(String uid) {
    return useUserSubcollection
        ? db.collection('users').doc(uid).collection('diaries')
        : db.collection('diaries');
  }
  Future<void> deleteMany(String uid, List<String> ids) async {
    final col = _col(uid);
    final batch = db.batch();
    for (final id in ids) {
      batch.delete(col.doc(id));
    }
    await batch.commit();
  }
}
