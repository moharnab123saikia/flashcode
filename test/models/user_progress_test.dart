import 'package:flutter_test/flutter_test.dart';
import 'package:flashcode/models/user_progress.dart';

void main() {
  group('UserProgress Models Tests', () {
    group('UserProfile', () {
      test('should create UserProfile with default values', () {
        final profile = UserProfile(userId: 'test-user');
        
        expect(profile.userId, equals('test-user'));
        expect(profile.displayName, isNull);
        expect(profile.currentStreak, equals(0));
        expect(profile.longestStreak, equals(0));
        expect(profile.totalCardsStudied, equals(0));
        expect(profile.lastStudyDate, isNull);
        expect(profile.settings, isA<UserSettings>());
        expect(profile.createdAt, isA<DateTime>());
        expect(profile.updatedAt, isA<DateTime>());
        expect(profile.lastSyncedAt, isA<DateTime>());
      });

      test('should create UserProfile with custom values', () {
        final customSettings = UserSettings(
          dailyGoal: 25,
          theme: 'dark',
          cloudSyncEnabled: false,
        );
        
        final now = DateTime.now();
        final profile = UserProfile(
          userId: 'test-user',
          displayName: 'Test User',
          currentStreak: 10,
          longestStreak: 25,
          totalCardsStudied: 100,
          lastStudyDate: now,
          settings: customSettings,
        );
        
        expect(profile.displayName, equals('Test User'));
        expect(profile.currentStreak, equals(10));
        expect(profile.longestStreak, equals(25));
        expect(profile.totalCardsStudied, equals(100));
        expect(profile.lastStudyDate, equals(now));
        expect(profile.settings.dailyGoal, equals(25));
        expect(profile.settings.theme, equals('dark'));
        expect(profile.settings.cloudSyncEnabled, isFalse);
      });

      test('should copy UserProfile with modified values', () {
        final original = UserProfile(
          userId: 'test-user',
          displayName: 'Original Name',
          currentStreak: 5,
        );
        
        final copied = original.copyWith(
          displayName: 'New Name',
          currentStreak: 10,
        );
        
        expect(copied.userId, equals('test-user')); // Unchanged
        expect(copied.displayName, equals('New Name')); // Changed
        expect(copied.currentStreak, equals(10)); // Changed
      });

      test('should serialize to/from JSON correctly', () {
        final profile = UserProfile(
          userId: 'test-user',
          displayName: 'Test User',
          currentStreak: 5,
          settings: UserSettings(dailyGoal: 20),
        );
        
        final json = profile.toJson();
        
        // Verify JSON structure
        expect(json, isA<Map<String, dynamic>>());
        expect(json['userId'], equals('test-user'));
        expect(json['displayName'], equals('Test User'));
        expect(json['currentStreak'], equals(5));
        expect(json['settings'], isA<Map<String, dynamic>>());
        
        final fromJson = UserProfile.fromJson(json);
        
        expect(fromJson.userId, equals(profile.userId));
        expect(fromJson.displayName, equals(profile.displayName));
        expect(fromJson.currentStreak, equals(profile.currentStreak));
        expect(fromJson.settings.dailyGoal, equals(profile.settings.dailyGoal));
      });

      test('should calculate category progress correctly', () {
        final profile = UserProfile(userId: 'test-user');
        
        final progressList = [
          FlashcardProgress(
            id: '1',
            userId: 'test-user',
            flashcardId: 'card-1',
            reviewCount: 3,
          ),
          FlashcardProgress(
            id: '2',
            userId: 'test-user',
            flashcardId: 'card-2',
            reviewCount: 0, // Not studied
          ),
          FlashcardProgress(
            id: '3',
            userId: 'test-user',
            flashcardId: 'card-3',
            reviewCount: 5,
          ),
        ];
        
        final categoryProgress = profile.calculateCategoryProgress(progressList);
        
        // Should only count cards with reviewCount > 0
        expect(categoryProgress.length, equals(2));
        expect(categoryProgress.containsKey('card-1'), isTrue);
        expect(categoryProgress.containsKey('card-3'), isTrue);
        expect(categoryProgress.containsKey('card-2'), isFalse);
      });

      test('should calculate category mastery correctly', () {
        final profile = UserProfile(userId: 'test-user');
        
        final progressList = [
          FlashcardProgress(
            id: '1',
            userId: 'test-user',
            flashcardId: 'card-1',
            personalDifficulty: 4, // Mastered
          ),
          FlashcardProgress(
            id: '2',
            userId: 'test-user',
            flashcardId: 'card-2',
            personalDifficulty: 2, // Not mastered
          ),
          FlashcardProgress(
            id: '3',
            userId: 'test-user',
            flashcardId: 'card-3',
            personalDifficulty: 4, // Mastered
          ),
        ];
        
        final categoryMastery = profile.calculateCategoryMastery(progressList);
        
        // Each card is its own category in this simplified test
        expect(categoryMastery['card-1'], equals(1.0)); // 1/1 mastered
        expect(categoryMastery['card-2'], equals(0.0)); // 0/1 mastered
        expect(categoryMastery['card-3'], equals(1.0)); // 1/1 mastered
      });
    });

    group('UserSettings', () {
      test('should create UserSettings with default values', () {
        final settings = UserSettings();
        
        expect(settings.dailyGoal, equals(15));
        expect(settings.sessionDuration, equals(30));
        expect(settings.notificationTime, equals('09:00'));
        expect(settings.notificationsEnabled, isTrue);
        expect(settings.theme, equals('auto'));
        expect(settings.defaultLanguage, equals('python'));
        expect(settings.codeFontSize, equals(14));
        expect(settings.cloudSyncEnabled, isTrue);
        expect(settings.spacedRepetitionAlgorithm, equals('SM-2'));
      });

      test('should create UserSettings with custom values', () {
        final settings = UserSettings(
          dailyGoal: 25,
          sessionDuration: 45,
          notificationTime: '18:00',
          notificationsEnabled: false,
          theme: 'dark',
          defaultLanguage: 'java',
          codeFontSize: 16,
          cloudSyncEnabled: false,
          spacedRepetitionAlgorithm: 'Anki',
        );
        
        expect(settings.dailyGoal, equals(25));
        expect(settings.sessionDuration, equals(45));
        expect(settings.notificationTime, equals('18:00'));
        expect(settings.notificationsEnabled, isFalse);
        expect(settings.theme, equals('dark'));
        expect(settings.defaultLanguage, equals('java'));
        expect(settings.codeFontSize, equals(16));
        expect(settings.cloudSyncEnabled, isFalse);
        expect(settings.spacedRepetitionAlgorithm, equals('Anki'));
      });

      test('should copy UserSettings with modified values', () {
        final original = UserSettings();
        final copied = original.copyWith(
          dailyGoal: 30,
          theme: 'light',
        );
        
        expect(copied.dailyGoal, equals(30)); // Changed
        expect(copied.theme, equals('light')); // Changed
        expect(copied.sessionDuration, equals(30)); // Unchanged
        expect(copied.defaultLanguage, equals('python')); // Unchanged
      });

      test('should serialize to/from JSON correctly', () {
        final settings = UserSettings(
          dailyGoal: 25,
          theme: 'dark',
          cloudSyncEnabled: false,
        );
        
        final json = settings.toJson();
        final fromJson = UserSettings.fromJson(json);
        
        expect(fromJson.dailyGoal, equals(settings.dailyGoal));
        expect(fromJson.theme, equals(settings.theme));
        expect(fromJson.cloudSyncEnabled, equals(settings.cloudSyncEnabled));
      });
    });

    group('FlashcardProgress', () {
      test('should create FlashcardProgress with default values', () {
        final progress = FlashcardProgress(
          id: 'test-id',
          userId: 'test-user',
          flashcardId: 'test-card',
        );
        
        expect(progress.id, equals('test-id'));
        expect(progress.userId, equals('test-user'));
        expect(progress.flashcardId, equals('test-card'));
        expect(progress.personalDifficulty, equals(2));
        expect(progress.reviewCount, equals(0));
        expect(progress.easeFactor, equals(2.5));
        expect(progress.intervalDays, equals(1));
        expect(progress.nextReview, isNull);
        expect(progress.lastReviewedAt, isNull);
        expect(progress.createdAt, isA<DateTime>());
        expect(progress.updatedAt, isA<DateTime>());
      });

      test('should create FlashcardProgress with custom values', () {
        final now = DateTime.now();
        final nextReview = now.add(const Duration(days: 3));
        
        final progress = FlashcardProgress(
          id: 'test-id',
          userId: 'test-user',
          flashcardId: 'test-card',
          personalDifficulty: 4,
          reviewCount: 5,
          easeFactor: 2.8,
          intervalDays: 7,
          nextReview: nextReview,
          lastReviewedAt: now,
        );
        
        expect(progress.personalDifficulty, equals(4));
        expect(progress.reviewCount, equals(5));
        expect(progress.easeFactor, equals(2.8));
        expect(progress.intervalDays, equals(7));
        expect(progress.nextReview, equals(nextReview));
        expect(progress.lastReviewedAt, equals(now));
      });

      test('should check if card is due for review correctly', () {
        final now = DateTime.now();
        
        // Card with no next review date (new card)
        final newCard = FlashcardProgress(
          id: '1',
          userId: 'test-user',
          flashcardId: 'card-1',
          nextReview: null,
        );
        expect(newCard.isDueForReview, isTrue);
        
        // Card due in the past
        final pastDue = FlashcardProgress(
          id: '2',
          userId: 'test-user',
          flashcardId: 'card-2',
          nextReview: now.subtract(const Duration(days: 1)),
        );
        expect(pastDue.isDueForReview, isTrue);
        
        // Card due now
        final dueNow = FlashcardProgress(
          id: '3',
          userId: 'test-user',
          flashcardId: 'card-3',
          nextReview: now,
        );
        expect(dueNow.isDueForReview, isTrue);
        
        // Card due in the future
        final futureDue = FlashcardProgress(
          id: '4',
          userId: 'test-user',
          flashcardId: 'card-4',
          nextReview: now.add(const Duration(days: 1)),
        );
        expect(futureDue.isDueForReview, isFalse);
      });

      test('should check if card has been reviewed correctly', () {
        final noReviews = FlashcardProgress(
          id: '1',
          userId: 'test-user',
          flashcardId: 'card-1',
          reviewCount: 0,
        );
        expect(noReviews.hasBeenReviewed, isFalse);
        
        final hasReviews = FlashcardProgress(
          id: '2',
          userId: 'test-user',
          flashcardId: 'card-2',
          reviewCount: 3,
        );
        expect(hasReviews.hasBeenReviewed, isTrue);
      });

      test('should check if card is mastered correctly', () {
        final notMastered = FlashcardProgress(
          id: '1',
          userId: 'test-user',
          flashcardId: 'card-1',
          personalDifficulty: 3,
        );
        expect(notMastered.isMastered, isFalse);
        
        final mastered = FlashcardProgress(
          id: '2',
          userId: 'test-user',
          flashcardId: 'card-2',
          personalDifficulty: 4,
        );
        expect(mastered.isMastered, isTrue);
      });

      test('should copy FlashcardProgress correctly', () {
        final original = FlashcardProgress(
          id: 'test-id',
          userId: 'test-user',
          flashcardId: 'test-card',
          reviewCount: 3,
        );
        
        final copied = original.copyWith(
          reviewCount: 5,
          personalDifficulty: 4,
        );
        
        expect(copied.id, equals('test-id')); // Unchanged
        expect(copied.reviewCount, equals(5)); // Changed
        expect(copied.personalDifficulty, equals(4)); // Changed
      });

      test('should serialize to/from JSON correctly', () {
        final now = DateTime.now();
        final progress = FlashcardProgress(
          id: 'test-id',
          userId: 'test-user',
          flashcardId: 'test-card',
          personalDifficulty: 3,
          reviewCount: 5,
          lastReviewedAt: now,
        );
        
        final json = progress.toJson();
        final fromJson = FlashcardProgress.fromJson(json);
        
        expect(fromJson.id, equals(progress.id));
        expect(fromJson.userId, equals(progress.userId));
        expect(fromJson.flashcardId, equals(progress.flashcardId));
        expect(fromJson.personalDifficulty, equals(progress.personalDifficulty));
        expect(fromJson.reviewCount, equals(progress.reviewCount));
        expect(fromJson.lastReviewedAt, equals(progress.lastReviewedAt));
      });
    });

    group('SyncMetadata', () {
      test('should create SyncMetadata with default values', () {
        final metadata = SyncMetadata(userId: 'test-user');
        
        expect(metadata.userId, equals('test-user'));
        expect(metadata.lastSyncTimestamp, isA<DateTime>());
        expect(metadata.deviceId, isNull);
        expect(metadata.syncVersion, equals(1));
        expect(metadata.conflictResolutionNeeded, isFalse);
        expect(metadata.createdAt, isA<DateTime>());
        expect(metadata.updatedAt, isA<DateTime>());
      });

      test('should create SyncMetadata with custom values', () {
        final now = DateTime.now();
        final metadata = SyncMetadata(
          userId: 'test-user',
          lastSyncTimestamp: now,
          deviceId: 'device-123',
          syncVersion: 2,
          conflictResolutionNeeded: true,
        );
        
        expect(metadata.lastSyncTimestamp, equals(now));
        expect(metadata.deviceId, equals('device-123'));
        expect(metadata.syncVersion, equals(2));
        expect(metadata.conflictResolutionNeeded, isTrue);
      });

      test('should copy SyncMetadata correctly', () {
        final original = SyncMetadata(
          userId: 'test-user',
          syncVersion: 1,
        );
        
        final copied = original.copyWith(
          syncVersion: 2,
          deviceId: 'new-device',
        );
        
        expect(copied.userId, equals('test-user')); // Unchanged
        expect(copied.syncVersion, equals(2)); // Changed
        expect(copied.deviceId, equals('new-device')); // Changed
      });

      test('should serialize to/from JSON correctly', () {
        final metadata = SyncMetadata(
          userId: 'test-user',
          deviceId: 'device-123',
          syncVersion: 2,
        );
        
        final json = metadata.toJson();
        final fromJson = SyncMetadata.fromJson(json);
        
        expect(fromJson.userId, equals(metadata.userId));
        expect(fromJson.deviceId, equals(metadata.deviceId));
        expect(fromJson.syncVersion, equals(metadata.syncVersion));
      });
    });

    group('FlashcardWithProgress', () {
      test('should create FlashcardWithProgress correctly', () {
        final flashcard = FlashcardWithProgress(
          id: 'card-1',
          title: 'Test Problem',
          question: 'What is this?',
          hint: 'Think about it',
          solutions: {'python': {'code': 'def solution(): pass'}},
          dataStructureCategory: 'Array',
          predefinedDifficulty: 'Easy',
          leetcodeNumber: '1',
          tags: ['array', 'easy'],
          companies: ['Google', 'Facebook'],
          createdAt: DateTime.now(),
        );
        
        expect(flashcard.id, equals('card-1'));
        expect(flashcard.title, equals('Test Problem'));
        expect(flashcard.question, equals('What is this?'));
        expect(flashcard.hint, equals('Think about it'));
        expect(flashcard.dataStructureCategory, equals('Array'));
        expect(flashcard.predefinedDifficulty, equals('Easy'));
        expect(flashcard.leetcodeNumber, equals('1'));
        expect(flashcard.tags, hasLength(2));
        expect(flashcard.companies, hasLength(2));
        expect(flashcard.personalDifficulty, equals(2)); // Default
        expect(flashcard.reviewCount, equals(0)); // Default
      });

      test('should check progress status correctly', () {
        final reviewed = FlashcardWithProgress(
          id: 'card-1',
          title: 'Test',
          question: 'Test',
          hint: 'Test',
          solutions: {},
          dataStructureCategory: 'Array',
          predefinedDifficulty: 'Easy',
          leetcodeNumber: '1',
          tags: [],
          companies: [],
          createdAt: DateTime.now(),
          reviewCount: 3,
          personalDifficulty: 4,
        );
        
        expect(reviewed.hasBeenReviewed, isTrue);
        expect(reviewed.isMastered, isTrue);
        
        final newCard = FlashcardWithProgress(
          id: 'card-2',
          title: 'Test',
          question: 'Test',
          hint: 'Test',
          solutions: {},
          dataStructureCategory: 'Array',
          predefinedDifficulty: 'Easy',
          leetcodeNumber: '2',
          tags: [],
          companies: [],
          createdAt: DateTime.now(),
        );
        
        expect(newCard.hasBeenReviewed, isFalse);
        expect(newCard.isMastered, isFalse);
      });

      test('should convert to FlashcardProgress correctly', () {
        final flashcard = FlashcardWithProgress(
          id: 'card-1',
          title: 'Test',
          question: 'Test',
          hint: 'Test',
          solutions: {},
          dataStructureCategory: 'Array',
          predefinedDifficulty: 'Easy',
          leetcodeNumber: '1',
          tags: [],
          companies: [],
          createdAt: DateTime.now(),
          userId: 'test-user',
          personalDifficulty: 3,
          reviewCount: 5,
        );
        
        final progress = flashcard.toProgress();
        
        expect(progress.userId, equals('test-user'));
        expect(progress.flashcardId, equals('card-1'));
        expect(progress.personalDifficulty, equals(3));
        expect(progress.reviewCount, equals(5));
      });
    });
  });
}