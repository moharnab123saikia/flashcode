import '../models/flashcard.dart';

class SpacedRepetition {
  // SM-2 Algorithm implementation
  static Flashcard calculateNextReview(Flashcard card, int rating) {
    // Rating: 0 = Again, 1 = Hard, 2 = Good, 3 = Easy
    
    double easeFactor = card.easeFactor;
    int interval = card.interval;
    int reviewCount = card.reviewCount + 1;
    
    // Calculate new ease factor
    easeFactor = easeFactor + (0.1 - (3 - rating) * (0.08 + (3 - rating) * 0.02));
    easeFactor = easeFactor < 1.3 ? 1.3 : easeFactor;
    
    // Calculate new interval
    if (rating < 2) {
      // Failed review - reset interval
      interval = 1;
    } else {
      if (reviewCount == 1) {
        interval = 1;
      } else if (reviewCount == 2) {
        interval = 6;
      } else {
        interval = (interval * easeFactor).round();
      }
    }
    
    // Calculate next review date
    final nextReview = DateTime.now().add(Duration(days: interval));
    
    // Update personal difficulty based on performance
    int personalDifficulty = card.personalDifficulty;
    if (rating == 0) {
      personalDifficulty = (personalDifficulty - 1).clamp(1, 4);
    } else if (rating == 3) {
      personalDifficulty = (personalDifficulty + 1).clamp(1, 4);
    }
    
    return card.copyWith(
      easeFactor: easeFactor,
      interval: interval,
      reviewCount: reviewCount,
      nextReview: nextReview,
      lastReviewedAt: DateTime.now(),
      personalDifficulty: personalDifficulty,
    );
  }
  
  // Get review difficulty description
  static String getRatingDescription(int rating) {
    switch (rating) {
      case 0:
        return 'Again - I couldn\'t solve it';
      case 1:
        return 'Hard - I struggled but solved it';
      case 2:
        return 'Good - I solved it with moderate effort';
      case 3:
        return 'Easy - I solved it quickly';
      default:
        return '';
    }
  }
  
  // Get interval description
  static String getIntervalDescription(int days) {
    if (days == 0) {
      return 'Today';
    } else if (days == 1) {
      return 'Tomorrow';
    } else if (days < 7) {
      return 'In $days days';
    } else if (days < 30) {
      final weeks = (days / 7).round();
      return weeks == 1 ? 'In 1 week' : 'In $weeks weeks';
    } else if (days < 365) {
      final months = (days / 30).round();
      return months == 1 ? 'In 1 month' : 'In $months months';
    } else {
      final years = (days / 365).round();
      return years == 1 ? 'In 1 year' : 'In $years years';
    }
  }
  
  // Calculate retention percentage
  static double calculateRetention(List<int> recentRatings) {
    if (recentRatings.isEmpty) return 0;
    
    final successfulReviews = recentRatings.where((r) => r >= 2).length;
    return (successfulReviews / recentRatings.length) * 100;
  }
  
  // Get mastery level based on review count and ease factor
  static String getMasteryLevel(Flashcard card) {
    if (card.reviewCount == 0) {
      return 'New';
    } else if (card.reviewCount < 3) {
      return 'Learning';
    } else if (card.easeFactor < 2.0) {
      return 'Difficult';
    } else if (card.easeFactor < 2.5) {
      return 'Familiar';
    } else {
      return 'Mastered';
    }
  }
  
  // Get color for mastery level
  static int getMasteryColor(String masteryLevel) {
    switch (masteryLevel) {
      case 'New':
        return 0xFF9E9E9E; // Grey
      case 'Learning':
        return 0xFF2196F3; // Blue
      case 'Difficult':
        return 0xFFFF9800; // Orange
      case 'Familiar':
        return 0xFF4CAF50; // Green
      case 'Mastered':
        return 0xFF9C27B0; // Purple
      default:
        return 0xFF9E9E9E;
    }
  }
}
