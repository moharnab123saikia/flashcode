import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/user_progress.dart';
import 'supabase_service_v2.dart';
import 'local_db_v2.dart';

enum SyncStatus {
  idle,
  syncing,
  conflict,
  success,
  error,
}

enum ConflictResolution {
  useLocal,
  useCloud,
  smartMerge,
}

class SyncConflict {
  final UserProfile? localProfile;
  final UserProfile? cloudProfile;
  final List<FlashcardProgress> localProgress;
  final List<FlashcardProgress> cloudProgress;
  final DateTime conflictDetectedAt;

  SyncConflict({
    this.localProfile,
    this.cloudProfile,
    required this.localProgress,
    required this.cloudProgress,
    DateTime? conflictDetectedAt,
  }) : conflictDetectedAt = conflictDetectedAt ?? DateTime.now();

  Map<String, dynamic> toSummary() {
    return {
      'local': {
        'profileExists': localProfile != null,
        'progressCount': localProgress.length,
        'cardsStudiedToday': localProgress.where((p) => 
          p.lastReviewedAt != null && 
          _isSameDay(p.lastReviewedAt!, DateTime.now())).length,
        'currentStreak': localProfile?.currentStreak ?? 0,
        'lastStudyDate': localProfile?.lastStudyDate?.toIso8601String(),
      },
      'cloud': {
        'profileExists': cloudProfile != null,
        'progressCount': cloudProgress.length,
        'cardsStudiedToday': cloudProgress.where((p) => 
          p.lastReviewedAt != null && 
          _isSameDay(p.lastReviewedAt!, DateTime.now())).length,
        'currentStreak': cloudProfile?.currentStreak ?? 0,
        'lastStudyDate': cloudProfile?.lastStudyDate?.toIso8601String(),
      },
      'conflictDetectedAt': conflictDetectedAt.toIso8601String(),
    };
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}

class SyncServiceV2 {
  SyncServiceV2._();
  static final SyncServiceV2 instance = SyncServiceV2._();

  final SupabaseServiceV2 _supabase = SupabaseServiceV2.instance;
  final LocalDbV2 _localDb = LocalDbV2.instance;

  SyncStatus _status = SyncStatus.idle;
  SyncConflict? _currentConflict;
  String? _deviceId;

  SyncStatus get status => _status;
  SyncConflict? get currentConflict => _currentConflict;

  // Status change listeners
  final List<Function(SyncStatus)> _statusListeners = [];
  final List<Function(SyncConflict)> _conflictListeners = [];

  void addStatusListener(Function(SyncStatus) listener) {
    _statusListeners.add(listener);
  }

  void removeStatusListener(Function(SyncStatus) listener) {
    _statusListeners.remove(listener);
  }

  void addConflictListener(Function(SyncConflict) listener) {
    _conflictListeners.add(listener);
  }

  void removeConflictListener(Function(SyncConflict) listener) {
    _conflictListeners.remove(listener);
  }

  void _notifyStatusChange(SyncStatus newStatus) {
    _status = newStatus;
    for (final listener in _statusListeners) {
      listener(newStatus);
    }
  }

  void _notifyConflict(SyncConflict conflict) {
    _currentConflict = conflict;
    for (final listener in _conflictListeners) {
      listener(conflict);
    }
  }

  // ============================================
  // INITIALIZATION
  // ============================================

  Future<void> init() async {
    _deviceId = await _getDeviceId();
    debugPrint('SyncServiceV2 initialized with device ID: $_deviceId');
  }

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    
    if (kIsWeb) {
      final webInfo = await deviceInfo.webBrowserInfo;
      return 'web_${webInfo.userAgent?.hashCode ?? 'unknown'}';
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return 'android_${androidInfo.id}';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return 'ios_${iosInfo.identifierForVendor ?? 'unknown'}';
    } else if (Platform.isMacOS) {
      final macInfo = await deviceInfo.macOsInfo;
      return 'macos_${macInfo.systemGUID ?? 'unknown'}';
    } else {
      return 'unknown_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // ============================================
  // MAIN SYNC OPERATIONS
  // ============================================

  /// Perform automatic sync (called on app start, background, etc.)
  Future<void> autoSync(String userId) async {
    try {
      _notifyStatusChange(SyncStatus.syncing);
      
      // Check if user has cloud sync enabled
      final localProfile = await _localDb.getUserProfile();
      if (localProfile?.settings.cloudSyncEnabled != true) {
        _notifyStatusChange(SyncStatus.idle);
        return;
      }

      // Detect conflicts first
      final conflict = await _detectConflicts(userId);
      if (conflict != null) {
        _notifyStatusChange(SyncStatus.conflict);
        _notifyConflict(conflict);
        return;
      }

      // No conflicts, perform sync
      await _performSync(userId);
      _notifyStatusChange(SyncStatus.success);
      
    } catch (e) {
      debugPrint('Auto sync failed: $e');
      _notifyStatusChange(SyncStatus.error);
      rethrow;
    }
  }

  /// Manual sync triggered by user
  Future<void> manualSync(String userId) async {
    try {
      _notifyStatusChange(SyncStatus.syncing);
      
      // Always check for conflicts on manual sync
      final conflict = await _detectConflicts(userId);
      if (conflict != null) {
        _notifyStatusChange(SyncStatus.conflict);
        _notifyConflict(conflict);
        return;
      }

      await _performSync(userId);
      _notifyStatusChange(SyncStatus.success);
      
    } catch (e) {
      debugPrint('Manual sync failed: $e');
      _notifyStatusChange(SyncStatus.error);
      rethrow;
    }
  }

  /// Download user progress from cloud (for new device)
  Future<void> downloadProgress(String userId) async {
    try {
      _notifyStatusChange(SyncStatus.syncing);
      
      // Get cloud data
      final cloudProfile = await _supabase.getUserProfile(userId);
      final cloudProgress = await _supabase.getUserFlashcardProgress(userId);
      
      if (cloudProfile == null && cloudProgress.isEmpty) {
        debugPrint('No cloud data found for user $userId');
        _notifyStatusChange(SyncStatus.success);
        return;
      }

      // Clear local data first
      await _localDb.clearUserData();
      
      // Download and save cloud data locally
      if (cloudProfile != null) {
        await _localDb.saveUserProfile(cloudProfile);
      }
      
      if (cloudProgress.isNotEmpty) {
        await _localDb.saveFlashcardProgressBatch(cloudProgress);
      }

      // Update sync metadata
      final metadata = SyncMetadata(
        userId: userId,
        deviceId: _deviceId,
        lastSyncTimestamp: DateTime.now(),
      );
      await _supabase.upsertSyncMetadata(metadata);
      
      _notifyStatusChange(SyncStatus.success);
      debugPrint('Successfully downloaded progress for user $userId');
      
    } catch (e) {
      debugPrint('Download progress failed: $e');
      _notifyStatusChange(SyncStatus.error);
      rethrow;
    }
  }

  /// Upload local progress to cloud (overwrite cloud data)
  Future<void> uploadProgress(String userId) async {
    try {
      _notifyStatusChange(SyncStatus.syncing);
      
      // Get local data
      final localProfile = await _localDb.getUserProfile();
      final localProgress = await _localDb.getAllFlashcardProgress();
      
      // Upload to cloud
      if (localProfile != null) {
        await _supabase.upsertUserProfile(localProfile.copyWith(userId: userId));
      }
      
      if (localProgress.isNotEmpty) {
        final progressWithUserId = localProgress.map((p) => 
          p.copyWith(userId: userId)).toList();
        await _supabase.upsertFlashcardProgress(progressWithUserId);
      }

      // Update sync metadata
      final metadata = SyncMetadata(
        userId: userId,
        deviceId: _deviceId,
        lastSyncTimestamp: DateTime.now(),
      );
      await _supabase.upsertSyncMetadata(metadata);
      
      _notifyStatusChange(SyncStatus.success);
      debugPrint('Successfully uploaded progress for user $userId');
      
    } catch (e) {
      debugPrint('Upload progress failed: $e');
      _notifyStatusChange(SyncStatus.error);
      rethrow;
    }
  }

  // ============================================
  // CONFLICT RESOLUTION
  // ============================================

  /// Hybrid Approach: Intelligent conflict detection with auto-merge capabilities
  /// Profile data: Cloud-first with local preferences override
  /// Progress data: Time-based resolution with conflict detection for significant differences
  Future<SyncConflict?> _detectConflicts(String userId) async {
    try {
      // Get local data
      final localProfile = await _localDb.getUserProfile();
      final localProgress = await _localDb.getAllFlashcardProgress();
      
      // Get cloud data
      final cloudProfile = await _supabase.getUserProfile(userId);
      final cloudProgress = await _supabase.getUserFlashcardProgress(userId);

      // No conflict if no cloud data exists
      if (cloudProfile == null && cloudProgress.isEmpty) {
        return null;
      }

      // No conflict if no local data exists
      if (localProfile == null && localProgress.isEmpty) {
        return null;
      }

      // HYBRID APPROACH: Analyze conflicts with time-based resolution
      final now = DateTime.now();
      bool hasSignificantConflict = false;
      List<String> conflictingCards = [];

      if (localProgress.isNotEmpty && cloudProgress.isNotEmpty) {
        // Create maps for efficient lookup
        final localProgressMap = {for (var p in localProgress) p.flashcardId: p};
        final cloudProgressMap = {for (var p in cloudProgress) p.flashcardId: p};

        // Check for progress conflicts with intelligent thresholds
        for (final flashcardId in {...localProgressMap.keys, ...cloudProgressMap.keys}) {
          final localProg = localProgressMap[flashcardId];
          final cloudProg = cloudProgressMap[flashcardId];

          // Card exists in both - apply hybrid conflict detection
          if (localProg != null && cloudProg != null) {
            final lastReviewDiff = _daysDifference(localProg.lastReviewedAt, cloudProg.lastReviewedAt);
            final reviewCountDiff = (localProg.reviewCount - cloudProg.reviewCount).abs();
            
            // HYBRID CRITERIA:
            // 1. Recent activity (< 24hrs) → Auto-merge intelligently
            // 2. Significant conflicts → User choice
            // 3. Minor differences → Auto-merge
            
            bool isRecentActivity = lastReviewDiff <= 1; // Within 24 hours
            bool hasSignificantDifference = reviewCountDiff > 3 ||
                                          localProg.personalDifficulty != cloudProg.personalDifficulty;
            bool hasMajorTimeDrift = lastReviewDiff > 7; // More than a week apart
            
            // Only flag as conflict if:
            // - Significant differences AND not recent activity
            // - OR major time drift with any differences
            if ((hasSignificantDifference && !isRecentActivity) ||
                (hasMajorTimeDrift && reviewCountDiff > 1)) {
              hasSignificantConflict = true;
              conflictingCards.add(flashcardId);
              debugPrint('🚨 Hybrid conflict detected for card $flashcardId: '
                        'reviewDiff=$reviewCountDiff, timeDiff=${lastReviewDiff}d, '
                        'Local(reviews=${localProg.reviewCount}, diff=${localProg.personalDifficulty}) vs '
                        'Cloud(reviews=${cloudProg.reviewCount}, diff=${cloudProg.personalDifficulty})');
            } else if (reviewCountDiff > 0 || localProg.personalDifficulty != cloudProg.personalDifficulty) {
              // Auto-merge candidate - log for debugging
              debugPrint('✨ Auto-merge candidate for card $flashcardId: '
                        'reviewDiff=$reviewCountDiff, timeDiff=${lastReviewDiff}d');
            }
          }
          // Cards that exist only locally or only in cloud are always auto-merged
        }
      }

      if (hasSignificantConflict) {
        debugPrint('🔥 Significant conflicts detected for ${conflictingCards.length} cards: ${conflictingCards.join(", ")}');
        return SyncConflict(
          localProfile: localProfile,
          cloudProfile: cloudProfile, // Cloud profile is always authoritative
          localProgress: localProgress,
          cloudProgress: cloudProgress,
        );
      }

      // No significant conflicts - auto-merge will be performed
      debugPrint('✅ No significant conflicts detected - proceeding with hybrid auto-merge');
      return null;
    } catch (e) {
      debugPrint('Error detecting conflicts: $e');
      rethrow;
    }
  }

  /// Helper method to calculate days difference between two nullable dates
  int _daysDifference(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return 0;
    return (date1.difference(date2).inDays).abs();
  }

  /// Resolve conflict using specified strategy
  Future<void> resolveConflict(String userId, ConflictResolution resolution) async {
    if (_currentConflict == null) {
      throw Exception('No conflict to resolve');
    }

    try {
      _notifyStatusChange(SyncStatus.syncing);

      switch (resolution) {
        case ConflictResolution.useLocal:
          await _resolveWithLocal(userId);
          break;
        case ConflictResolution.useCloud:
          await _resolveWithCloud(userId);
          break;
        case ConflictResolution.smartMerge:
          await _resolveWithSmartMerge(userId);
          break;
      }

      _currentConflict = null;
      _notifyStatusChange(SyncStatus.success);
      
    } catch (e) {
      debugPrint('Conflict resolution failed: $e');
      _notifyStatusChange(SyncStatus.error);
      rethrow;
    }
  }

  Future<void> _resolveWithLocal(String userId) async {
    // Upload local data, overwriting cloud
    await uploadProgress(userId);
  }

  Future<void> _resolveWithCloud(String userId) async {
    // Download cloud data, overwriting local
    await downloadProgress(userId);
  }

  Future<void> _resolveWithSmartMerge(String userId) async {
    final conflict = _currentConflict!;
    
    // Smart merge logic
    UserProfile? mergedProfile;
    final mergedProgress = <String, FlashcardProgress>{};

    // Merge profiles (take max values where appropriate)
    if (conflict.localProfile != null || conflict.cloudProfile != null) {
      final local = conflict.localProfile;
      final cloud = conflict.cloudProfile;
      
      mergedProfile = UserProfile(
        userId: userId,
        displayName: cloud?.displayName ?? local?.displayName,
        currentStreak: _maxStreak(local?.currentStreak ?? 0, cloud?.currentStreak ?? 0),
        longestStreak: _max(local?.longestStreak ?? 0, cloud?.longestStreak ?? 0),
        totalCardsStudied: _max(local?.totalCardsStudied ?? 0, cloud?.totalCardsStudied ?? 0),
        lastStudyDate: _latestDate(local?.lastStudyDate, cloud?.lastStudyDate),
        settings: cloud?.settings ?? local?.settings ?? UserSettings(),
      );
    }

    // Merge progress (take higher review counts and later review dates)
    for (final progress in conflict.localProgress) {
      mergedProgress[progress.flashcardId] = progress;
    }

    for (final progress in conflict.cloudProgress) {
      final existing = mergedProgress[progress.flashcardId];
      if (existing == null) {
        mergedProgress[progress.flashcardId] = progress.copyWith(userId: userId);
      } else {
        // Merge: take higher review count and more recent data
        mergedProgress[progress.flashcardId] = FlashcardProgress(
          id: existing.id,
          userId: userId,
          flashcardId: progress.flashcardId,
          personalDifficulty: _max(existing.personalDifficulty, progress.personalDifficulty),
          reviewCount: _max(existing.reviewCount, progress.reviewCount),
          easeFactor: progress.reviewCount > existing.reviewCount ? progress.easeFactor : existing.easeFactor,
          intervalDays: progress.reviewCount > existing.reviewCount ? progress.intervalDays : existing.intervalDays,
          nextReview: _latestDate(existing.nextReview, progress.nextReview),
          lastReviewedAt: _latestDate(existing.lastReviewedAt, progress.lastReviewedAt),
        );
      }
    }

    // Save merged data locally
    await _localDb.clearUserData();
    if (mergedProfile != null) {
      await _localDb.saveUserProfile(mergedProfile);
    }
    if (mergedProgress.isNotEmpty) {
      await _localDb.saveFlashcardProgressBatch(mergedProgress.values.toList());
    }

    // Upload merged data to cloud
    await uploadProgress(userId);
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// HYBRID SYNC: Intelligent auto-merge without conflict detection
  /// Implements cloud-first profile data with smart progress merging
  Future<void> _performSync(String userId) async {
    debugPrint('🔄 Starting hybrid sync for user $userId');
    
    // Get local and cloud data
    final localProfile = await _localDb.getUserProfile();
    final localProgress = await _localDb.getAllFlashcardProgress();
    final cloudProfile = await _supabase.getUserProfile(userId);
    final cloudProgress = await _supabase.getUserFlashcardProgress(userId);

    // HYBRID PROFILE SYNC: Cloud-first with local preference preservation
    UserProfile? syncedProfile;
    if (cloudProfile != null || localProfile != null) {
      syncedProfile = _hybridMergeProfile(userId, localProfile, cloudProfile);
      
      // Save locally and upload to cloud
      if (syncedProfile != null) {
        await _localDb.saveUserProfile(syncedProfile);
        await _supabase.upsertUserProfile(syncedProfile);
      }
    }

    // HYBRID PROGRESS SYNC: Intelligent time-based merging
    if (localProgress.isNotEmpty || cloudProgress.isNotEmpty) {
      final mergedProgress = _hybridMergeProgress(userId, localProgress, cloudProgress);
      
      // Save locally and upload to cloud
      if (mergedProgress.isNotEmpty) {
        await _localDb.saveFlashcardProgressBatch(mergedProgress);
        await _supabase.upsertFlashcardProgress(mergedProgress);
      }
    }

    // Update sync metadata
    final metadata = SyncMetadata(
      userId: userId,
      deviceId: _deviceId,
      lastSyncTimestamp: DateTime.now(),
    );
    await _supabase.upsertSyncMetadata(metadata);
    
    debugPrint('✅ Hybrid sync completed successfully');
  }

  /// Hybrid profile merge: Cloud-first with local preferences
  UserProfile? _hybridMergeProfile(String userId, UserProfile? local, UserProfile? cloud) {
    if (cloud == null && local == null) return null;
    if (cloud == null) return local?.copyWith(userId: userId);
    if (local == null) return cloud;

    // Cloud data is authoritative for account data
    // Local preferences override cloud where appropriate
    return UserProfile(
      userId: userId,
      displayName: cloud.displayName, // Cloud authoritative
      currentStreak: cloud.currentStreak, // Cloud authoritative
      longestStreak: _max(local.longestStreak, cloud.longestStreak), // Take max
      totalCardsStudied: cloud.totalCardsStudied, // Cloud authoritative
      lastStudyDate: cloud.lastStudyDate, // Cloud authoritative
      settings: UserSettings(
        cloudSyncEnabled: cloud.settings.cloudSyncEnabled, // Cloud authoritative
        notificationsEnabled: local.settings.notificationsEnabled, // Local preference
        notificationTime: local.settings.notificationTime, // Local preference
        dailyGoal: local.settings.dailyGoal, // Local preference
        sessionDuration: local.settings.sessionDuration, // Local preference
        theme: local.settings.theme, // Local preference
        defaultLanguage: local.settings.defaultLanguage, // Local preference
        codeFontSize: local.settings.codeFontSize, // Local preference
        spacedRepetitionAlgorithm: local.settings.spacedRepetitionAlgorithm, // Local preference
      ),
    );
  }

  /// Hybrid progress merge: Time-based intelligent merging
  List<FlashcardProgress> _hybridMergeProgress(String userId,
      List<FlashcardProgress> local, List<FlashcardProgress> cloud) {
    
    final mergedProgress = <String, FlashcardProgress>{};
    final now = DateTime.now();

    // Add all local progress first
    for (final progress in local) {
      mergedProgress[progress.flashcardId] = progress.copyWith(userId: userId);
    }

    // Merge cloud progress with hybrid logic
    for (final cloudProg in cloud) {
      final localProg = mergedProgress[cloudProg.flashcardId];
      
      if (localProg == null) {
        // Card only exists in cloud - add it
        mergedProgress[cloudProg.flashcardId] = cloudProg.copyWith(userId: userId);
      } else {
        // Card exists in both - apply hybrid merge logic
        final timeDiff = _daysDifference(localProg.lastReviewedAt, cloudProg.lastReviewedAt);
        
        // HYBRID MERGE RULES:
        // 1. Recent activity (< 24hrs) → Take more recent
        // 2. Significant time gap (> 7 days) → Take more recent
        // 3. Similar timing → Merge intelligently
        
        if (timeDiff <= 1) {
          // Recent activity - take the one with more reviews or more recent
          if (cloudProg.reviewCount > localProg.reviewCount ||
              (cloudProg.reviewCount == localProg.reviewCount &&
               _isMoreRecent(cloudProg.lastReviewedAt, localProg.lastReviewedAt))) {
            mergedProgress[cloudProg.flashcardId] = cloudProg.copyWith(userId: userId);
          }
          // Otherwise keep local
        } else if (timeDiff > 7) {
          // Major time gap - take more recent
          if (_isMoreRecent(cloudProg.lastReviewedAt, localProg.lastReviewedAt)) {
            mergedProgress[cloudProg.flashcardId] = cloudProg.copyWith(userId: userId);
          }
          // Otherwise keep local
        } else {
          // Intelligent merge for moderate time differences
          mergedProgress[cloudProg.flashcardId] = FlashcardProgress(
            id: localProg.id,
            userId: userId,
            flashcardId: cloudProg.flashcardId,
            personalDifficulty: _max(localProg.personalDifficulty, cloudProg.personalDifficulty),
            reviewCount: _max(localProg.reviewCount, cloudProg.reviewCount),
            easeFactor: cloudProg.reviewCount > localProg.reviewCount
                       ? cloudProg.easeFactor : localProg.easeFactor,
            intervalDays: cloudProg.reviewCount > localProg.reviewCount
                         ? cloudProg.intervalDays : localProg.intervalDays,
            nextReview: _latestDate(localProg.nextReview, cloudProg.nextReview),
            lastReviewedAt: _latestDate(localProg.lastReviewedAt, cloudProg.lastReviewedAt),
          );
        }
      }
    }

    return mergedProgress.values.toList();
  }

  /// Check if date1 is more recent than date2
  bool _isMoreRecent(DateTime? date1, DateTime? date2) {
    if (date1 == null && date2 == null) return false;
    if (date1 == null) return false;
    if (date2 == null) return true;
    return date1.isAfter(date2);
  }

  int _max(int a, int b) => a > b ? a : b;
  
  DateTime? _latestDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  int _maxStreak(int localStreak, int cloudStreak) {
    // For streaks, we might want different logic
    // For now, take the maximum
    return _max(localStreak, cloudStreak);
  }

  // ============================================
  // UTILITY METHODS
  // ============================================

  /// Get sync summary for UI display
  Future<Map<String, dynamic>> getSyncSummary(String userId) async {
    try {
      return await _supabase.getSyncSummary(userId);
    } catch (e) {
      debugPrint('Error getting sync summary: $e');
      rethrow;
    }
  }

  /// Reset all user data (for testing/debugging)
  Future<void> resetUserData(String userId) async {
    try {
      await _localDb.clearUserData();
      await _supabase.clearUserData(userId);
      debugPrint('Successfully reset all data for user $userId');
    } catch (e) {
      debugPrint('Error resetting user data: $e');
      rethrow;
    }
  }

  /// Check if sync is available (user logged in and has internet)
  bool get isSyncAvailable {
    // This would check internet connectivity and auth status
    // For now, return true if we have a device ID
    return _deviceId != null;
  }
}
