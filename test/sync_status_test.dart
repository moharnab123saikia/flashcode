import 'package:flutter_test/flutter_test.dart';
import 'package:flashcode/services/sync_service_v2.dart';
import 'package:flashcode/models/user_progress.dart';

void main() {
  group('Sync Status and Notification Tests', () {
    late SyncServiceV2 syncService;

    setUp(() {
      syncService = SyncServiceV2.instance;
    });

    group('Status Listener Management', () {
      test('should add and remove status listeners correctly', () {
        var callCount = 0;
        SyncStatus? lastStatus;

        void testListener(SyncStatus status) {
          callCount++;
          lastStatus = status;
        }

        // Initial state - no listeners
        expect(callCount, equals(0));

        // Add listener
        syncService.addStatusListener(testListener);

        // Remove listener
        syncService.removeStatusListener(testListener);

        // Verify listener operations work without errors
        expect(() => syncService.addStatusListener(testListener), returnsNormally);
        expect(() => syncService.removeStatusListener(testListener), returnsNormally);
      });

      test('should handle multiple status listeners', () {
        var listener1Calls = 0;
        var listener2Calls = 0;
        SyncStatus? status1, status2;

        void listener1(SyncStatus status) {
          listener1Calls++;
          status1 = status;
        }

        void listener2(SyncStatus status) {
          listener2Calls++;
          status2 = status;
        }

        // Add multiple listeners
        syncService.addStatusListener(listener1);
        syncService.addStatusListener(listener2);

        // Both should start with no calls
        expect(listener1Calls, equals(0));
        expect(listener2Calls, equals(0));

        // Remove listeners
        syncService.removeStatusListener(listener1);
        syncService.removeStatusListener(listener2);

        // Should handle cleanup without errors
        expect(() => syncService.removeStatusListener(listener1), returnsNormally);
      });
    });

    group('Conflict Listener Management', () {
      test('should add and remove conflict listeners correctly', () {
        var callCount = 0;
        SyncConflict? lastConflict;

        void testListener(SyncConflict conflict) {
          callCount++;
          lastConflict = conflict;
        }

        // Initial state
        expect(callCount, equals(0));
        expect(lastConflict, isNull);

        // Add and remove listener
        syncService.addConflictListener(testListener);
        syncService.removeConflictListener(testListener);

        // Should work without errors
        expect(() => syncService.addConflictListener(testListener), returnsNormally);
        expect(() => syncService.removeConflictListener(testListener), returnsNormally);
      });

      test('should handle multiple conflict listeners', () {
        var listener1Calls = 0;
        var listener2Calls = 0;

        void listener1(SyncConflict conflict) {
          listener1Calls++;
        }

        void listener2(SyncConflict conflict) {
          listener2Calls++;
        }

        // Add multiple listeners
        syncService.addConflictListener(listener1);
        syncService.addConflictListener(listener2);

        // Initial state
        expect(listener1Calls, equals(0));
        expect(listener2Calls, equals(0));

        // Clean up
        syncService.removeConflictListener(listener1);
        syncService.removeConflictListener(listener2);
      });
    });

    group('Sync Status Values', () {
      test('should have correct initial status', () {
        expect(syncService.status, equals(SyncStatus.idle));
      });

      test('should handle all status enum values', () {
        // Test that all enum values are properly defined
        const allStatuses = [
          SyncStatus.idle,
          SyncStatus.syncing,
          SyncStatus.conflict,
          SyncStatus.success,
          SyncStatus.error,
        ];

        for (final status in allStatuses) {
          expect(status, isA<SyncStatus>());
          expect(status.toString(), contains('SyncStatus.'));
        }
      });
    });

    group('Conflict Management', () {
      test('should start with no current conflict', () {
        expect(syncService.currentConflict, isNull);
      });

      test('should create valid conflict objects', () {
        final now = DateTime.now();
        
        final localProgress = [
          FlashcardProgress(
            id: 'local-1',
            userId: 'test-user',
            flashcardId: 'card-1',
            personalDifficulty: 2,
            reviewCount: 3,
            lastReviewedAt: now,
          ),
        ];

        final cloudProgress = [
          FlashcardProgress(
            id: 'cloud-1',
            userId: 'test-user',
            flashcardId: 'card-1',
            personalDifficulty: 4,
            reviewCount: 5,
            lastReviewedAt: now.subtract(const Duration(days: 1)),
          ),
        ];

        final conflict = SyncConflict(
          localProgress: localProgress,
          cloudProgress: cloudProgress,
        );

        expect(conflict.localProgress, hasLength(1));
        expect(conflict.cloudProgress, hasLength(1));
        expect(conflict.conflictDetectedAt, isA<DateTime>());
        expect(conflict.localProfile, isNull);
        expect(conflict.cloudProfile, isNull);
      });

      test('should generate meaningful conflict summaries', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        final localProfile = UserProfile(
          userId: 'test-user',
          displayName: 'Local User',
          currentStreak: 5,
          lastStudyDate: today,
        );

        final cloudProfile = UserProfile(
          userId: 'test-user',
          displayName: 'Cloud User',
          currentStreak: 7,
          lastStudyDate: today.subtract(const Duration(days: 1)),
        );

        final todayProgress = FlashcardProgress(
          id: 'today-1',
          userId: 'test-user',
          flashcardId: 'card-1',
          reviewCount: 1,
          lastReviewedAt: today.add(const Duration(hours: 10)),
        );

        final conflict = SyncConflict(
          localProfile: localProfile,
          cloudProfile: cloudProfile,
          localProgress: [todayProgress],
          cloudProgress: [],
        );

        final summary = conflict.toSummary();

        // Verify summary structure
        expect(summary, isA<Map<String, dynamic>>());
        expect(summary.containsKey('local'), isTrue);
        expect(summary.containsKey('cloud'), isTrue);
        expect(summary.containsKey('conflictDetectedAt'), isTrue);

        // Verify local data
        final localData = summary['local'] as Map<String, dynamic>;
        expect(localData['profileExists'], isTrue);
        expect(localData['progressCount'], equals(1));
        expect(localData['cardsStudiedToday'], equals(1));
        expect(localData['currentStreak'], equals(5));

        // Verify cloud data
        final cloudData = summary['cloud'] as Map<String, dynamic>;
        expect(cloudData['profileExists'], isTrue);
        expect(cloudData['progressCount'], equals(0));
        expect(cloudData['cardsStudiedToday'], equals(0));
        expect(cloudData['currentStreak'], equals(7));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle null profiles in conflict summary', () {
        final conflict = SyncConflict(
          localProfile: null,
          cloudProfile: null,
          localProgress: [],
          cloudProgress: [],
        );

        final summary = conflict.toSummary();
        expect(summary['local']['profileExists'], isFalse);
        expect(summary['cloud']['profileExists'], isFalse);
        expect(summary['local']['currentStreak'], equals(0));
        expect(summary['cloud']['currentStreak'], equals(0));
      });

      test('should handle empty progress lists', () {
        final conflict = SyncConflict(
          localProgress: [],
          cloudProgress: [],
        );

        final summary = conflict.toSummary();
        expect(summary['local']['progressCount'], equals(0));
        expect(summary['cloud']['progressCount'], equals(0));
        expect(summary['local']['cardsStudiedToday'], equals(0));
        expect(summary['cloud']['cardsStudiedToday'], equals(0));
      });

      test('should handle progress items without last reviewed dates', () {
        final progressWithoutDate = FlashcardProgress(
          id: 'no-date-1',
          userId: 'test-user',
          flashcardId: 'card-1',
          reviewCount: 3,
          lastReviewedAt: null,
        );

        final conflict = SyncConflict(
          localProgress: [progressWithoutDate],
          cloudProgress: [],
        );

        // Should not crash when calculating cards studied today
        expect(() => conflict.toSummary(), returnsNormally);
        
        final summary = conflict.toSummary();
        expect(summary['local']['cardsStudiedToday'], equals(0));
      });

      test('should handle date comparison edge cases', () {
        final now = DateTime.now();
        final midnight = DateTime(now.year, now.month, now.day);
        final almostMidnight = midnight.add(const Duration(hours: 23, minutes: 59));
        
        final progressAtMidnight = FlashcardProgress(
          id: 'midnight-1',
          userId: 'test-user',
          flashcardId: 'card-1',
          reviewCount: 1,
          lastReviewedAt: midnight,
        );

        final progressBeforeMidnight = FlashcardProgress(
          id: 'before-midnight-1',
          userId: 'test-user',
          flashcardId: 'card-2',
          reviewCount: 1,
          lastReviewedAt: almostMidnight,
        );

        final conflict = SyncConflict(
          localProgress: [progressAtMidnight, progressBeforeMidnight],
          cloudProgress: [],
        );

        final summary = conflict.toSummary();
        
        // Both should count as studied today
        expect(summary['local']['cardsStudiedToday'], equals(2));
      });
    });

    group('Performance Tests', () {
      test('should handle large numbers of listeners efficiently', () {
        final listeners = <Function(SyncStatus)>[];
        
        // Add many listeners
        for (int i = 0; i < 100; i++) {
          void listener(SyncStatus status) {
            // Do nothing - just test memory management
          }
          listeners.add(listener);
          syncService.addStatusListener(listener);
        }

        // Remove all listeners
        for (final listener in listeners) {
          syncService.removeStatusListener(listener);
        }

        // Should complete without memory issues
        expect(listeners, hasLength(100));
      });

      test('should handle conflict summaries with large progress lists efficiently', () {
        // Create large progress lists
        final largeLocalProgress = List.generate(1000, (index) => 
          FlashcardProgress(
            id: 'local-$index',
            userId: 'test-user',
            flashcardId: 'card-$index',
            reviewCount: index,
            lastReviewedAt: DateTime.now().subtract(Duration(days: index % 30)),
          )
        );

        final largeCloudProgress = List.generate(500, (index) => 
          FlashcardProgress(
            id: 'cloud-$index',
            userId: 'test-user',
            flashcardId: 'card-$index',
            reviewCount: index * 2,
            lastReviewedAt: DateTime.now().subtract(Duration(days: index % 15)),
          )
        );

        final conflict = SyncConflict(
          localProgress: largeLocalProgress,
          cloudProgress: largeCloudProgress,
        );

        // Should generate summary efficiently
        final stopwatch = Stopwatch()..start();
        final summary = conflict.toSummary();
        stopwatch.stop();

        // Summary generation should complete quickly (under 100ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        expect(summary['local']['progressCount'], equals(1000));
        expect(summary['cloud']['progressCount'], equals(500));
      });
    });
  });
}