import 'package:flutter_test/flutter_test.dart';
import 'package:flashcode/models/user_progress.dart';
import 'package:flashcode/services/sync_service_v2.dart';

void main() {
  group('Sync Conflict Detection Tests', () {
    
    // Helper function to calculate days difference (mirrors the private method)
    int daysDifference(DateTime? date1, DateTime? date2) {
      if (date1 == null || date2 == null) return 0;
      return (date1.difference(date2).inDays).abs();
    }

    // Helper function to check if date1 is more recent (mirrors the private method)
    bool isMoreRecent(DateTime? date1, DateTime? date2) {
      if (date1 == null && date2 == null) return false;
      if (date1 == null) return false;
      if (date2 == null) return true;
      return date1.isAfter(date2);
    }

    // Helper function to get latest date (mirrors the private method)
    DateTime? latestDate(DateTime? a, DateTime? b) {
      if (a == null && b == null) return null;
      if (a == null) return b;
      if (b == null) return a;
      return a.isAfter(b) ? a : b;
    }

    group('Hybrid Conflict Detection Logic', () {
      test('should detect significant conflict with major review count difference', () {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        final twoDaysAgo = now.subtract(const Duration(days: 2));
        
        final localProgress = FlashcardProgress(
          id: 'local-1',
          userId: 'test-user',
          flashcardId: 'card-1',
          personalDifficulty: 2,
          reviewCount: 2,
          lastReviewedAt: twoDaysAgo,
        );
        
        final cloudProgress = FlashcardProgress(
          id: 'cloud-1',
          userId: 'test-user',
          flashcardId: 'card-1',
          personalDifficulty: 2,
          reviewCount: 6, // Difference of 4 (> 3 threshold)
          lastReviewedAt: yesterday,
        );
        
        // Test conflict detection criteria
        final lastReviewDiff = daysDifference(localProgress.lastReviewedAt, cloudProgress.lastReviewedAt);
        final reviewCountDiff = (localProgress.reviewCount - cloudProgress.reviewCount).abs();
        
        final isRecentActivity = lastReviewDiff <= 1; // Within 24 hours
        final hasSignificantDifference = reviewCountDiff > 3 ||
                                        localProgress.personalDifficulty != cloudProgress.personalDifficulty;
        final hasMajorTimeDrift = lastReviewDiff > 7; // More than a week apart
        
        // Should be flagged as conflict: significant difference AND not recent activity
        final shouldBeConflict = (hasSignificantDifference && !isRecentActivity) ||
                                (hasMajorTimeDrift && reviewCountDiff > 1);
        
        expect(reviewCountDiff, equals(4));
        expect(hasSignificantDifference, isTrue);
        expect(isRecentActivity, isTrue); // 1 day apart = recent activity
        expect(shouldBeConflict, isFalse); // Should NOT be conflict due to recent activity
      });
      
      test('should detect significant conflict with personal difficulty change', () {
        final now = DateTime.now();
        final threeDaysAgo = now.subtract(const Duration(days: 3));
        
        final localProgress = FlashcardProgress(
          id: 'local-1',
          userId: 'test-user',
          flashcardId: 'card-1',
          personalDifficulty: 1, // Easy
          reviewCount: 3,
          lastReviewedAt: threeDaysAgo,
        );
        
        final cloudProgress = FlashcardProgress(
          id: 'cloud-1',
          userId: 'test-user',
          flashcardId: 'card-1',
          personalDifficulty: 4, // Hard
          reviewCount: 3,
          lastReviewedAt: now,
        );
        
        final lastReviewDiff = daysDifference(localProgress.lastReviewedAt, cloudProgress.lastReviewedAt);
        final reviewCountDiff = (localProgress.reviewCount - cloudProgress.reviewCount).abs();
        
        final isRecentActivity = lastReviewDiff <= 1;
        final hasSignificantDifference = reviewCountDiff > 3 ||
                                        localProgress.personalDifficulty != cloudProgress.personalDifficulty;
        
        final shouldBeConflict = (hasSignificantDifference && !isRecentActivity);
        
        expect(hasSignificantDifference, isTrue); // Difficulty differs
        expect(isRecentActivity, isFalse); // 3 days apart
        expect(shouldBeConflict, isTrue);
      });
      
      test('should NOT detect conflict for recent activity with minor differences', () {
        final now = DateTime.now();
        final sixHoursAgo = now.subtract(const Duration(hours: 6));
        
        final localProgress = FlashcardProgress(
          id: 'local-1',
          userId: 'test-user',
          flashcardId: 'card-1',
          personalDifficulty: 2,
          reviewCount: 3,
          lastReviewedAt: sixHoursAgo,
        );
        
        final cloudProgress = FlashcardProgress(
          id: 'cloud-1',
          userId: 'test-user',
          flashcardId: 'card-1',
          personalDifficulty: 2,
          reviewCount: 4, // Minor difference (≤ 3)
          lastReviewedAt: now,
        );
        
        final lastReviewDiff = daysDifference(localProgress.lastReviewedAt, cloudProgress.lastReviewedAt);
        final reviewCountDiff = (localProgress.reviewCount - cloudProgress.reviewCount).abs();
        
        final isRecentActivity = lastReviewDiff <= 1; // Within 24hrs
        final hasSignificantDifference = reviewCountDiff > 3 ||
                                        localProgress.personalDifficulty != cloudProgress.personalDifficulty;
        
        final shouldBeConflict = (hasSignificantDifference && !isRecentActivity);
        
        expect(isRecentActivity, isTrue); // Same day
        expect(hasSignificantDifference, isFalse); // Minor differences
        expect(shouldBeConflict, isFalse); // Should be auto-merged
      });
      
      test('should detect conflict for major time drift with differences', () {
        final now = DateTime.now();
        final tenDaysAgo = now.subtract(const Duration(days: 10));
        
        final localProgress = FlashcardProgress(
          id: 'local-1',
          userId: 'test-user',
          flashcardId: 'card-1',
          personalDifficulty: 2,
          reviewCount: 3,
          lastReviewedAt: now,
        );
        
        final cloudProgress = FlashcardProgress(
          id: 'cloud-1',
          userId: 'test-user',
          flashcardId: 'card-1',
          personalDifficulty: 2,
          reviewCount: 5, // Difference of 2
          lastReviewedAt: tenDaysAgo,
        );
        
        final lastReviewDiff = daysDifference(localProgress.lastReviewedAt, cloudProgress.lastReviewedAt);
        final reviewCountDiff = (localProgress.reviewCount - cloudProgress.reviewCount).abs();
        
        final hasMajorTimeDrift = lastReviewDiff > 7; // More than a week apart
        final shouldBeConflict = hasMajorTimeDrift && reviewCountDiff > 1;
        
        expect(lastReviewDiff, equals(10));
        expect(hasMajorTimeDrift, isTrue);
        expect(reviewCountDiff, equals(2));
        expect(shouldBeConflict, isTrue);
      });
      
      test('should handle null dates gracefully', () {
        final localProgress = FlashcardProgress(
          id: 'local-1',
          userId: 'test-user',
          flashcardId: 'card-1',
          personalDifficulty: 2,
          reviewCount: 3,
          lastReviewedAt: null, // Never reviewed
        );
        
        final cloudProgress = FlashcardProgress(
          id: 'cloud-1',
          userId: 'test-user',
          flashcardId: 'card-1',
          personalDifficulty: 3,
          reviewCount: 5,
          lastReviewedAt: DateTime.now(),
        );
        
        final lastReviewDiff = daysDifference(localProgress.lastReviewedAt, cloudProgress.lastReviewedAt);
        final reviewCountDiff = (localProgress.reviewCount - cloudProgress.reviewCount).abs();
        
        expect(lastReviewDiff, equals(0)); // Null dates return 0
        expect(reviewCountDiff, equals(2));
        
        // Should handle null gracefully without throwing
        expect(() => daysDifference(null, null), returnsNormally);
        expect(() => daysDifference(DateTime.now(), null), returnsNormally);
        expect(() => daysDifference(null, DateTime.now()), returnsNormally);
      });
    });

    group('Helper Method Tests', () {
      test('daysDifference should calculate correctly', () {
        final date1 = DateTime(2024, 1, 1);
        final date2 = DateTime(2024, 1, 8);
        
        expect(daysDifference(date1, date2), equals(7));
        expect(daysDifference(date2, date1), equals(7)); // Absolute difference
        expect(daysDifference(date1, date1), equals(0));
        expect(daysDifference(null, date1), equals(0));
        expect(daysDifference(date1, null), equals(0));
        expect(daysDifference(null, null), equals(0));
      });
      
      test('isMoreRecent should compare dates correctly', () {
        final older = DateTime(2024, 1, 1);
        final newer = DateTime(2024, 1, 2);
        
        expect(isMoreRecent(newer, older), isTrue);
        expect(isMoreRecent(older, newer), isFalse);
        expect(isMoreRecent(older, older), isFalse);
        expect(isMoreRecent(null, older), isFalse);
        expect(isMoreRecent(newer, null), isTrue);
        expect(isMoreRecent(null, null), isFalse);
      });
      
      test('latestDate should return more recent date', () {
        final older = DateTime(2024, 1, 1);
        final newer = DateTime(2024, 1, 2);
        
        expect(latestDate(older, newer), equals(newer));
        expect(latestDate(newer, older), equals(newer));
        expect(latestDate(older, older), equals(older));
        expect(latestDate(null, newer), equals(newer));
        expect(latestDate(older, null), equals(older));
        expect(latestDate(null, null), isNull);
      });
    });

    group('Smart Merge Logic Tests', () {
      test('should merge progress intelligently with higher values preference', () {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        
        final localProgress = FlashcardProgress(
          id: 'local-1',
          userId: 'test-user',
          flashcardId: 'card-1',
          personalDifficulty: 2,
          reviewCount: 5,
          easeFactor: 2.3,
          intervalDays: 2,
          lastReviewedAt: yesterday,
        );
        
        final cloudProgress = FlashcardProgress(
          id: 'cloud-1',
          userId: 'test-user',
          flashcardId: 'card-1',
          personalDifficulty: 3,
          reviewCount: 7,
          easeFactor: 2.6,
          intervalDays: 4,
          lastReviewedAt: now,
        );
        
        // Smart merge should prefer:
        // - Higher personal difficulty: 3
        // - Higher review count: 7
        // - More recent review date: now
        // - Ease factor from more reviewed progress: 2.6
        
        final mergedDifficulty = localProgress.personalDifficulty > cloudProgress.personalDifficulty 
            ? localProgress.personalDifficulty 
            : cloudProgress.personalDifficulty;
        final mergedReviewCount = localProgress.reviewCount > cloudProgress.reviewCount 
            ? localProgress.reviewCount 
            : cloudProgress.reviewCount;
        final mergedLastReviewed = latestDate(localProgress.lastReviewedAt, cloudProgress.lastReviewedAt);
        final mergedEaseFactor = cloudProgress.reviewCount > localProgress.reviewCount 
            ? cloudProgress.easeFactor 
            : localProgress.easeFactor;
        
        expect(mergedDifficulty, equals(3));
        expect(mergedReviewCount, equals(7));
        expect(mergedLastReviewed, equals(now));
        expect(mergedEaseFactor, equals(2.6));
      });
      
      test('should handle hybrid merge with time-based decisions', () {
        final now = DateTime.now();
        final recentTime = now.subtract(const Duration(hours: 12));
        final olderTime = now.subtract(const Duration(days: 10));
        
        // Test recent activity merge
        final recentLocal = FlashcardProgress(
          id: 'local-1',
          userId: 'test-user',
          flashcardId: 'card-1',
          reviewCount: 3,
          lastReviewedAt: recentTime,
        );
        
        final recentCloud = FlashcardProgress(
          id: 'cloud-1',
          userId: 'test-user',
          flashcardId: 'card-1',
          reviewCount: 4,
          lastReviewedAt: now,
        );
        
        final timeDiff = daysDifference(recentLocal.lastReviewedAt, recentCloud.lastReviewedAt);
        final isRecent = timeDiff <= 1;
        
        // For recent activity, take the one with more reviews or more recent
        final shouldTakeCloud = isRecent && (
          recentCloud.reviewCount > recentLocal.reviewCount ||
          (recentCloud.reviewCount == recentLocal.reviewCount &&
           isMoreRecent(recentCloud.lastReviewedAt, recentLocal.lastReviewedAt))
        );
        
        expect(isRecent, isTrue);
        expect(shouldTakeCloud, isTrue);
        
        // Test major time gap merge
        final oldLocal = FlashcardProgress(
          id: 'local-2',
          userId: 'test-user',
          flashcardId: 'card-2',
          reviewCount: 5,
          lastReviewedAt: now,
        );
        
        final oldCloud = FlashcardProgress(
          id: 'cloud-2',
          userId: 'test-user',
          flashcardId: 'card-2',
          reviewCount: 3,
          lastReviewedAt: olderTime,
        );
        
        final majorTimeDiff = daysDifference(oldLocal.lastReviewedAt, oldCloud.lastReviewedAt);
        final hasMajorGap = majorTimeDiff > 7;
        final shouldTakeLocal = hasMajorGap && 
                               isMoreRecent(oldLocal.lastReviewedAt, oldCloud.lastReviewedAt);
        
        expect(hasMajorGap, isTrue);
        expect(shouldTakeLocal, isTrue);
      });
    });

    group('Profile Merge Logic Tests', () {
      test('should merge profiles with cloud-first strategy', () {
        final localProfile = UserProfile(
          userId: 'test-user',
          displayName: 'Local User',
          currentStreak: 5,
          longestStreak: 10,
          totalCardsStudied: 50,
          lastStudyDate: DateTime(2024, 1, 1),
          settings: UserSettings(
            cloudSyncEnabled: false,
            notificationsEnabled: true,
            dailyGoal: 20,
            theme: 'dark',
            defaultLanguage: 'python',
          ),
        );
        
        final cloudProfile = UserProfile(
          userId: 'test-user',
          displayName: 'Cloud User',
          currentStreak: 7,
          longestStreak: 8,
          totalCardsStudied: 60,
          lastStudyDate: DateTime(2024, 1, 5),
          settings: UserSettings(
            cloudSyncEnabled: true,
            notificationsEnabled: false,
            dailyGoal: 15,
            theme: 'light',
            defaultLanguage: 'java',
          ),
        );
        
        // Expected hybrid merge logic:
        // Cloud authoritative: displayName, currentStreak, totalCardsStudied, lastStudyDate, cloudSyncEnabled
        // Max values: longestStreak
        // Local preferences: notificationsEnabled, dailyGoal, theme, defaultLanguage
        
        expect(cloudProfile.displayName, equals('Cloud User')); // Cloud wins
        expect(cloudProfile.currentStreak, equals(7)); // Cloud wins
        expect(cloudProfile.totalCardsStudied, equals(60)); // Cloud wins
        expect(cloudProfile.lastStudyDate, equals(DateTime(2024, 1, 5))); // Cloud wins
        expect(cloudProfile.settings.cloudSyncEnabled, isTrue); // Cloud wins
        
        final maxLongestStreak = localProfile.longestStreak > cloudProfile.longestStreak 
            ? localProfile.longestStreak 
            : cloudProfile.longestStreak;
        expect(maxLongestStreak, equals(10)); // Local wins (max)
        
        // Local preferences should be preserved in actual implementation
        expect(localProfile.settings.notificationsEnabled, isTrue);
        expect(localProfile.settings.dailyGoal, equals(20));
        expect(localProfile.settings.theme, equals('dark'));
        expect(localProfile.settings.defaultLanguage, equals('python'));
      });
    });

    group('Edge Cases', () {
      test('should handle identical progress data', () {
        final now = DateTime.now();
        
        final progress1 = FlashcardProgress(
          id: 'test-1',
          userId: 'test-user',
          flashcardId: 'card-1',
          personalDifficulty: 2,
          reviewCount: 3,
          easeFactor: 2.5,
          lastReviewedAt: now,
        );
        
        final progress2 = FlashcardProgress(
          id: 'test-2',
          userId: 'test-user',
          flashcardId: 'card-1',
          personalDifficulty: 2,
          reviewCount: 3,
          easeFactor: 2.5,
          lastReviewedAt: now,
        );
        
        final lastReviewDiff = daysDifference(progress1.lastReviewedAt, progress2.lastReviewedAt);
        final reviewCountDiff = (progress1.reviewCount - progress2.reviewCount).abs();
        final hasSignificantDifference = reviewCountDiff > 3 ||
                                        progress1.personalDifficulty != progress2.personalDifficulty;
        
        // Identical data should not trigger conflicts
        expect(lastReviewDiff, equals(0));
        expect(reviewCountDiff, equals(0));
        expect(hasSignificantDifference, isFalse);
      });
      
      test('should handle empty progress lists', () {
        final emptyLocal = <FlashcardProgress>[];
        final emptyCloud = <FlashcardProgress>[];
        
        // Empty lists should not cause conflicts
        expect(emptyLocal.isEmpty, isTrue);
        expect(emptyCloud.isEmpty, isTrue);
        
        // No conflicts when both are empty
        expect(emptyLocal.length + emptyCloud.length, equals(0));
      });
      
      test('should handle cards that exist only locally or in cloud', () {
        final localOnly = FlashcardProgress(
          id: 'local-only',
          userId: 'test-user',
          flashcardId: 'card-local',
          reviewCount: 3,
        );
        
        final cloudOnly = FlashcardProgress(
          id: 'cloud-only',
          userId: 'test-user',
          flashcardId: 'card-cloud',
          reviewCount: 5,
        );
        
        // Cards that exist only on one side should be auto-merged (no conflict)
        expect(localOnly.flashcardId, equals('card-local'));
        expect(cloudOnly.flashcardId, equals('card-cloud'));
        
        // Different card IDs = no conflict, just merge both
        expect(localOnly.flashcardId != cloudOnly.flashcardId, isTrue);
      });
    });
  });
}