import 'package:flutter_test/flutter_test.dart';
import '../../lib/utils/spaced_repetition.dart';
import '../../lib/models/flashcard.dart';

void main() {
  group('SpacedRepetition', () {
    late Flashcard testCard;

    setUp(() {
      testCard = Flashcard(
        id: 'test-1',
        title: 'Two Sum',
        question: 'Given an array of integers nums and an integer target, return indices of the two numbers such that they add up to target.',
        hint: 'Use a hash map to store numbers and their indices',
        solutions: {
          'optimal': CodeSolution(
            code: 'def twoSum(nums, target): ...',
            timeComplexity: 'O(n)',
            spaceComplexity: 'O(n)',
            keyPoints: ['Hash map', 'Single pass'],
            approach: 'optimized',
          ),
        },
        dataStructureCategory: 'Hash Table',
        algorithmPattern: 'Two Pointers',
        predefinedDifficulty: 'Easy',
        personalDifficulty: 2,
        leetcodeNumber: '1',
        nextReview: DateTime.now().add(Duration(days: 1)),
        interval: 1,
        easeFactor: 2.5,
        reviewCount: 0,
        createdAt: DateTime.now(),
        lastReviewedAt: null,
        tags: ['array', 'hash-table'],
        companies: ['Google', 'Amazon'],
      );
    });

    group('calculateNextReview', () {
      test('should handle "Again" rating (0) correctly', () {
        final result = SpacedRepetition.calculateNextReview(testCard, 0);

        expect(result.interval, equals(1)); // Reset to 1 day
        expect(result.reviewCount, equals(1));
        expect(result.easeFactor, lessThan(testCard.easeFactor)); // Should decrease
        expect(result.personalDifficulty, equals(1)); // Should decrease difficulty
        expect(result.lastReviewedAt, isNotNull);
      });

      test('should handle "Hard" rating (1) correctly', () {
        final result = SpacedRepetition.calculateNextReview(testCard, 1);

        expect(result.interval, equals(1)); // Reset to 1 day for rating < 2
        expect(result.reviewCount, equals(1));
        expect(result.easeFactor, lessThan(testCard.easeFactor)); // Should decrease
        expect(result.personalDifficulty, equals(testCard.personalDifficulty)); // Should stay same
        expect(result.lastReviewedAt, isNotNull);
      });

      test('should handle "Good" rating (2) correctly', () {
        final result = SpacedRepetition.calculateNextReview(testCard, 2);

        expect(result.interval, equals(1)); // First review should be 1 day
        expect(result.reviewCount, equals(1));
        expect(result.easeFactor, greaterThanOrEqualTo(1.3)); // Should not go below 1.3
        expect(result.personalDifficulty, equals(testCard.personalDifficulty)); // Should stay same
        expect(result.lastReviewedAt, isNotNull);
      });

      test('should handle "Easy" rating (3) correctly', () {
        final result = SpacedRepetition.calculateNextReview(testCard, 3);

        expect(result.interval, equals(1)); // First review should be 1 day
        expect(result.reviewCount, equals(1));
        expect(result.easeFactor, greaterThanOrEqualTo(testCard.easeFactor)); // Should increase or stay same
        expect(result.personalDifficulty, equals(3)); // Should increase difficulty
        expect(result.lastReviewedAt, isNotNull);
      });

      test('should handle second review with good rating', () {
        // Simulate first review
        final afterFirst = SpacedRepetition.calculateNextReview(testCard, 2);
        
        // Second review
        final afterSecond = SpacedRepetition.calculateNextReview(afterFirst, 2);

        expect(afterSecond.interval, equals(6)); // Second review should be 6 days
        expect(afterSecond.reviewCount, equals(2));
      });

      test('should handle third and subsequent reviews with good rating', () {
        // Simulate first two reviews
        var card = SpacedRepetition.calculateNextReview(testCard, 2);
        card = SpacedRepetition.calculateNextReview(card, 2);
        
        // Third review
        final afterThird = SpacedRepetition.calculateNextReview(card, 2);

        expect(afterThird.interval, greaterThan(6)); // Should use ease factor calculation
        expect(afterThird.reviewCount, equals(3));
        expect(afterThird.interval, equals((6 * afterThird.easeFactor).round()));
      });

      test('should maintain minimum ease factor of 1.3', () {
        // Start with a card that has multiple failed reviews
        var card = testCard.copyWith(easeFactor: 1.4);
        
        // Multiple "Again" ratings should not drop ease factor below 1.3
        for (int i = 0; i < 10; i++) {
          card = SpacedRepetition.calculateNextReview(card, 0);
        }

        expect(card.easeFactor, greaterThanOrEqualTo(1.3));
      });

      test('should reset interval on failed review', () {
        // Start with a card that has a long interval
        var card = testCard.copyWith(interval: 30, reviewCount: 5);
        
        // Failed review should reset interval
        final result = SpacedRepetition.calculateNextReview(card, 1);

        expect(result.interval, equals(1));
      });

      test('should clamp personal difficulty between 1 and 4', () {
        // Test lower bound
        var lowCard = testCard.copyWith(personalDifficulty: 1);
        var result = SpacedRepetition.calculateNextReview(lowCard, 0);
        expect(result.personalDifficulty, equals(1));

        // Test upper bound
        var highCard = testCard.copyWith(personalDifficulty: 4);
        result = SpacedRepetition.calculateNextReview(highCard, 3);
        expect(result.personalDifficulty, equals(4));
      });
    });

    group('getRatingDescription', () {
      test('should return correct descriptions for all ratings', () {
        expect(SpacedRepetition.getRatingDescription(0), contains('Again'));
        expect(SpacedRepetition.getRatingDescription(1), contains('Hard'));
        expect(SpacedRepetition.getRatingDescription(2), contains('Good'));
        expect(SpacedRepetition.getRatingDescription(3), contains('Easy'));
        expect(SpacedRepetition.getRatingDescription(4), isEmpty);
        expect(SpacedRepetition.getRatingDescription(-1), isEmpty);
      });
    });

    group('getIntervalDescription', () {
      test('should return correct descriptions for various intervals', () {
        expect(SpacedRepetition.getIntervalDescription(0), equals('Today'));
        expect(SpacedRepetition.getIntervalDescription(1), equals('Tomorrow'));
        expect(SpacedRepetition.getIntervalDescription(3), equals('In 3 days'));
        expect(SpacedRepetition.getIntervalDescription(7), equals('In 1 week'));
        expect(SpacedRepetition.getIntervalDescription(14), equals('In 2 weeks'));
        expect(SpacedRepetition.getIntervalDescription(30), equals('In 1 month'));
        expect(SpacedRepetition.getIntervalDescription(60), equals('In 2 months'));
        expect(SpacedRepetition.getIntervalDescription(365), equals('In 1 year'));
        expect(SpacedRepetition.getIntervalDescription(730), equals('In 2 years'));
      });
    });

    group('calculateRetention', () {
      test('should return 0 for empty ratings', () {
        expect(SpacedRepetition.calculateRetention([]), equals(0));
      });

      test('should calculate retention percentage correctly', () {
        expect(SpacedRepetition.calculateRetention([2, 3, 2, 1, 3]), equals(80.0));
        expect(SpacedRepetition.calculateRetention([0, 1, 0, 1]), equals(0.0));
        expect(SpacedRepetition.calculateRetention([2, 3, 3, 2]), equals(100.0));
        expect(SpacedRepetition.calculateRetention([1, 2, 0, 3]), equals(50.0));
      });
    });

    group('getMasteryLevel', () {
      test('should return "New" for unreviewed cards', () {
        final newCard = testCard.copyWith(reviewCount: 0);
        expect(SpacedRepetition.getMasteryLevel(newCard), equals('New'));
      });

      test('should return "Learning" for cards with few reviews', () {
        final learningCard = testCard.copyWith(reviewCount: 2);
        expect(SpacedRepetition.getMasteryLevel(learningCard), equals('Learning'));
      });

      test('should return "Difficult" for cards with low ease factor', () {
        final difficultCard = testCard.copyWith(reviewCount: 5, easeFactor: 1.8);
        expect(SpacedRepetition.getMasteryLevel(difficultCard), equals('Difficult'));
      });

      test('should return "Familiar" for cards with moderate ease factor', () {
        final familiarCard = testCard.copyWith(reviewCount: 5, easeFactor: 2.2);
        expect(SpacedRepetition.getMasteryLevel(familiarCard), equals('Familiar'));
      });

      test('should return "Mastered" for cards with high ease factor', () {
        final masteredCard = testCard.copyWith(reviewCount: 10, easeFactor: 2.8);
        expect(SpacedRepetition.getMasteryLevel(masteredCard), equals('Mastered'));
      });
    });

    group('getMasteryColor', () {
      test('should return correct colors for all mastery levels', () {
        expect(SpacedRepetition.getMasteryColor('New'), equals(0xFF9E9E9E));
        expect(SpacedRepetition.getMasteryColor('Learning'), equals(0xFF2196F3));
        expect(SpacedRepetition.getMasteryColor('Difficult'), equals(0xFFFF9800));
        expect(SpacedRepetition.getMasteryColor('Familiar'), equals(0xFF4CAF50));
        expect(SpacedRepetition.getMasteryColor('Mastered'), equals(0xFF9C27B0));
        expect(SpacedRepetition.getMasteryColor('Unknown'), equals(0xFF9E9E9E));
      });
    });

    group('SM-2 Algorithm Validation', () {
      test('should follow SM-2 algorithm principles', () {
        var card = testCard;

        // First review with good rating
        card = SpacedRepetition.calculateNextReview(card, 2);
        expect(card.interval, equals(1));
        expect(card.reviewCount, equals(1));

        // Second review with good rating
        card = SpacedRepetition.calculateNextReview(card, 2);
        expect(card.interval, equals(6));
        expect(card.reviewCount, equals(2));

        // Third review with good rating should use ease factor
        final beforeEaseFactor = card.easeFactor;
        card = SpacedRepetition.calculateNextReview(card, 2);
        expect(card.interval, equals((6 * beforeEaseFactor).round()));
        expect(card.reviewCount, equals(3));
      });

      test('should handle multiple sequential reviews correctly', () {
        var card = testCard;
        final ratings = [2, 2, 3, 2, 3, 1, 2, 3];
        final intervals = <int>[];

        for (final rating in ratings) {
          card = SpacedRepetition.calculateNextReview(card, rating);
          intervals.add(card.interval);
        }

        // Verify intervals follow expected pattern
        expect(intervals[0], equals(1)); // First review
        expect(intervals[1], equals(6)); // Second review
        expect(intervals[2], greaterThan(6)); // Third review should use ease factor
        
        // After failed review (rating 1), interval should reset
        expect(intervals[5], equals(1));
      });

      test('should handle edge cases in ease factor calculation', () {
        // Test with very low ease factor
        var lowEaseCard = testCard.copyWith(easeFactor: 1.3);
        var result = SpacedRepetition.calculateNextReview(lowEaseCard, 0);
        expect(result.easeFactor, equals(1.3)); // Should not go below 1.3

        // Test with very high ease factor
        var highEaseCard = testCard.copyWith(easeFactor: 4.0);
        result = SpacedRepetition.calculateNextReview(highEaseCard, 3);
        expect(result.easeFactor, greaterThan(4.0)); // Should increase
      });
    });

    group('Integration Tests', () {
      test('should handle complete study session workflow', () {
        // Create multiple cards with different states
        final cards = [
          testCard.copyWith(id: 'card-1', reviewCount: 0),
          testCard.copyWith(id: 'card-2', reviewCount: 1, interval: 1),
          testCard.copyWith(id: 'card-3', reviewCount: 3, interval: 15, easeFactor: 2.8),
        ];

        // Simulate study session with mixed ratings
        final studiedCards = cards.map((card) {
          // Simulate different performance levels
          final rating = card.id == 'card-1' ? 2 : 
                        card.id == 'card-2' ? 3 : 1;
          return SpacedRepetition.calculateNextReview(card, rating);
        }).toList();

        // Verify all cards were updated
        for (final card in studiedCards) {
          expect(card.lastReviewedAt, isNotNull);
          expect(card.reviewCount, greaterThan(0));
          expect(card.nextReview, isNotNull);
        }

        // Verify mastery levels are assigned
        for (final card in studiedCards) {
          final mastery = SpacedRepetition.getMasteryLevel(card);
          expect(['New', 'Learning', 'Difficult', 'Familiar', 'Mastered'], contains(mastery));
        }
      });

      test('should maintain data consistency across multiple reviews', () {
        var card = testCard;
        final originalId = card.id;
        final originalTitle = card.title;

        // Perform multiple reviews
        for (int i = 0; i < 10; i++) {
          final rating = i % 4; // Cycle through all ratings
          card = SpacedRepetition.calculateNextReview(card, rating);
        }

        // Verify core data remains unchanged
        expect(card.id, equals(originalId));
        expect(card.title, equals(originalTitle));
        expect(card.reviewCount, equals(10));
        expect(card.easeFactor, greaterThanOrEqualTo(1.3));
        expect(card.personalDifficulty, inInclusiveRange(1, 4));
      });
    });
  });
}