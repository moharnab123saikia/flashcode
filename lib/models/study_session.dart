import 'package:json_annotation/json_annotation.dart';

part 'study_session.g.dart';

@JsonSerializable()
class StudySession {
  final String id;
  final String userId;
  final String mode; // 'spaced_repetition', 'sequential', 'category', 'random', 'timed'
  final List<String> targetTags;
  final List<String> targetCategories;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int duration; // in seconds
  final List<String> cardIds;
  final Map<String, SessionCardResult> results; // cardId -> result
  final int totalCards;
  final int completedCards;

  StudySession({
    required this.id,
    required this.userId,
    required this.mode,
    List<String>? targetTags,
    List<String>? targetCategories,
    DateTime? startedAt,
    this.completedAt,
    this.duration = 0,
    required this.cardIds,
    Map<String, SessionCardResult>? results,
    required this.totalCards,
    this.completedCards = 0,
  })  : targetTags = targetTags ?? [],
        targetCategories = targetCategories ?? [],
        startedAt = startedAt ?? DateTime.now(),
        results = results ?? {};

  factory StudySession.fromJson(Map<String, dynamic> json) =>
      _$StudySessionFromJson(json);

  Map<String, dynamic> toJson() => _$StudySessionToJson(this);

  bool get isCompleted => completedAt != null;
  
  double get progressPercentage => 
      totalCards > 0 ? (completedCards / totalCards) * 100 : 0;
}

@JsonSerializable()
class SessionCardResult {
  final String cardId;
  final int rating; // 0: Again, 1: Hard, 2: Good, 3: Easy
  final int timeSpent; // in seconds
  final bool hintUsed;
  final bool solutionViewed;
  final DateTime reviewedAt;

  SessionCardResult({
    required this.cardId,
    required this.rating,
    required this.timeSpent,
    this.hintUsed = false,
    this.solutionViewed = false,
    DateTime? reviewedAt,
  }) : reviewedAt = reviewedAt ?? DateTime.now();

  factory SessionCardResult.fromJson(Map<String, dynamic> json) =>
      _$SessionCardResultFromJson(json);

  Map<String, dynamic> toJson() => _$SessionCardResultToJson(this);
}

enum StudyMode {
  spacedRepetition,
  sequential,
  category,
  random,
  timed,
}

extension StudyModeExtension on StudyMode {
  String get displayName {
    switch (this) {
      case StudyMode.spacedRepetition:
        return 'Spaced Repetition';
      case StudyMode.sequential:
        return 'Sequential Study';
      case StudyMode.category:
        return 'Category Focus';
      case StudyMode.random:
        return 'Random Practice';
      case StudyMode.timed:
        return 'Timed Challenge';
    }
  }

  String get description {
    switch (this) {
      case StudyMode.spacedRepetition:
        return 'Review cards based on spaced repetition algorithm';
      case StudyMode.sequential:
        return 'Study cards in Grind 75 order';
      case StudyMode.category:
        return 'Focus on specific topics';
      case StudyMode.random:
        return 'Mixed difficulty practice';
      case StudyMode.timed:
        return 'Time-pressured practice session';
    }
  }

  String get icon {
    switch (this) {
      case StudyMode.spacedRepetition:
        return '🎯';
      case StudyMode.sequential:
        return '📖';
      case StudyMode.category:
        return '🏷️';
      case StudyMode.random:
        return '🎲';
      case StudyMode.timed:
        return '⏱️';
    }
  }
}
