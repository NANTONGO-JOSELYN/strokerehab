import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  late SharedPreferences _prefs;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasCompletedOnboarding => _currentUser?.hasCompletedOnboarding ?? false;

  AuthProvider() {
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadStoredUser();
  }

  /// Load user from local storage (for persistence across app restarts)
  Future<void> _loadStoredUser() async {
    try {
      final userJson = _prefs.getString('current_user');
      if (userJson != null) {
        _currentUser = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to load user data: $e';
      debugPrint('Error loading stored user: $e');
    }
  }

  /// Save user to local storage
  Future<void> _saveUserLocally(User user) async {
    try {
      await _prefs.setString('current_user', jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Error saving user: $e');
    }
  }

  /// Mock login function — replace with actual backend API call
  Future<bool> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock validation
      if (email.isEmpty || password.isEmpty) {
        _errorMessage = 'Email and password are required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!email.contains('@')) {
        _errorMessage = 'Invalid email format';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Mock successful login
      _currentUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        fullName: email.split('@')[0], // Use email prefix as name for demo
        role: role,
        createdAt: DateTime.now(),
        hasCompletedOnboarding: false,
      );

      await _saveUserLocally(_currentUser!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mock sign up function
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
        _errorMessage = 'All fields are required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!email.contains('@')) {
        _errorMessage = 'Invalid email format';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.length < 6) {
        _errorMessage = 'Password must be at least 6 characters';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        fullName: fullName,
        role: role,
        createdAt: DateTime.now(),
        hasCompletedOnboarding: false,
      );

      await _saveUserLocally(_currentUser!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Sign up failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(hasCompletedOnboarding: true);
      await _saveUserLocally(_currentUser!);
      notifyListeners();
    }
  }

  /// Logout
  Future<void> logout() async {
    _currentUser = null;
    await _prefs.remove('current_user');
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
