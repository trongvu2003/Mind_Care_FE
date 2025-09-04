import 'package:cloud_firestore/cloud_firestore.dart';

class StatsRepository {
  Stream<QuerySnapshot<Map<String, dynamic>>> streamRange(
    String uid,
    DateTime start,
    DateTime end,
  ) {
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('diaries');

    return col
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('createdAt', descending: false)
        .snapshots();
  }
}
