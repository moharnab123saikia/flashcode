import 'package:flutter/foundation.dart';
import '../models/flashcard.dart';
import '../data/sample_flashcards.dart';
import 'local_db_stub.dart'
    if (dart.library.io) 'local_db.dart'
    if (dart.library.html) 'local_db_web.dart';
import 'supabase_service.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final LocalDb _localDb = LocalDb.instance;
  final SupabaseService _supabase = SupabaseService.instance;

  Future<void> init() async {
    await _localDb.init();
    await _supabase.init();
  }

  /// Initialize with sample data if needed
  Future<void> initializeWithSampleData() async {
    try {
      // Check if we have any local data
      final localCards = await _localDb.getAllFlashcards();
      debugPrint('Found ${localCards.length} local cards');
      
      if (localCards.isEmpty) {
        debugPrint('No local cards found, loading sample data...');
        // Load sample data
        final sampleCards = SampleFlashcards.getAllCards();
        debugPrint('Loaded ${sampleCards.length} sample cards');
        
        // Save to local DB
        await _localDb.upsertFlashcards(sampleCards);
        debugPrint('Saved sample cards to local DB');
        
        // Try to save to remote (may fail if offline or not configured)
        try {
          debugPrint('Attempting to save to Supabase...');
          await _supabase.upsertFlashcards(sampleCards);
          debugPrint('Successfully saved sample data to Supabase!');
        } catch (e) {
          debugPrint('Failed to save sample data to Supabase: $e');
        }
      } else {
        debugPrint('Local data exists, attempting to sync to Supabase...');
        try {
          await _supabase.upsertFlashcards(localCards);
          debugPrint('Successfully synced ${localCards.length} cards to Supabase!');
        } catch (e) {
          debugPrint('Failed to sync existing data to Supabase: $e');
        }
      }
    } catch (e) {
      debugPrint('Error initializing sample data: $e');
    }
  }

  /// Get all flashcards (from local DB)
  Future<List<Flashcard>> getAllFlashcards() async {
    return await _localDb.getAllFlashcards();
  }

  /// Save a flashcard (to both local and remote)
  Future<void> saveFlashcard(Flashcard card) async {
    // Always save to local first
    await _localDb.upsertFlashcard(card);
    
    // Try to save to remote
    try {
      await _supabase.upsertFlashcard(card);
    } catch (e) {
      debugPrint('Failed to save flashcard to Supabase: $e');
      // Local save succeeded, so we don't throw
    }
  }

  /// Save multiple flashcards
  Future<void> saveFlashcards(List<Flashcard> cards) async {
    // Save to local
    await _localDb.upsertFlashcards(cards);
    
    // Try to save to remote
    try {
      await _supabase.upsertFlashcards(cards);
    } catch (e) {
      debugPrint('Failed to save flashcards to Supabase: $e');
    }
  }

  /// Sync with remote (pull from Supabase and merge with local)
  Future<SyncResult> syncWithRemote() async {
    try {
      // Pull from remote
      final remoteCards = await _supabase.pullFlashcards();
      
      // Get local cards
      final localCards = await _localDb.getAllFlashcards();
      
      // Create maps for easy lookup
      final localMap = {for (var card in localCards) card.id: card};
      final remoteMap = {for (var card in remoteCards) card.id: card};
      
      // Find cards to update locally (newer on remote)
      final toUpdateLocal = <Flashcard>[];
      final toUpdateRemote = <Flashcard>[];
      
      for (final remoteCard in remoteCards) {
        final localCard = localMap[remoteCard.id];
        if (localCard == null) {
          // New card from remote
          toUpdateLocal.add(remoteCard);
        } else {
          // Compare timestamps (prefer card with more reviews or later review date)
          if (remoteCard.reviewCount > localCard.reviewCount ||
              (remoteCard.lastReviewedAt != null && 
               localCard.lastReviewedAt != null &&
               remoteCard.lastReviewedAt!.isAfter(localCard.lastReviewedAt!))) {
            toUpdateLocal.add(remoteCard);
          } else if (localCard.reviewCount > remoteCard.reviewCount ||
                     (localCard.lastReviewedAt != null && 
                      remoteCard.lastReviewedAt != null &&
                      localCard.lastReviewedAt!.isAfter(remoteCard.lastReviewedAt!))) {
            toUpdateRemote.add(localCard);
          }
        }
      }
      
      // Find cards only in local (to push to remote)
      for (final localCard in localCards) {
        if (!remoteMap.containsKey(localCard.id)) {
          toUpdateRemote.add(localCard);
        }
      }
      
      // Update local with remote changes
      if (toUpdateLocal.isNotEmpty) {
        await _localDb.upsertFlashcards(toUpdateLocal);
      }
      
      // Update remote with local changes
      if (toUpdateRemote.isNotEmpty) {
        await _supabase.upsertFlashcards(toUpdateRemote);
      }
      
      return SyncResult(
        pulledCount: toUpdateLocal.length,
        pushedCount: toUpdateRemote.length,
        totalCards: remoteCards.length,
        success: true,
      );
    } catch (e) {
      debugPrint('Sync failed: $e');
      return SyncResult(
        pulledCount: 0,
        pushedCount: 0,
        totalCards: 0,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Clear all local data
  Future<void> clearLocalData() async {
    await _localDb.clearFlashcards();
  }

  /// Reset and reload sample data
  Future<void> resetToSampleData() async {
    await clearLocalData();
    final sampleCards = SampleFlashcards.getAllCards();
    await saveFlashcards(sampleCards);
  }
}

class SyncResult {
  final int pulledCount;
  final int pushedCount;
  final int totalCards;
  final bool success;
  final String? error;

  SyncResult({
    required this.pulledCount,
    required this.pushedCount,
    required this.totalCards,
    required this.success,
    this.error,
  });
}
