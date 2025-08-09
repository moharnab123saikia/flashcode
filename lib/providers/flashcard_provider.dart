import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../models/flashcard.dart';
import '../services/sync_service.dart';

class FlashcardProvider extends ChangeNotifier {
  List<Flashcard> _flashcards = [];
  List<Flashcard> _filteredCards = [];
  bool _isLoading = false;
  String? _error;
  
  // Filters
  String? _selectedCategory;
  String? _selectedDifficulty;
  int? _selectedWeek;
  String _searchQuery = '';

  List<Flashcard> get flashcards => _flashcards;
  List<Flashcard> get filteredCards => _filteredCards;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  String? get selectedCategory => _selectedCategory;
  String? get selectedDifficulty => _selectedDifficulty;
  int? get selectedWeek => _selectedWeek;
  String get searchQuery => _searchQuery;

  // Get unique categories
  List<String> get categories {
    return _flashcards
        .map((card) => card.dataStructureCategory)
        .toSet()
        .toList()
      ..sort();
  }

  // Get unique algorithm patterns
  List<String> get algorithmPatterns {
    return _flashcards
        .map((card) => card.algorithmPattern)
        .where((pattern) => pattern != null)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();
  }

  // Get cards for spaced repetition
  List<Flashcard> getCardsForReview() {
    final now = DateTime.now();
    return _flashcards.where((card) {
      if (card.nextReview == null) return true;
      return card.nextReview!.isBefore(now) || 
             card.nextReview!.isAtSameMomentAs(now);
    }).toList()
      ..sort((a, b) {
        if (a.nextReview == null && b.nextReview == null) return 0;
        if (a.nextReview == null) return -1;
        if (b.nextReview == null) return 1;
        return a.nextReview!.compareTo(b.nextReview!);
      });
  }

  // Get cards by category (removed week-based functionality)
  List<Flashcard> getCardsByDifficulty(String difficulty) {
    return _flashcards
        .where((card) => card.predefinedDifficulty == difficulty)
        .toList();
  }

  // Get cards by category
  List<Flashcard> getCardsByCategory(String category) {
    return _flashcards
        .where((card) => card.dataStructureCategory == category)
        .toList();
  }

  // Get card by ID
  Flashcard? getCardById(String id) {
    return _flashcards.firstWhereOrNull((card) => card.id == id);
  }

  // Initialize with sample data
  Future<void> initializeSampleData() async {
    _setLoading(true);
    
    try {
      // Initialize with sample data if needed
      await SyncService.instance.initializeWithSampleData();
      
      // Load from local DB
      _flashcards = await SyncService.instance.getAllFlashcards();
      _filteredCards = List.from(_flashcards);
      
      // Try to sync with remote
      _syncWithRemote();
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load flashcards from database
  Future<void> loadFlashcards() async {
    _setLoading(true);
    
    try {
      // Load from local DB
      _flashcards = await SyncService.instance.getAllFlashcards();
      _filteredCards = List.from(_flashcards);
      notifyListeners();
      
      // Try to sync with remote in background
      _syncWithRemote();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Sync with remote database
  Future<void> _syncWithRemote() async {
    try {
      final result = await SyncService.instance.syncWithRemote();
      if (result.success && (result.pulledCount > 0)) {
        // Reload if we pulled new data
        _flashcards = await SyncService.instance.getAllFlashcards();
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      // Sync errors are non-critical, just log them
      debugPrint('Sync error: $e');
    }
  }

  // Update flashcard after review
  Future<void> updateFlashcard(Flashcard updatedCard) async {
    final index = _flashcards.indexWhere((card) => card.id == updatedCard.id);
    if (index != -1) {
      _flashcards[index] = updatedCard;
      _applyFilters();
      notifyListeners();
      
      // Save to both local and remote
      await SyncService.instance.saveFlashcard(updatedCard);
    }
  }

  // Apply filters
  void _applyFilters() {
    _filteredCards = _flashcards.where((card) {
      // Category filter
      if (_selectedCategory != null && 
          card.dataStructureCategory != _selectedCategory) {
        return false;
      }
      
      // Difficulty filter
      if (_selectedDifficulty != null && 
          card.predefinedDifficulty != _selectedDifficulty) {
        return false;
      }
      
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return card.title.toLowerCase().contains(query) ||
               card.question.toLowerCase().contains(query) ||
               card.tags.any((tag) => tag.toLowerCase().contains(query));
      }
      
      return true;
    }).toList();
  }

  // Set filters
  void setCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setDifficulty(String? difficulty) {
    _selectedDifficulty = difficulty;
    _applyFilters();
    notifyListeners();
  }

  void setWeek(int? week) {
    _selectedWeek = week;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = null;
    _selectedDifficulty = null;
    _selectedWeek = null;
    _searchQuery = '';
    _filteredCards = List.from(_flashcards);
    notifyListeners();
  }

  // Get statistics
  Map<String, dynamic> getStatistics() {
    final totalCards = _flashcards.length;
    final masteredCards = _flashcards.where((card) => 
        card.personalDifficulty == 4).length;
    final reviewedCards = _flashcards.where((card) => 
        card.reviewCount > 0).length;
    
    final categoryStats = <String, int>{};
    for (final card in _flashcards) {
      categoryStats[card.dataStructureCategory] = 
          (categoryStats[card.dataStructureCategory] ?? 0) + 1;
    }
    
    final difficultyStats = {
      'Easy': _flashcards.where((c) => c.predefinedDifficulty == 'Easy').length,
      'Medium': _flashcards.where((c) => c.predefinedDifficulty == 'Medium').length,
      'Hard': _flashcards.where((c) => c.predefinedDifficulty == 'Hard').length,
    };
    
    return {
      'totalCards': totalCards,
      'masteredCards': masteredCards,
      'reviewedCards': reviewedCards,
      'categoryStats': categoryStats,
      'difficultyStats': difficultyStats,
    };
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
