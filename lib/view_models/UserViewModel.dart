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
}
