import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../models/user_progress.dart';
import '../services/sync_service_v2.dart';
import '../services/local_db_v2.dart';
import '../services/supabase_service_v2.dart';

class FlashcardProviderV2 extends ChangeNotifier {
  List<FlashcardWithProgress> _flashcards = [];
  List<FlashcardWithProgress> _filteredCards = [];
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;
  String _currentUserId = '';
  
  // Sync status
  SyncStatus _syncStatus = SyncStatus.idle;
  SyncConflict? _currentConflict;
  
  // Filters
  String? _selectedCategory;
  String? _selectedDifficulty;
  String _searchQuery = '';

  // Getters
  List<FlashcardWithProgress> get flashcards => _flashcards;
  List<FlashcardWithProgress> get filteredCards => _filteredCards;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SyncStatus get syncStatus => _syncStatus;
  SyncConflict? get currentConflict => _currentConflict;
  
  String? get selectedCategory => _selectedCategory;
  String? get selectedDifficulty => _selectedDifficulty;
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

  // Initialize the provider
  Future<void> initialize(String userId) async {
    _setLoading(true);
    
    try {
      // Store current user ID
      _currentUserId = userId;
      
      // Initialize local database
      await LocalDbV2.instance.init();
      
      // Initialize sync service
      await SyncServiceV2.instance.init();
      
      // Set up sync listeners
      SyncServiceV2.instance.addStatusListener(_onSyncStatusChanged);
      SyncServiceV2.instance.addConflictListener(_onSyncConflict);
      
      // First, ensure we have flashcard content (check content separately from user progress)
      final localContent = await LocalDbV2.instance.getAllFlashcardContent();
      if (localContent.isEmpty) {
        debugPrint('No local flashcard content found, syncing from Supabase...');
        await _syncFlashcardContentFromSupabase();
      }
      
      // Now load user-specific data (content + progress)
      await _loadLocalData();
      
      // Create user profile if it doesn't exist
      if (_userProfile == null && userId.isNotEmpty) {
        await createUserProfile(userId);
      }
      
      // Attempt auto sync
      if (userId.isNotEmpty) {
        _performAutoSync(userId);
      }
      
      debugPrint('FlashcardProviderV2 initialized with ${_flashcards.length} cards for user $userId');
      
    } catch (e) {
      _setError(e.toString());
      debugPrint('Error initializing FlashcardProviderV2: $e');
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    SyncServiceV2.instance.removeStatusListener(_onSyncStatusChanged);
    SyncServiceV2.instance.removeConflictListener(_onSyncConflict);
    super.dispose();
  }

  // Load data from local database
  Future<void> _loadLocalData() async {
    try {
      _userProfile = await LocalDbV2.instance.getUserProfile(userId: _currentUserId);
      _flashcards = await LocalDbV2.instance.getFlashcardsWithProgress(userId: _currentUserId);
      _filteredCards = List.from(_flashcards);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local data: $e');
    }
  }

  // Perform auto sync in background
  void _performAutoSync(String userId) {
    SyncServiceV2.instance.autoSync(userId).catchError((e) {
      debugPrint('Auto sync failed: $e');
    });
  }

  // Manual sync triggered by user
  Future<void> manualSync(String userId) async {
    try {
      await SyncServiceV2.instance.manualSync(userId);
      await _loadLocalData(); // Refresh data after sync
    } catch (e) {
      _setError('Sync failed: $e');
    }
  }

  // Download progress from cloud (for new device)
  Future<void> downloadFromCloud(String userId) async {
    _setLoading(true);
    try {
      await SyncServiceV2.instance.downloadProgress(userId);
      await _loadLocalData();
    } catch (e) {
      _setError('Download failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Upload progress to cloud (overwrite cloud)
  Future<void> uploadToCloud(String userId) async {
    _setLoading(true);
    try {
      await SyncServiceV2.instance.uploadProgress(userId);
    } catch (e) {
      _setError('Upload failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Resolve sync conflict
  Future<void> resolveConflict(String userId, ConflictResolution resolution) async {
    if (_currentConflict == null) return;
    
    _setLoading(true);
    try {
      await SyncServiceV2.instance.resolveConflict(userId, resolution);
      await _loadLocalData();
      _currentConflict = null;
    } catch (e) {
      _setError('Conflict resolution failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Sync status listener
  void _onSyncStatusChanged(SyncStatus status) {
    _syncStatus = status;
    notifyListeners();
  }

  // Sync conflict listener
  void _onSyncConflict(SyncConflict conflict) {
    _currentConflict = conflict;
    notifyListeners();
  }

  // Get cards due for review (spaced repetition)
  List<FlashcardWithProgress> getCardsForReview() {
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

  // Get cards by difficulty
  List<FlashcardWithProgress> getCardsByDifficulty(String difficulty) {
    return _flashcards
        .where((card) => card.predefinedDifficulty == difficulty)
        .toList();
  }

  // Get cards by category
  List<FlashcardWithProgress> getCardsByCategory(String category) {
    return _flashcards
        .where((card) => card.dataStructureCategory == category)
        .toList();
  }

  // Get card by ID
  FlashcardWithProgress? getCardById(String id) {
    return _flashcards.firstWhereOrNull((card) => card.id == id);
  }

  // Update card progress after study session
  Future<void> updateCardProgress(String cardId, {
    required int personalDifficulty,
    int? reviewCount,
    double? easeFactor,
    int? intervalDays,
    DateTime? nextReview,
    DateTime? lastReviewedAt,
  }) async {
    try {
      // Find the card
      final cardIndex = _flashcards.indexWhere((card) => card.id == cardId);
      if (cardIndex == -1) return;

      final card = _flashcards[cardIndex];
      final userId = _userProfile?.userId ?? '';

      // Create or update progress
      final progress = FlashcardProgress(
        id: '${userId}_$cardId',
        userId: userId,
        flashcardId: cardId,
        personalDifficulty: personalDifficulty,
        reviewCount: reviewCount ?? (card.reviewCount + 1),
        easeFactor: easeFactor ?? card.easeFactor,
        intervalDays: intervalDays ?? card.intervalDays,
        nextReview: nextReview,
        lastReviewedAt: lastReviewedAt ?? DateTime.now(),
      );

      // Save to local database
      await LocalDbV2.instance.saveFlashcardProgress(progress);

      // Update local state
      _flashcards[cardIndex] = card.copyWith(
        personalDifficulty: personalDifficulty,
        reviewCount: progress.reviewCount,
        easeFactor: progress.easeFactor,
        intervalDays: progress.intervalDays,
        nextReview: nextReview,
        lastReviewedAt: progress.lastReviewedAt,
        progressUpdatedAt: progress.updatedAt,
      );

      _applyFilters();
      notifyListeners();

      // Update user profile stats
      await _updateUserStats();

    } catch (e) {
      _setError('Failed to update progress: $e');
    }
  }

  // Update user profile statistics
  Future<void> _updateUserStats() async {
    if (_userProfile == null) return;

    try {
      final stats = await LocalDbV2.instance.getStudyStats();
      final now = DateTime.now();
      
      // Calculate streak
      int currentStreak = _userProfile!.currentStreak;
      if (_userProfile!.lastStudyDate != null) {
        final daysSinceLastStudy = now.difference(_userProfile!.lastStudyDate!).inDays;
        if (daysSinceLastStudy == 1) {
          currentStreak += 1;
        } else if (daysSinceLastStudy > 1) {
          currentStreak = 1; // Reset streak but count today
        }
        // If daysSinceLastStudy == 0, keep current streak (studied today already)
      } else {
        currentStreak = 1; // First study session
      }

      final updatedProfile = _userProfile!.copyWith(
        currentStreak: currentStreak,
        longestStreak: currentStreak > _userProfile!.longestStreak 
            ? currentStreak : _userProfile!.longestStreak,
        totalCardsStudied: stats['totalProgress'] ?? 0,
        lastStudyDate: now,
      );

      await LocalDbV2.instance.saveUserProfile(updatedProfile);
      _userProfile = updatedProfile;
      notifyListeners();

    } catch (e) {
      debugPrint('Error updating user stats: $e');
    }
  }

  // Apply filters to flashcards
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

  // Filter methods
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

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = null;
    _selectedDifficulty = null;
    _searchQuery = '';
    _filteredCards = List.from(_flashcards);
    notifyListeners();
  }

  // Get comprehensive statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      return await LocalDbV2.instance.getStudyStats(userId: _currentUserId);
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return {};
    }
  }

  // Get basic statistics (for immediate use)
  Map<String, dynamic> getBasicStatistics() {
    final totalCards = _flashcards.length;
    final masteredCards = _flashcards.where((card) => 
        card.personalDifficulty >= 4).length;
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
      'currentStreak': _userProfile?.currentStreak ?? 0,
      'longestStreak': _userProfile?.longestStreak ?? 0,
      'totalCardsStudied': _userProfile?.totalCardsStudied ?? 0,
    };
  }

  // Reset user progress
  Future<void> resetProgress(String userId) async {
    _setLoading(true);
    
    try {
      // Clear all progress data
      await LocalDbV2.instance.clearFlashcardProgress();
      
      // Reset user profile
      if (_userProfile != null) {
        final resetProfile = _userProfile!.copyWith(
          currentStreak: 0,
          longestStreak: 0,
          totalCardsStudied: 0,
          lastStudyDate: null,
        );
        await LocalDbV2.instance.saveUserProfile(resetProfile);
        _userProfile = resetProfile;
      }
      
      // Reload data
      await _loadLocalData();
      
    } catch (e) {
      _setError('Failed to reset progress: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Clear all data
  Future<void> resetAllData(String userId) async {
    _setLoading(true);
    
    try {
      await SyncServiceV2.instance.resetUserData(userId);
      await _loadLocalData();
    } catch (e) {
      _setError('Failed to reset all data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create user profile if it doesn't exist
  Future<void> createUserProfile(String userId, {String? displayName}) async {
    if (_userProfile != null) return;

    try {
      final profile = UserProfile(
        userId: userId,
        displayName: displayName,
        settings: UserSettings(),
      );

      await LocalDbV2.instance.saveUserProfile(profile);
      _userProfile = profile;
      notifyListeners();

    } catch (e) {
      _setError('Failed to create user profile: $e');
    }
  }

  // Update user settings
  Future<void> updateUserSettings(UserSettings settings) async {
    if (_userProfile == null) return;

    try {
      final updatedProfile = _userProfile!.copyWith(settings: settings);
      await LocalDbV2.instance.saveUserProfile(updatedProfile);
      _userProfile = updatedProfile;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update settings: $e');
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Sync flashcard content from Supabase to local database
  Future<void> _syncFlashcardContentFromSupabase() async {
    try {
      debugPrint('Syncing flashcard content from Supabase...');
      
      // Use SupabaseServiceV2 to fetch all flashcard content
      final supabaseService = SupabaseServiceV2.instance;
      final flashcards = await supabaseService.pullFlashcardContent();
      
      debugPrint('Fetched ${flashcards.length} flashcards from Supabase');
      
      // Save to local database
      await LocalDbV2.instance.upsertFlashcardContent(flashcards);
      
      // Reload local data
      await _loadLocalData();
      
      debugPrint('Successfully synced flashcard content to local database');
      
    } catch (e) {
      debugPrint('Error syncing flashcard content: $e');
      _setError('Failed to sync flashcard content: $e');
      rethrow; // Re-throw to see the error in logs
    }
  }

  // Public method to manually trigger flashcard content sync
  Future<void> syncFlashcardContent() async {
    _setLoading(true);
    try {
      await _syncFlashcardContentFromSupabase();
    } finally {
      _setLoading(false);
    }
  }
}
