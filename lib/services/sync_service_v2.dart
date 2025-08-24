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

  /// Detect sync conflicts
  Future<SyncConflict?> _detectConflicts(String userId) async {
    try {
      // Get local data
      final localProfile = await _localDb.getUserProfile();
      final localProgress = await _localDb.getAllFlashcardProgress();
      
      // Get cloud data
      final cloudProfile = await _supabase.getUserProfile(userId);
      final cloudProgress = await _supabase.getUserFlashcardProgress(userId);
      final cloudMetadata = await _supabase.getSyncMetadata(userId);

      // No conflict if no cloud data exists
      if (cloudProfile == null && cloudProgress.isEmpty) {
        return null;
      }

      // No conflict if no local data exists
      if (localProfile == null && localProgress.isEmpty) {
        return null;
      }

      // Check for data conflicts
      bool hasConflict = false;

      // Profile conflicts
      if (localProfile != null && cloudProfile != null) {
        if (localProfile.currentStreak != cloudProfile.currentStreak ||
            localProfile.totalCardsStudied != cloudProfile.totalCardsStudied ||
            (localProfile.lastStudyDate?.millisecondsSinceEpoch ?? 0) != 
            (cloudProfile.lastStudyDate?.millisecondsSinceEpoch ?? 0)) {
          hasConflict = true;
        }
      }

      // Progress conflicts (simplified check)
      if (localProgress.length != cloudProgress.length) {
        hasConflict = true;
      }

      // Check last sync timestamp
      if (cloudMetadata != null && _deviceId != cloudMetadata.deviceId) {
        // Different device, potential conflict
        hasConflict = true;
      }

      if (hasConflict) {
        return SyncConflict(
          localProfile: localProfile,
          cloudProfile: cloudProfile,
          localProgress: localProgress,
          cloudProgress: cloudProgress,
        );
      }

      return null;
    } catch (e) {
      debugPrint('Error detecting conflicts: $e');
      rethrow;
    }
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

  /// Perform sync without conflict detection
  Future<void> _performSync(String userId) async {
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
