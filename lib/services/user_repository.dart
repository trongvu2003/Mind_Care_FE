import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AppUser?> fetchUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.id, doc.data()!);
    }
    return null;
  }
  Future<void> createOrUpdateUser(AppUser user) async {
    await _firestore.collection("users").doc(user.uid).set(
      user.toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> updateUser(AppUser user) async {
    await _firestore.collection("users").doc(user.uid).update(user.toMap());
  }
}
