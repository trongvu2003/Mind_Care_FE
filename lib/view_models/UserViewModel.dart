import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_repository.dart';
class UserViewModel extends ChangeNotifier {
  final UserRepository _repository = UserRepository();
  AppUser? user;
  bool isLoading = false;

  Future<void> loadUser(String uid) async {
    isLoading = true;
    notifyListeners();
    try {
      user = await _repository.fetchUser(uid);
    } catch (e) {
      print("Error fetching user: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  Future<void> updateUserInfo({
    required String name,
    required String email,
    required String phone,
    String? avatarUrl,
  }) async {
    if (user == null) return;

    final updatedUser = user!.copyWith(
      name: name,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl ?? user!.avatarUrl,
      lastLogin: DateTime.now(),
    );

    await _repository.updateUser(updatedUser); // cập nhật lên Firestore
    user = updatedUser;
    notifyListeners();
  }

}
