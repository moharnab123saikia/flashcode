import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_progress.dart';
import '../models/flashcard_content.dart';

class SupabaseServiceV2 {
  SupabaseServiceV2._();
  static final SupabaseServiceV2 instance = SupabaseServiceV2._();

  SupabaseClient get client => Supabase.instance.client;

  Future<void> init() async {
    // Supabase.initialize should be called once in main()
    // This method exists for symmetry with LocalDb.init()
  }

  // ============================================
  // FLASHCARD CONTENT (Static, Read-Only)
  // ============================================

  /// Pull all flashcard content (static data only)
  Future<List<FlashcardContent>> pullFlashcardContent() async {
    try {
      final res = await client
          .from('flashcards_clean')
          .select('*')
          .order('created_at');

      return res.map((row) => FlashcardContent.fromJson(_convertRow(row))).toList();
    } catch (e) {
      debugPrint('Error pulling flashcard content: $e');
      rethrow;
    }
  }

  /// Upsert flashcard content (for initial data setup)
  Future<void> upsertFlashcardContent(List<FlashcardContent> cards) async {
    if (cards.isEmpty) return;
    
    try {
      final payload = cards.map((card) => _convertToRow(card.toJson())).toList();
      
      await client
          .from('flashcards_clean')
          .upsert(payload, onConflict: 'id');
      
      debugPrint('Successfully upserted ${cards.length} flashcard content records');
    } catch (e) {
      debugPrint('Error upserting flashcard content: $e');
      rethrow;
    }
  }

  // ============================================
  // USER PROFILES
  // ============================================

  /// Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final res = await client
          .from('user_profiles')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (res == null) return null;
      
      return UserProfile.fromJson(_convertUserProfileRow(res));
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      rethrow;
    }
  }

  /// Upsert user profile
  Future<void> upsertUserProfile(UserProfile profile) async {
    try {
      final payload = _convertUserProfileToRow(profile);
      
      await client
          .from('user_profiles')
          .upsert(payload, onConflict: 'user_id');
      
      debugPrint('Successfully upserted user profile for ${profile.userId}');
    } catch (e) {
      debugPrint('Error upserting user profile: $e');
      rethrow;
    }
  }

  // ============================================
  // USER FLASHCARD PROGRESS
  // ============================================

  /// Get user's flashcard progress
  Future<List<FlashcardProgress>> getUserFlashcardProgress(String userId) async {
    try {
      final res = await client
          .from('user_flashcard_progress')
          .select('*')
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      return res.map((row) => FlashcardProgress.fromJson(_convertProgressRow(row))).toList();
    } catch (e) {
      debugPrint('Error getting user flashcard progress: $e');
      rethrow;
    }
  }

  /// Upsert user flashcard progress
  Future<void> upsertFlashcardProgress(List<FlashcardProgress> progressList) async {
    if (progressList.isEmpty) return;
    
    try {
      final payload = progressList.map((progress) => _convertProgressToRow(progress)).toList();
      
      await client
          .from('user_flashcard_progress')
          .upsert(payload, onConflict: 'user_id,flashcard_id');
      
      debugPrint('Successfully upserted ${progressList.length} progress records');
    } catch (e) {
      debugPrint('Error upserting flashcard progress: $e');
      rethrow;
    }
  }

  /// Upsert single flashcard progress
  Future<void> upsertSingleFlashcardProgress(FlashcardProgress progress) async {
    try {
      final payload = _convertProgressToRow(progress);
      
      await client
          .from('user_flashcard_progress')
          .upsert(payload, onConflict: 'user_id,flashcard_id');
      
      debugPrint('Successfully upserted progress for card ${progress.flashcardId}');
    } catch (e) {
      debugPrint('Error upserting single flashcard progress: $e');
      rethrow;
    }
  }

  // ============================================
  // COMBINED VIEW FOR UI
  // ============================================

  /// Get flashcards with user progress (using the view)
  Future<List<FlashcardWithProgress>> getFlashcardsWithProgress(String userId) async {
    try {
      final res = await client
          .from('user_flashcards')
          .select('*')
          .eq('user_id', userId)
          .order('created_at');

      return res.map((row) => FlashcardWithProgress.fromJson(_convertWithProgressRow(row))).toList();
    } catch (e) {
      debugPrint('Error getting flashcards with progress: $e');
      rethrow;
    }
  }

  /// Get cards due for review
  Future<List<FlashcardWithProgress>> getCardsDueForReview(String userId) async {
    try {
      final res = await client
          .from('cards_due_for_review')
          .select('*')
          .eq('user_id', userId)
          .order('next_review');

      return res.map((row) => FlashcardWithProgress.fromJson(_convertWithProgressRow(row))).toList();
    } catch (e) {
      debugPrint('Error getting cards due for review: $e');
      rethrow;
    }
  }

  // ============================================
  // SYNC METADATA
  // ============================================

  /// Get sync metadata
  Future<SyncMetadata?> getSyncMetadata(String userId) async {
    try {
      final res = await client
          .from('sync_metadata')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (res == null) return null;
      
      return SyncMetadata.fromJson(_convertSyncMetadataRow(res));
    } catch (e) {
      debugPrint('Error getting sync metadata: $e');
      rethrow;
    }
  }

  /// Upsert sync metadata
  Future<void> upsertSyncMetadata(SyncMetadata metadata) async {
    try {
      final payload = _convertSyncMetadataToRow(metadata);
      
      await client
          .from('sync_metadata')
          .upsert(payload, onConflict: 'user_id');
      
      debugPrint('Successfully upserted sync metadata for ${metadata.userId}');
    } catch (e) {
      debugPrint('Error upserting sync metadata: $e');
      rethrow;
    }
  }

  // ============================================
  // BULK OPERATIONS
  // ============================================

  /// Clear all user data (for reset)
  Future<void> clearUserData(String userId) async {
    try {
      // Delete user progress
      await client
          .from('user_flashcard_progress')
          .delete()
          .eq('user_id', userId);

      // Delete user profile
      await client
          .from('user_profiles')
          .delete()
          .eq('user_id', userId);

      // Delete sync metadata
      await client
          .from('sync_metadata')
          .delete()
          .eq('user_id', userId);

      debugPrint('Successfully cleared all data for user $userId');
    } catch (e) {
      debugPrint('Error clearing user data: $e');
      rethrow;
    }
  }

  /// Get sync summary for conflict resolution
  Future<Map<String, dynamic>> getSyncSummary(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      final progressList = await getUserFlashcardProgress(userId);
      final metadata = await getSyncMetadata(userId);

      return {
        'profile': profile?.toJson(),
        'progressCount': progressList.length,
        'cardsStudiedToday': progressList.where((p) => 
          p.lastReviewedAt != null && 
          _isSameDay(p.lastReviewedAt!, DateTime.now())).length,
        'currentStreak': profile?.currentStreak ?? 0,
        'lastSyncAt': metadata?.lastSyncTimestamp.toIso8601String(),
        'lastStudyDate': profile?.lastStudyDate?.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting sync summary: $e');
      rethrow;
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Convert database row to FlashcardContent format
  Map<String, dynamic> _convertRow(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'title': row['title'],
      'question': row['question'],
      'hint': row['hint'],
      'solutions': row['solutions'],
      'dataStructureCategory': row['data_structure_category'],
      'algorithmPattern': row['algorithm_pattern'],
      'predefinedDifficulty': row['predefined_difficulty'],
      'leetcodeNumber': row['leetcode_number'],
      'tags': row['tags'] ?? [],
      'companies': row['companies'] ?? [],
      'createdAt': DateTime.parse(row['created_at']).toIso8601String(),
    };
  }

  /// Convert FlashcardContent to database format
  Map<String, dynamic> _convertToRow(Map<String, dynamic> json) {
    return {
      'id': json['id'],
      'title': json['title'],
      'question': json['question'],
      'hint': json['hint'],
      'solutions': json['solutions'],
      'data_structure_category': json['dataStructureCategory'],
      'algorithm_pattern': json['algorithmPattern'],
      'predefined_difficulty': json['predefinedDifficulty'],
      'leetcode_number': json['leetcodeNumber'],
      'tags': json['tags'],
      'companies': json['companies'],
    };
  }

  /// Convert user profile database row to UserProfile format
  Map<String, dynamic> _convertUserProfileRow(Map<String, dynamic> row) {
    return {
      'userId': row['user_id'],
      'displayName': row['display_name'],
      'currentStreak': row['current_streak'],
      'longestStreak': row['longest_streak'],
      'totalCardsStudied': row['total_cards_studied'],
      'lastStudyDate': row['last_study_date'] != null 
          ? DateTime.parse(row['last_study_date']).toIso8601String() 
          : null,
      'settings': row['settings'],
      'createdAt': DateTime.parse(row['created_at']).toIso8601String(),
      'updatedAt': DateTime.parse(row['updated_at']).toIso8601String(),
      'lastSyncedAt': DateTime.parse(row['last_synced_at']).toIso8601String(),
    };
  }

  /// Convert UserProfile to database format
  Map<String, dynamic> _convertUserProfileToRow(UserProfile profile) {
    return {
      'user_id': profile.userId,
      'display_name': profile.displayName,
      'current_streak': profile.currentStreak,
      'longest_streak': profile.longestStreak,
      'total_cards_studied': profile.totalCardsStudied,
      'last_study_date': profile.lastStudyDate?.toIso8601String(),
      'settings': profile.settings.toJson(),
      'updated_at': profile.updatedAt.toIso8601String(),
      'last_synced_at': DateTime.now().toIso8601String(),
    };
  }

  /// Convert progress database row to FlashcardProgress format
  Map<String, dynamic> _convertProgressRow(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'userId': row['user_id'],
      'flashcardId': row['flashcard_id'],
      'personalDifficulty': row['personal_difficulty'],
      'reviewCount': row['review_count'],
      'easeFactor': row['ease_factor'],
      'intervalDays': row['interval_days'],
      'nextReview': row['next_review'] != null 
          ? DateTime.parse(row['next_review']).toIso8601String() 
          : null,
      'lastReviewedAt': row['last_reviewed_at'] != null 
          ? DateTime.parse(row['last_reviewed_at']).toIso8601String() 
          : null,
      'createdAt': DateTime.parse(row['created_at']).toIso8601String(),
      'updatedAt': DateTime.parse(row['updated_at']).toIso8601String(),
    };
  }

  /// Convert FlashcardProgress to database format
  Map<String, dynamic> _convertProgressToRow(FlashcardProgress progress) {
    return {
      'user_id': progress.userId,
      'flashcard_id': progress.flashcardId,
      'personal_difficulty': progress.personalDifficulty,
      'review_count': progress.reviewCount,
      'ease_factor': progress.easeFactor,
      'interval_days': progress.intervalDays,
      'next_review': progress.nextReview?.toIso8601String(),
      'last_reviewed_at': progress.lastReviewedAt?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Convert combined view row to FlashcardWithProgress format
  Map<String, dynamic> _convertWithProgressRow(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'title': row['title'],
      'question': row['question'],
      'hint': row['hint'],
      'solutions': row['solutions'],
      'dataStructureCategory': row['data_structure_category'],
      'algorithmPattern': row['algorithm_pattern'],
      'predefinedDifficulty': row['predefined_difficulty'],
      'leetcodeNumber': row['leetcode_number'],
      'tags': row['tags'] ?? [],
      'companies': row['companies'] ?? [],
      'createdAt': DateTime.parse(row['created_at']).toIso8601String(),
      'userId': row['user_id'],
      'personalDifficulty': row['personal_difficulty'] ?? 2,
      'reviewCount': row['review_count'] ?? 0,
      'easeFactor': row['ease_factor'] ?? 2.5,
      'intervalDays': row['interval_days'] ?? 1,
      'nextReview': row['next_review'] != null 
          ? DateTime.parse(row['next_review']).toIso8601String() 
          : null,
      'lastReviewedAt': row['last_reviewed_at'] != null 
          ? DateTime.parse(row['last_reviewed_at']).toIso8601String() 
          : null,
      'progressUpdatedAt': row['progress_updated_at'] != null 
          ? DateTime.parse(row['progress_updated_at']).toIso8601String() 
          : null,
    };
  }

  /// Convert sync metadata database row to SyncMetadata format
  Map<String, dynamic> _convertSyncMetadataRow(Map<String, dynamic> row) {
    return {
      'userId': row['user_id'],
      'lastSyncTimestamp': DateTime.parse(row['last_sync_timestamp']).toIso8601String(),
      'deviceId': row['device_id'],
      'syncVersion': row['sync_version'],
      'conflictResolutionNeeded': row['conflict_resolution_needed'],
      'createdAt': DateTime.parse(row['created_at']).toIso8601String(),
      'updatedAt': DateTime.parse(row['updated_at']).toIso8601String(),
    };
  }

  /// Convert SyncMetadata to database format
  Map<String, dynamic> _convertSyncMetadataToRow(SyncMetadata metadata) {
    return {
      'user_id': metadata.userId,
      'last_sync_timestamp': metadata.lastSyncTimestamp.toIso8601String(),
      'device_id': metadata.deviceId,
      'sync_version': metadata.syncVersion,
      'conflict_resolution_needed': metadata.conflictResolutionNeeded,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Check if two dates are on the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}
