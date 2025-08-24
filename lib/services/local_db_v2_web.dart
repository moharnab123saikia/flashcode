import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard_content.dart';
import '../models/user_progress.dart';

class LocalDbV2 {
  LocalDbV2._();
  static final LocalDbV2 instance = LocalDbV2._();

  // Keys for SharedPreferences
  static const _flashcardContentKey = 'flashcard_content_v2';
  static const _userProfileKey = 'user_profile_v2';
  static const _flashcardProgressKey = 'flashcard_progress_v2';

  Future<void> init() async {
    // No initialization needed for SharedPreferences
  }

  // ============================================
  // FLASHCARD CONTENT (Static Data)
  // ============================================

  Future<List<FlashcardContent>> getAllFlashcardContent() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_flashcardContentKey);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((json) => FlashcardContent.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<FlashcardContent?> getFlashcardContent(String id) async {
    final cards = await getAllFlashcardContent();
    try {
      return cards.firstWhere((card) => card.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> upsertFlashcardContent(List<FlashcardContent> cards) async {
    final prefs = await SharedPreferences.getInstance();
    final existingCards = await getAllFlashcardContent();
    final cardMap = {for (var card in existingCards) card.id: card};
    
    // Update with new cards
    for (final card in cards) {
      cardMap[card.id] = card;
    }
    
    // Save back
    final jsonList = cardMap.values.map((c) => c.toJson()).toList();
    await prefs.setString(_flashcardContentKey, jsonEncode(jsonList));
  }

  Future<void> clearFlashcardContent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_flashcardContentKey);
  }

  // ============================================
  // USER PROFILE
  // ============================================

  Future<UserProfile?> getUserProfile({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final profilesJson = prefs.getString(_userProfileKey);
    if (profilesJson == null) return null;
    
    final Map<String, dynamic> profilesMap = jsonDecode(profilesJson);
    
    if (userId == null || userId.isEmpty) {
      // Get any profile (for backward compatibility)
      final profiles = profilesMap.values;
      if (profiles.isEmpty) return null;
      return UserProfile.fromJson(profiles.first as Map<String, dynamic>);
    }
    
    final profileJson = profilesMap[userId];
    if (profileJson == null) return null;
    
    return UserProfile.fromJson(profileJson as Map<String, dynamic>);
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final profilesJson = prefs.getString(_userProfileKey) ?? '{}';
    final Map<String, dynamic> profilesMap = jsonDecode(profilesJson);
    
    profilesMap[profile.userId] = profile.toJson();
    
    await prefs.setString(_userProfileKey, jsonEncode(profilesMap));
  }

  Future<void> clearUserProfile({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId == null || userId.isEmpty) {
      // Clear all profiles
      await prefs.remove(_userProfileKey);
    } else {
      final profilesJson = prefs.getString(_userProfileKey) ?? '{}';
      final Map<String, dynamic> profilesMap = jsonDecode(profilesJson);
      profilesMap.remove(userId);
      await prefs.setString(_userProfileKey, jsonEncode(profilesMap));
    }
  }

  // ============================================
  // FLASHCARD PROGRESS
  // ============================================

  Future<List<FlashcardProgress>> getAllFlashcardProgress({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString(_flashcardProgressKey);
    if (progressJson == null) return [];
    
    final Map<String, dynamic> progressMap = jsonDecode(progressJson);
    final List<FlashcardProgress> allProgress = [];
    
    for (final entry in progressMap.entries) {
      final progress = FlashcardProgress.fromJson(entry.value as Map<String, dynamic>);
      if (userId == null || userId.isEmpty || progress.userId == userId) {
        allProgress.add(progress);
      }
    }
    
    return allProgress;
  }

  Future<FlashcardProgress?> getFlashcardProgress(String flashcardId, {String? userId}) async {
    final allProgress = await getAllFlashcardProgress(userId: userId);
    try {
      return allProgress.firstWhere((p) => p.flashcardId == flashcardId);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveFlashcardProgress(FlashcardProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString(_flashcardProgressKey) ?? '{}';
    final Map<String, dynamic> progressMap = jsonDecode(progressJson);
    
    final key = progress.id.isNotEmpty ? progress.id : progress.flashcardId;
    progressMap[key] = progress.toJson();
    
    await prefs.setString(_flashcardProgressKey, jsonEncode(progressMap));
  }

  Future<void> saveFlashcardProgressBatch(List<FlashcardProgress> progressList) async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString(_flashcardProgressKey) ?? '{}';
    final Map<String, dynamic> progressMap = jsonDecode(progressJson);
    
    for (final progress in progressList) {
      final key = progress.id.isNotEmpty ? progress.id : progress.flashcardId;
      progressMap[key] = progress.toJson();
    }
    
    await prefs.setString(_flashcardProgressKey, jsonEncode(progressMap));
  }

  Future<void> deleteFlashcardProgress(String flashcardId, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString(_flashcardProgressKey) ?? '{}';
    final Map<String, dynamic> progressMap = jsonDecode(progressJson);
    
    // Remove matching entries
    progressMap.removeWhere((key, value) {
      final progress = FlashcardProgress.fromJson(value as Map<String, dynamic>);
      if (progress.flashcardId != flashcardId) return false;
      if (userId == null || userId.isEmpty) return true;
      return progress.userId == userId;
    });
    
    await prefs.setString(_flashcardProgressKey, jsonEncode(progressMap));
  }

  Future<void> clearFlashcardProgress({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId == null || userId.isEmpty) {
      // Clear all progress
      await prefs.remove(_flashcardProgressKey);
    } else {
      final progressJson = prefs.getString(_flashcardProgressKey) ?? '{}';
      final Map<String, dynamic> progressMap = jsonDecode(progressJson);
      
      // Remove entries for specific user
      progressMap.removeWhere((key, value) {
        final progress = FlashcardProgress.fromJson(value as Map<String, dynamic>);
        return progress.userId == userId;
      });
      
      await prefs.setString(_flashcardProgressKey, jsonEncode(progressMap));
    }
  }

  // ============================================
  // COMBINED OPERATIONS
  // ============================================

  /// Get flashcards with user progress combined
  Future<List<FlashcardWithProgress>> getFlashcardsWithProgress({String? userId}) async {
    final content = await getAllFlashcardContent();
    final progress = await getAllFlashcardProgress(userId: userId);
    
    final progressMap = <String, FlashcardProgress>{};
    for (final p in progress) {
      progressMap[p.flashcardId] = p;
    }
    
    return content.map((card) {
      final userProgress = progressMap[card.id];
      
      return FlashcardWithProgress(
        id: card.id,
        title: card.title,
        question: card.question,
        hint: card.hint,
        solutions: card.solutions.map((key, value) => MapEntry(key, value.toJson())),
        dataStructureCategory: card.dataStructureCategory,
        algorithmPattern: card.algorithmPattern,
        predefinedDifficulty: card.predefinedDifficulty,
        leetcodeNumber: card.leetcodeNumber,
        tags: card.tags,
        companies: card.companies,
        createdAt: card.createdAt,
        userId: userProgress?.userId,
        personalDifficulty: userProgress?.personalDifficulty ?? 2,
        reviewCount: userProgress?.reviewCount ?? 0,
        easeFactor: userProgress?.easeFactor ?? 2.5,
        intervalDays: userProgress?.intervalDays ?? 1,
        nextReview: userProgress?.nextReview,
        lastReviewedAt: userProgress?.lastReviewedAt,
        progressUpdatedAt: userProgress?.updatedAt,
      );
    }).toList();
  }

  /// Get cards due for review
  Future<List<FlashcardWithProgress>> getCardsDueForReview({String? userId}) async {
    final cardsWithProgress = await getFlashcardsWithProgress(userId: userId);
    final now = DateTime.now();
    
    return cardsWithProgress.where((card) {
      if (card.nextReview == null) return true;
      return card.nextReview!.isBefore(now) || card.nextReview!.isAtSameMomentAs(now);
    }).toList();
  }

  /// Get study statistics
  Future<Map<String, dynamic>> getStudyStats({String? userId}) async {
    final profile = await getUserProfile(userId: userId);
    final progress = await getAllFlashcardProgress(userId: userId);
    final now = DateTime.now();
    
    final studiedToday = progress.where((p) => 
      p.lastReviewedAt != null && 
      _isSameDay(p.lastReviewedAt!, now)
    ).length;
    
    final dueForReview = progress.where((p) => 
      p.nextReview == null || 
      p.nextReview!.isBefore(now) || 
      p.nextReview!.isAtSameMomentAs(now)
    ).length;
    
    final mastered = progress.where((p) => p.personalDifficulty >= 4).length;
    
    return {
      'currentStreak': profile?.currentStreak ?? 0,
      'longestStreak': profile?.longestStreak ?? 0,
      'totalCardsStudied': profile?.totalCardsStudied ?? 0,
      'studiedToday': studiedToday,
      'dueForReview': dueForReview,
      'mastered': mastered,
      'totalProgress': progress.length,
      'lastStudyDate': profile?.lastStudyDate?.toIso8601String(),
    };
  }

  // ============================================
  // BULK OPERATIONS
  // ============================================

  /// Clear all user data (profile and progress, but keep flashcard content)
  Future<void> clearUserData() async {
    await clearUserProfile();
    await clearFlashcardProgress();
  }

  /// Clear all data
  Future<void> clearAllData() async {
    await clearFlashcardContent();
    await clearUserProfile();
    await clearFlashcardProgress();
  }

  /// Export all data for backup
  Future<Map<String, dynamic>> exportData() async {
    final profile = await getUserProfile();
    final progress = await getAllFlashcardProgress();
    final content = await getAllFlashcardContent();
    
    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profile?.toJson(),
      'progress': progress.map((p) => p.toJson()).toList(),
      'content': content.map((c) => c.toJson()).toList(),
    };
  }

  /// Import data from backup
  Future<void> importData(Map<String, dynamic> data) async {
    // Clear existing data
    await clearAllData();
    
    // Import profile
    if (data['profile'] != null) {
      final profile = UserProfile.fromJson(data['profile'] as Map<String, dynamic>);
      await saveUserProfile(profile);
    }
    
    // Import progress
    if (data['progress'] != null) {
      final progressList = (data['progress'] as List)
          .map((p) => FlashcardProgress.fromJson(p as Map<String, dynamic>))
          .toList();
      await saveFlashcardProgressBatch(progressList);
    }
    
    // Import content
    if (data['content'] != null) {
      final contentList = (data['content'] as List)
          .map((c) => FlashcardContent.fromJson(c as Map<String, dynamic>))
          .toList();
      await upsertFlashcardContent(contentList);
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Close database connection (no-op for SharedPreferences)
  Future<void> close() async {
    // No cleanup needed for SharedPreferences
  }
}
