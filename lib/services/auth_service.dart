import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<AppUser?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) return null;
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    String avatarUrl = user.photoURL ?? '';
    String phone = user.phoneNumber ?? '';
    String name = user.displayName ?? '';
    String email = user.email ?? '';

    if (userDoc.exists) {
      final data = userDoc.data()!;
      name = (data['name'] ?? '').isNotEmpty ? data['name'] : name;
      email = (data['email'] ?? '').isNotEmpty ? data['email'] : email;
      avatarUrl =
          (data['avatarUrl'] ?? '').isNotEmpty ? data['avatarUrl'] : avatarUrl;
      phone = (data['phone'] ?? '').isNotEmpty ? data['phone'] : phone;
    }

    final appUser = AppUser(
      uid: user.uid,
      name: name,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(appUser.toMap(), SetOptions(merge: true));
    return appUser;
  }

  Future<AppUser?> signInWithEmail(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    final appUser = AppUser(
      uid: user.uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      lastLogin: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).update({
      'lastLogin': appUser.lastLogin,
    });

    return appUser;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }
}
