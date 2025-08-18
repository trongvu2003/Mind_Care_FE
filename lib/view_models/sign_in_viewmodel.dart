import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class SignInViewModel extends ChangeNotifier {
  final AuthService _authService;
  bool isLoading = false;
  AppUser? user;
  String? error;

  SignInViewModel(this._authService);

  Future<void> signInWithGoogle() async {
    try {
      isLoading = true;
      notifyListeners();
      user = await _authService.signInWithGoogle();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();
      user = await _authService.signInWithEmail(email, password);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    user = null;
    notifyListeners();
  }
}
