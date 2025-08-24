import 'package:flutter_test/flutter_test.dart';
import 'package:flashcode/services/sync_service_v2.dart';
import 'package:flashcode/models/user_progress.dart';

void main() {
  group('SyncServiceV2 Tests', () {
    late SyncServiceV2 syncService;

    setUp(() {
      syncService = SyncServiceV2.instance;
    });

    group('Initialization', () {
      test('should be a singleton', () {
        final instance1 = SyncServiceV2.instance;
        final instance2 = SyncServiceV2.instance;
        expect(instance1, same(instance2));
      });

      test('should initialize with correct initial status', () {
        expect(syncService.status, equals(SyncStatus.idle));
        expect(syncService.currentConflict, isNull);
      });
    });

    group('Status Management', () {
      test('should add and remove status listeners correctly', () {
        var callCount = 0;
        void testListener(SyncStatus status) {
          callCount++;
        }

        // Add listener
        syncService.addStatusListener(testListener);
        
        // Remove listener
        syncService.removeStatusListener(testListener);

        // Verify listener management doesn't throw
        expect(() => syncService.addStatusListener(testListener), returnsNormally);
        expect(() => syncService.removeStatusListener(testListener), returnsNormally);
      });

      test('should add and remove conflict listeners correctly', () {
        var callCount = 0;
        void testListener(SyncConflict conflict) {
          callCount++;
        }

        // Add listener
        syncService.addConflictListener(testListener);
        
        // Remove listener
        syncService.removeConflictListener(testListener);

        // Verify listener management doesn't throw
        expect(() => syncService.addConflictListener(testListener), returnsNormally);
        expect(() => syncService.removeConflictListener(testListener), returnsNormally);
      });
    });

    group('Sync Status Enum', () {
      test('should have all expected status values', () {
        expect(SyncStatus.idle, isA<SyncStatus>());
        expect(SyncStatus.syncing, isA<SyncStatus>());
        expect(SyncStatus.conflict, isA<SyncStatus>());
        expect(SyncStatus.success, isA<SyncStatus>());
        expect(SyncStatus.error, isA<SyncStatus>());
      });
    });

    group('Conflict Resolution Enum', () {
      test('should have all expected resolution strategies', () {
        expect(ConflictResolution.useLocal, isA<ConflictResolution>());
        expect(ConflictResolution.useCloud, isA<ConflictResolution>());
        expect(ConflictResolution.smartMerge, isA<ConflictResolution>());
      });
    });

    group('SyncConflict Model', () {
      test('should create conflict with summary data', () {
        final now = DateTime.now();
        final localProgress = [
          FlashcardProgress(
            id: 'local-1',
            userId: 'test-user',
            flashcardId: 'card-1',
            reviewCount: 3,
            lastReviewedAt: now,
          ),
        ];

        final cloudProgress = [
          FlashcardProgress(
            id: 'cloud-1',
            userId: 'test-user',
            flashcardId: 'card-1',
            reviewCount: 5,
            lastReviewedAt: now.subtract(const Duration(days: 1)),
          ),
        ];

        final conflict = SyncConflict(
          localProgress: localProgress,
          cloudProgress: cloudProgress,
        );

        expect(conflict.localProgress, equals(localProgress));
        expect(conflict.cloudProgress, equals(cloudProgress));
        expect(conflict.conflictDetectedAt, isA<DateTime>());

        // Test summary generation
        final summary = conflict.toSummary();
        expect(summary, isA<Map<String, dynamic>>());
        expect(summary['local'], isA<Map<String, dynamic>>());
        expect(summary['cloud'], isA<Map<String, dynamic>>());
        expect(summary['conflictDetectedAt'], isA<String>());
      });

      test('should calculate cards studied today correctly', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));

        final progressToday = FlashcardProgress(
          id: 'today-1',
          userId: 'test-user',
          flashcardId: 'card-1',
          reviewCount: 1,
          lastReviewedAt: today.add(const Duration(hours: 10)),
        );

        final progressYesterday = FlashcardProgress(
          id: 'yesterday-1',
          userId: 'test-user',
          flashcardId: 'card-2',
          reviewCount: 1,
          lastReviewedAt: yesterday,
        );

        final conflict = SyncConflict(
          localProgress: [progressToday],
          cloudProgress: [progressYesterday],
        );

        final summary = conflict.toSummary();
        
        // Local should have 1 card studied today
        expect(summary['local']['cardsStudiedToday'], equals(1));
        
        // Cloud should have 0 cards studied today
        expect(summary['cloud']['cardsStudiedToday'], equals(0));
      });
    });

    group('Error Handling', () {
      test('should throw exception when resolving non-existent conflict', () async {
        // Ensure no current conflict
        expect(syncService.currentConflict, isNull);
        
        // Should throw when trying to resolve non-existent conflict
        expect(
          () => syncService.resolveConflict('test-user', ConflictResolution.useLocal),
          throwsException,
        );
      });
    });

    group('Sync Availability', () {
      test('should check sync availability without device initialization', () {
        // Test sync availability getter directly
        // Note: In a real app, init() would be called with proper Flutter binding
        // For unit tests, we test the getter logic
        expect(syncService.isSyncAvailable, isFalse); // No device ID yet
      });
    });

    group('Integration Test Scenarios', () {
      test('should handle empty progress lists without errors', () {
        final conflict = SyncConflict(
          localProgress: [],
          cloudProgress: [],
        );

        expect(conflict.localProgress.isEmpty, isTrue);
        expect(conflict.cloudProgress.isEmpty, isTrue);
        
        // Should generate summary without errors
        final summary = conflict.toSummary();
        expect(summary['local']['progressCount'], equals(0));
        expect(summary['cloud']['progressCount'], equals(0));
      });

      test('should handle mixed null and valid data', () {
        final validProgress = FlashcardProgress(
          id: 'valid-1',
          userId: 'test-user',
          flashcardId: 'card-1',
          reviewCount: 1,
          lastReviewedAt: null, // Null review date
        );

        final conflict = SyncConflict(
          localProfile: null, // Null profile
          cloudProfile: UserProfile(userId: 'test-user'),
          localProgress: [validProgress],
          cloudProgress: [],
        );

        expect(conflict.localProfile, isNull);
        expect(conflict.cloudProfile, isNotNull);
        
        final summary = conflict.toSummary();
        expect(summary['local']['profileExists'], isFalse);
        expect(summary['cloud']['profileExists'], isTrue);
      });
    });

    group('Performance and Edge Cases', () {
      test('should handle large progress lists efficiently', () {
        // Create a large list of progress items
        final largeProgressList = List.generate(1000, (index) => 
          FlashcardProgress(
            id: 'progress-$index',
            userId: 'test-user',
            flashcardId: 'card-$index',
            reviewCount: index % 10,
            lastReviewedAt: DateTime.now().subtract(Duration(days: index % 30)),
          )
        );

        final conflict = SyncConflict(
          localProgress: largeProgressList,
          cloudProgress: largeProgressList.take(500).toList(),
        );

        // Should handle large lists without performance issues
        final summary = conflict.toSummary();
        expect(summary['local']['progressCount'], equals(1000));
        expect(summary['cloud']['progressCount'], equals(500));
      });

      test('should handle date edge cases correctly', () {
        final farFuture = DateTime(2030, 12, 31);
        final farPast = DateTime(1990, 1, 1);

        final progressFuture = FlashcardProgress(
          id: 'future-1',
          userId: 'test-user',
          flashcardId: 'card-1',
          reviewCount: 1,
          lastReviewedAt: farFuture,
        );

        final progressPast = FlashcardProgress(
          id: 'past-1',
          userId: 'test-user',
          flashcardId: 'card-2',
          reviewCount: 1,
          lastReviewedAt: farPast,
        );

        final conflict = SyncConflict(
          localProgress: [progressFuture],
          cloudProgress: [progressPast],
        );

        // Should handle extreme dates without errors
        expect(() => conflict.toSummary(), returnsNormally);
      });
    });
  });
}