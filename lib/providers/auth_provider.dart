import 'package:flutter/foundation.dart';
import '../repositories/auth_repository.dart';
import '../services/token_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  String? _userEmail;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  String? get userEmail => _userEmail;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isAuthenticated = await _authRepository.isAuthenticated();
    if (_isAuthenticated) {
      _userEmail = await TokenService.getUserEmail();
    }
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authRepository.register(
        email: email,
        password: password,
      );
      _isAuthenticated = true;
      _userEmail = response.user.email;
      await TokenService.saveUserEmail(_userEmail!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authRepository.login(
        email: email,
        password: password,
      );
      _isAuthenticated = true;
      _userEmail = response.user.email;
      await TokenService.saveUserEmail(_userEmail!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.logout();
    } finally {
      _isAuthenticated = false;
      _userEmail = null;
      _isLoading = false;
      _error = null;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

