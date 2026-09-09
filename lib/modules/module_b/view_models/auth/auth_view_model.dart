import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:locate_my/modules/module_b/repositories/auth/auth_repository.dart';

class AuthViewModel with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthViewModel() {
    _user = _authRepository.currentUser;
    if (_user != null) {
      _authRepository.ensureProfileExists();
    }
    _authRepository.authStateChanges.listen((data) {
      _user = data.session?.user;
      if (_user != null) {
        _authRepository.ensureProfileExists();
      }
      notifyListeners();
    });
  }

  Future<bool> signUp(String email, String password, {String? username}) async {
    _setLoading(true);
    _clearError();
    try {
      await _authRepository.signUp(
        email: email,
        password: password,
        username: username,
      );
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'unexpected_error';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _authRepository.signIn(email: email, password: password);
      await _authRepository.ensureProfileExists();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'unexpected_error';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
