import 'package:flutter/material.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Mock user for development
  void initMockUser() {
    _currentUser = User(
      id: 'mock_user_1',
      email: 'user@example.com',
      displayName: 'Test User',
      progress: UserProgress(
        totalCardsStudied: 34,
        currentStreak: 7,
        longestStreak: 15,
        grind75Completed: 34,
        categoryProgress: {
          'Arrays & Strings': 12,
          'Linked Lists': 5,
          'Trees & BST': 8,
          'Graphs': 3,
          'Dynamic Programming': 6,
        },
        categoryMastery: {
          'Arrays & Strings': 0.8,
          'Linked Lists': 0.6,
          'Trees & BST': 0.4,
          'Graphs': 0.2,
          'Dynamic Programming': 0.3,
        },
        weeklyProgress: {
          1: 8,
          2: 4,
          3: 0,
        },
      ),
    );
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      // TODO: Implement Firebase authentication
      await Future.delayed(const Duration(seconds: 1));
      initMockUser();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    
    try {
      // TODO: Implement Google Sign In
      await Future.delayed(const Duration(seconds: 1));
      initMockUser();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithApple() async {
    _setLoading(true);
    _clearError();
    
    try {
      // TODO: Implement Apple Sign In
      await Future.delayed(const Duration(seconds: 1));
      initMockUser();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUp(String email, String password, String displayName) async {
    _setLoading(true);
    _clearError();
    
    try {
      // TODO: Implement Firebase sign up
      await Future.delayed(const Duration(seconds: 1));
      initMockUser();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      // TODO: Implement Firebase sign out
      await Future.delayed(const Duration(milliseconds: 500));
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void updateUserProgress(UserProgress progress) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(progress: progress);
      notifyListeners();
    }
  }

  void updateUserSettings(UserSettings settings) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(settings: settings);
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
