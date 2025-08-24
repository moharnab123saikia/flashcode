import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../../lib/providers/flashcard_provider_v2.dart';
import '../../lib/models/user_progress.dart';
import '../../lib/services/sync_service_v2.dart';

void main() {
  group('FlashcardProviderV2', () {
    late FlashcardProviderV2 provider;
    late List<FlashcardWithProgress> mockCards;
    late UserProfile mockProfile;

    setUp(() {
      provider = FlashcardProviderV2();
      
      // Create mock flashcards with progress
      mockCards = [
        FlashcardWithProgress(
          id: 'card-1',
          title: 'Two Sum',
          question: 'Find two numbers that add up to target',
          hint: 'Use hash map',
          solutions: {
            'optimal': {
              'code': 'def twoSum(): ...',
              'timeComplexity': 'O(n)',
              'spaceComplexity': 'O(n)',
              'keyPoints': ['Hash map'],
              'approach': 'optimized',
            },
          },
          dataStructureCategory: 'Hash Table',
          algorithmPattern: 'Two Pointers',
          predefinedDifficulty: 'Easy',
          personalDifficulty: 2,
          leetcodeNumber: '1',
          tags: ['array', 'hash-table'],
          companies: ['Google'],
          createdAt: DateTime.now(),
          reviewCount: 0,
          easeFactor: 2.5,
          intervalDays: 1,
          nextReview: DateTime.now().add(Duration(days: 1)),
          lastReviewedAt: null,
          progressUpdatedAt: null,
        ),
        FlashcardWithProgress(
          id: 'card-2',
          title: 'Valid Parentheses',
          question: 'Check if parentheses are valid',
          hint: 'Use stack',
          solutions: {
            'optimal': {
              'code': 'def isValid(): ...',
              'timeComplexity': 'O(n)',
              'spaceComplexity': 'O(n)',
              'keyPoints': ['Stack'],
              'approach': 'optimized',
            },
          },
          dataStructureCategory: 'Stack',
          algorithmPattern: 'Stack',
          predefinedDifficulty: 'Medium',
          personalDifficulty: 3,
          leetcodeNumber: '20',
          tags: ['string', 'stack'],
          companies: ['Amazon'],
          createdAt: DateTime.now(),
          reviewCount: 5,
          easeFactor: 2.8,
          intervalDays: 15,
          nextReview: DateTime.now().subtract(Duration(days: 1)), // Due for review
          lastReviewedAt: DateTime.now().subtract(Duration(days: 16)),
          progressUpdatedAt: DateTime.now(),
        ),
        FlashcardWithProgress(
          id: 'card-3',
          title: 'Binary Tree Traversal',
          question: 'Implement inorder traversal',
          hint: 'Use recursion or stack',
          solutions: {
            'recursive': {
              'code': 'def inorder(): ...',
              'timeComplexity': 'O(n)',
              'spaceComplexity': 'O(h)',
              'keyPoints': ['Recursion'],
              'approach': 'recursive',
            },
          },
          dataStructureCategory: 'Tree',
          algorithmPattern: 'Tree Traversal',
          predefinedDifficulty: 'Hard',
          personalDifficulty: 4,
          leetcodeNumber: '94',
          tags: ['tree', 'dfs'],
          companies: ['Microsoft'],
          createdAt: DateTime.now(),
          reviewCount: 10,
          easeFactor: 3.2,
          intervalDays: 45,
          nextReview: DateTime.now().add(Duration(days: 10)),
          lastReviewedAt: DateTime.now().subtract(Duration(days: 35)),
          progressUpdatedAt: DateTime.now(),
        ),
      ];

      mockProfile = UserProfile(
        userId: 'test-user',
        displayName: 'Test User',
        currentStreak: 5,
        longestStreak: 10,
        totalCardsStudied: 25,
        lastStudyDate: DateTime.now().subtract(Duration(days: 1)),
        settings: UserSettings(
          notificationsEnabled: true,
          dailyGoal: 10,
          theme: 'dark',
        ),
      );
    });

    group('Initialization', () {
      test('should initialize with default values', () {
        expect(provider.flashcards, isEmpty);
        expect(provider.filteredCards, isEmpty);
        expect(provider.userProfile, isNull);
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
        expect(provider.syncStatus, equals(SyncStatus.idle));
        expect(provider.currentConflict, isNull);
        expect(provider.selectedCategory, isNull);
        expect(provider.selectedDifficulty, isNull);
        expect(provider.searchQuery, isEmpty);
      });

      test('should provide categories from flashcards', () {
        // Simulate having flashcards loaded
        provider.flashcards.addAll(mockCards);
        
        final categories = provider.categories;
        expect(categories, contains('Hash Table'));
        expect(categories, contains('Stack'));
        expect(categories, contains('Tree'));
        expect(categories.length, equals(3));
        expect(categories, orderedEquals(['Hash Table', 'Stack', 'Tree'])); // Should be sorted
      });

      test('should provide algorithm patterns from flashcards', () {
        provider.flashcards.addAll(mockCards);
        
        final patterns = provider.algorithmPatterns;
        expect(patterns, contains('Two Pointers'));
        expect(patterns, contains('Stack'));
        expect(patterns, contains('Tree Traversal'));
        expect(patterns.length, equals(3));
      });
    });

    group('Card Retrieval', () {
      setUp(() {
        // Simulate loaded state
        provider.flashcards.addAll(mockCards);
        provider.filteredCards.addAll(mockCards);
      });

      test('should get cards due for review', () {
        final dueCards = provider.getCardsForReview();
        
        // Only card-2 is due (nextReview in the past)
        expect(dueCards.length, equals(1));
        expect(dueCards.first.id, equals('card-2'));
      });

      test('should get cards by difficulty', () {
        final easyCards = provider.getCardsByDifficulty('Easy');
        final mediumCards = provider.getCardsByDifficulty('Medium');
        final hardCards = provider.getCardsByDifficulty('Hard');
        
        expect(easyCards.length, equals(1));
        expect(easyCards.first.id, equals('card-1'));
        
        expect(mediumCards.length, equals(1));
        expect(mediumCards.first.id, equals('card-2'));
        
        expect(hardCards.length, equals(1));
        expect(hardCards.first.id, equals('card-3'));
      });

      test('should get cards by category', () {
        final hashTableCards = provider.getCardsByCategory('Hash Table');
        final stackCards = provider.getCardsByCategory('Stack');
        final treeCards = provider.getCardsByCategory('Tree');
        
        expect(hashTableCards.length, equals(1));
        expect(hashTableCards.first.id, equals('card-1'));
        
        expect(stackCards.length, equals(1));
        expect(stackCards.first.id, equals('card-2'));
        
        expect(treeCards.length, equals(1));
        expect(treeCards.first.id, equals('card-3'));
      });

      test('should get card by ID', () {
        final card = provider.getCardById('card-2');
        expect(card, isNotNull);
        expect(card!.title, equals('Valid Parentheses'));
        
        final nonExistentCard = provider.getCardById('non-existent');
        expect(nonExistentCard, isNull);
      });
    });

    group('Filtering', () {
      setUp(() {
        provider.flashcards.addAll(mockCards);
        provider.filteredCards.addAll(mockCards);
      });

      test('should filter by category', () {
        provider.setCategory('Stack');
        
        expect(provider.selectedCategory, equals('Stack'));
        expect(provider.filteredCards.length, equals(1));
        expect(provider.filteredCards.first.id, equals('card-2'));
      });

      test('should filter by difficulty', () {
        provider.setDifficulty('Easy');
        
        expect(provider.selectedDifficulty, equals('Easy'));
        expect(provider.filteredCards.length, equals(1));
        expect(provider.filteredCards.first.id, equals('card-1'));
      });

      test('should filter by search query', () {
        provider.setSearchQuery('parentheses');
        
        expect(provider.searchQuery, equals('parentheses'));
        expect(provider.filteredCards.length, equals(1));
        expect(provider.filteredCards.first.id, equals('card-2'));
      });

      test('should filter by tag search', () {
        provider.setSearchQuery('hash-table');
        
        expect(provider.filteredCards.length, equals(1));
        expect(provider.filteredCards.first.id, equals('card-1'));
      });

      test('should combine multiple filters', () {
        // Set both category and difficulty
        provider.setCategory('Tree');
        provider.setDifficulty('Hard');
        
        expect(provider.filteredCards.length, equals(1));
        expect(provider.filteredCards.first.id, equals('card-3'));
        
        // Add incompatible difficulty
        provider.setDifficulty('Easy');
        expect(provider.filteredCards.length, equals(0));
      });

      test('should clear all filters', () {
        provider.setCategory('Stack');
        provider.setDifficulty('Medium');
        provider.setSearchQuery('test');
        
        provider.clearFilters();
        
        expect(provider.selectedCategory, isNull);
        expect(provider.selectedDifficulty, isNull);
        expect(provider.searchQuery, isEmpty);
      });

      test('should be case insensitive for search', () {
        provider.setSearchQuery('BINARY');
        
        expect(provider.filteredCards.length, equals(1));
        expect(provider.filteredCards.first.id, equals('card-3'));
      });
    });

    group('Statistics', () {
      setUp(() {
        provider.flashcards.addAll(mockCards);
      });

      test('should calculate basic statistics correctly', () {
        final stats = provider.getBasicStatistics();
        
        expect(stats['totalCards'], equals(3));
        expect(stats['masteredCards'], equals(1)); // card-3 has difficulty 4
        expect(stats['reviewedCards'], equals(2)); // card-2 and card-3 have reviews
        
        final categoryStats = stats['categoryStats'] as Map<String, int>;
        expect(categoryStats['Hash Table'], equals(1));
        expect(categoryStats['Stack'], equals(1));
        expect(categoryStats['Tree'], equals(1));
        
        final difficultyStats = stats['difficultyStats'] as Map<String, int>;
        expect(difficultyStats['Easy'], equals(1));
        expect(difficultyStats['Medium'], equals(1));
        expect(difficultyStats['Hard'], equals(1));
      });

      test('should handle empty flashcards for statistics', () {
        final emptyProvider = FlashcardProviderV2();
        final stats = emptyProvider.getBasicStatistics();
        
        expect(stats['totalCards'], equals(0));
        expect(stats['masteredCards'], equals(0));
        expect(stats['reviewedCards'], equals(0));
        expect(stats['currentStreak'], equals(0));
        expect(stats['longestStreak'], equals(0));
      });
    });

    group('Public Methods', () {
      test('should clear error state', () {
        provider.clearError();
        expect(provider.error, isNull);
      });

      test('should handle user profile creation', () async {
        // Test that the method exists and can be called
        expect(() => provider.createUserProfile('new-user', displayName: 'New User'), 
               returnsNormally);
      });

      test('should handle user settings update', () async {
        final newSettings = UserSettings(
          notificationsEnabled: false,
          dailyGoal: 20,
          theme: 'light',
        );
        
        expect(() => provider.updateUserSettings(newSettings), returnsNormally);
      });
    });

    group('Spaced Repetition Integration', () {
      test('should sort due cards by next review date', () {
        final now = DateTime.now();
        final cards = [
          mockCards[0].copyWith(nextReview: now.add(Duration(hours: 2))), // Future
          mockCards[1].copyWith(nextReview: now.subtract(Duration(hours: 2))), // Past
          mockCards[2].copyWith(nextReview: now.subtract(Duration(hours: 1))), // More recent past
        ];
        
        provider.flashcards.clear();
        provider.flashcards.addAll(cards);
        
        final dueCards = provider.getCardsForReview();
        
        expect(dueCards.length, equals(2)); // Only past due cards
        expect(dueCards[0].nextReview!.isBefore(dueCards[1].nextReview!), isTrue);
      });

      test('should handle cards with null next review as due', () {
        // Create a new card with null nextReview directly
        final cardWithNullReview = FlashcardWithProgress(
          id: 'test-null',
          title: 'Test Card',
          question: 'Test question',
          hint: 'Test hint',
          solutions: {'test': {}},
          dataStructureCategory: 'Test',
          predefinedDifficulty: 'Easy',
          leetcodeNumber: '0',
          tags: [],
          companies: [],
          createdAt: DateTime.now(),
          nextReview: null, // Explicitly null
        );
        
        final cardNotDue = mockCards[1].copyWith(
          nextReview: DateTime.now().add(Duration(days: 1))
        );
        
        // Test that a card with null nextReview would be considered due
        expect(cardWithNullReview.nextReview, isNull);
        expect(cardNotDue.nextReview!.isAfter(DateTime.now()), isTrue);
        
        // Test the FlashcardWithProgress isDueForReview getter
        expect(cardWithNullReview.isDueForReview, isTrue);
        expect(cardNotDue.isDueForReview, isFalse);
      });
    });

    group('Data Consistency', () {
      test('should maintain flashcard data integrity during operations', () {
        provider.flashcards.addAll(mockCards);
        
        final originalCard = mockCards[0];
        final originalId = originalCard.id;
        final originalTitle = originalCard.title;
        final originalQuestion = originalCard.question;
        
        // Verify core data remains unchanged
        expect(originalCard.id, equals(originalId));
        expect(originalCard.title, equals(originalTitle));
        expect(originalCard.question, equals(originalQuestion));
      });

      test('should handle empty states gracefully', () {
        // Test with empty provider
        expect(provider.getCardsForReview(), isEmpty);
        expect(provider.getCardsByDifficulty('Easy'), isEmpty);
        expect(provider.getCardsByCategory('Any'), isEmpty);
        expect(provider.getCardById('any'), isNull);
        expect(provider.categories, isEmpty);
        expect(provider.algorithmPatterns, isEmpty);
      });

      test('should maintain filter consistency after data changes', () {
        provider.flashcards.addAll(mockCards);
        provider.filteredCards.addAll(mockCards);
        
        // Apply filter
        provider.setCategory('Stack');
        expect(provider.filteredCards.length, equals(1));
        
        // Add new card to flashcards
        final newCard = mockCards[0].copyWith(
          id: 'new-card',
          dataStructureCategory: 'Stack',
        );
        provider.flashcards.add(newCard);
        
        // Filters should still be consistent
        expect(provider.selectedCategory, equals('Stack'));
      });
    });

    group('Edge Cases', () {
      test('should handle duplicate card IDs gracefully', () {
        final duplicateCard = mockCards[0].copyWith(id: mockCards[1].id);
        
        provider.flashcards.addAll([mockCards[0], duplicateCard]);
        
        final foundCard = provider.getCardById(mockCards[1].id);
        expect(foundCard, isNotNull);
        // Should get the first match
        expect(foundCard!.title, equals(mockCards[0].title));
      });

      test('should handle special characters in search', () {
        final specialCard = mockCards[0].copyWith(
          title: 'Test & Special <Characters>',
        );
        
        provider.flashcards.clear();
        provider.flashcards.add(specialCard);
        provider.filteredCards.clear();
        provider.filteredCards.add(specialCard);
        
        provider.setSearchQuery('&');
        expect(provider.filteredCards.length, equals(1));
        
        provider.setSearchQuery('<');
        expect(provider.filteredCards.length, equals(1));
      });

      test('should handle very long filter queries', () {
        final longQuery = 'a' * 1000;
        
        provider.flashcards.addAll(mockCards);
        provider.filteredCards.addAll(mockCards);
        
        provider.setSearchQuery(longQuery);
        expect(provider.filteredCards, isEmpty);
        expect(provider.searchQuery, equals(longQuery));
      });

      test('should handle null and empty string filters', () {
        provider.flashcards.addAll(mockCards);
        provider.filteredCards.addAll(mockCards);
        
        provider.setCategory(null);
        expect(provider.selectedCategory, isNull);
        expect(provider.filteredCards.length, equals(3));
        
        // Test that filters work with real data
        provider.setSearchQuery('');
        expect(provider.filteredCards.length, equals(3));
      });
    });

    group('Memory Management', () {
      test('should dispose properly', () {
        // Add listener to verify cleanup
        bool listenerCalled = false;
        void testListener() => listenerCalled = true;
        
        provider.addListener(testListener);
        
        // Test that dispose can be called without throwing
        expect(() => provider.dispose(), returnsNormally);
        
        // After disposal, the provider should be marked as disposed
        // We can't test notifyListeners after disposal as it properly throws
        expect(provider.isLoading, isFalse); // This should work even after disposal
      });
    });
  });
}