import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/study_session.dart';
import '../models/flashcard.dart';
import '../utils/spaced_repetition.dart';

class StudySessionProvider extends ChangeNotifier {
  StudySession? _currentSession;
  List<StudySession> _sessionHistory = [];
  bool _isLoading = false;
  String? _error;
  
  StudySession? get currentSession => _currentSession;
  List<StudySession> get sessionHistory => _sessionHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveSession => _currentSession != null && !_currentSession!.isCompleted;

  // Start a new study session
  Future<void> startSession({
    required String userId,
    required List<Flashcard> cards,
    required String mode,
    List<String>? targetTags,
    List<String>? targetCategories,
  }) async {
    if (hasActiveSession) {
      _setError('Please complete the current session first');
      return;
    }

    _setLoading(true);
    
    try {
      final sessionId = const Uuid().v4();
      final cardIds = cards.map((card) => card.id).toList();
      
      _currentSession = StudySession(
        id: sessionId,
        userId: userId,
        mode: mode,
        targetTags: targetTags,
        targetCategories: targetCategories,
        cardIds: cardIds,
        totalCards: cards.length,
      );
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Record card review result
  void recordCardResult({
    required String cardId,
    required int rating,
    required int timeSpent,
    bool hintUsed = false,
    bool solutionViewed = false,
  }) {
    if (_currentSession == null) return;
    
    final result = SessionCardResult(
      cardId: cardId,
      rating: rating,
      timeSpent: timeSpent,
      hintUsed: hintUsed,
      solutionViewed: solutionViewed,
    );
    
    _currentSession!.results[cardId] = result;
    
    // Update completed count
    final completedCards = _currentSession!.results.length;
    _currentSession = StudySession(
      id: _currentSession!.id,
      userId: _currentSession!.userId,
      mode: _currentSession!.mode,
      targetTags: _currentSession!.targetTags,
      targetCategories: _currentSession!.targetCategories,
      startedAt: _currentSession!.startedAt,
      cardIds: _currentSession!.cardIds,
      results: _currentSession!.results,
      totalCards: _currentSession!.totalCards,
      completedCards: completedCards,
      duration: DateTime.now().difference(_currentSession!.startedAt).inSeconds,
    );
    
    notifyListeners();
  }

  // Complete the current session
  Future<void> completeSession() async {
    if (_currentSession == null) return;
    
    _setLoading(true);
    
    try {
      final completedSession = StudySession(
        id: _currentSession!.id,
        userId: _currentSession!.userId,
        mode: _currentSession!.mode,
        targetTags: _currentSession!.targetTags,
        targetCategories: _currentSession!.targetCategories,
        startedAt: _currentSession!.startedAt,
        completedAt: DateTime.now(),
        cardIds: _currentSession!.cardIds,
        results: _currentSession!.results,
        totalCards: _currentSession!.totalCards,
        completedCards: _currentSession!.completedCards,
        duration: DateTime.now().difference(_currentSession!.startedAt).inSeconds,
      );
      
      _sessionHistory.add(completedSession);
      _currentSession = null;
      
      // TODO: Save to Firebase
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Pause session (save progress)
  Future<void> pauseSession() async {
    if (_currentSession == null) return;
    
    // TODO: Save session state to local storage
    notifyListeners();
  }

  // Resume session
  Future<void> resumeSession() async {
    // TODO: Load session state from local storage
    notifyListeners();
  }

  // Cancel current session
  void cancelSession() {
    _currentSession = null;
    notifyListeners();
  }

  // Load session history
  Future<void> loadSessionHistory(String userId) async {
    _setLoading(true);
    
    try {
      // TODO: Load from Firebase
      await Future.delayed(const Duration(seconds: 1));
      _sessionHistory = [];
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Get session statistics
  Map<String, dynamic> getSessionStatistics() {
    if (_sessionHistory.isEmpty) {
      return {
        'totalSessions': 0,
        'totalCardsStudied': 0,
        'averageAccuracy': 0.0,
        'totalTimeSpent': 0,
        'preferredMode': 'N/A',
      };
    }
    
    int totalCards = 0;
    int totalTime = 0;
    int goodRatings = 0;
    int totalRatings = 0;
    Map<String, int> modeCount = {};
    
    for (final session in _sessionHistory) {
      totalCards += session.completedCards;
      totalTime += session.duration;
      
      modeCount[session.mode] = (modeCount[session.mode] ?? 0) + 1;
      
      for (final result in session.results.values) {
        totalRatings++;
        if (result.rating >= 2) {
          goodRatings++;
        }
      }
    }
    
    final preferredMode = modeCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    return {
      'totalSessions': _sessionHistory.length,
      'totalCardsStudied': totalCards,
      'averageAccuracy': totalRatings > 0 ? (goodRatings / totalRatings) * 100 : 0.0,
      'totalTimeSpent': totalTime,
      'preferredMode': preferredMode,
    };
  }

  // Calculate next review date using spaced repetition
  Flashcard calculateNextReview(Flashcard card, int rating) {
    return SpacedRepetition.calculateNextReview(card, rating);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}
