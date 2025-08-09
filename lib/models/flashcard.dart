import 'package:json_annotation/json_annotation.dart';

part 'flashcard.g.dart';

@JsonSerializable()
class Flashcard {
  final String id;
  final String title;
  final String question;
  final String hint;
  final Map<String, CodeSolution> solutions;
  final String dataStructureCategory;
  final String? algorithmPattern;
  final String predefinedDifficulty; // Easy/Medium/Hard
  final int personalDifficulty; // 1-4 for spaced repetition
  final String leetcodeNumber;
  final DateTime? nextReview;
  final int interval; // days
  final double easeFactor;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime? lastReviewedAt;
  final List<String> tags;
  final List<String> companies;

  Flashcard({
    required this.id,
    required this.title,
    required this.question,
    required this.hint,
    required this.solutions,
    required this.dataStructureCategory,
    this.algorithmPattern,
    required this.predefinedDifficulty,
    this.personalDifficulty = 2,
    required this.leetcodeNumber,
    this.nextReview,
    this.interval = 1,
    this.easeFactor = 2.5,
    this.reviewCount = 0,
    DateTime? createdAt,
    this.lastReviewedAt,
    List<String>? tags,
    List<String>? companies,
  })  : createdAt = createdAt ?? DateTime.now(),
        tags = tags ?? [],
        companies = companies ?? [];

  factory Flashcard.fromJson(Map<String, dynamic> json) =>
      _$FlashcardFromJson(json);

  Map<String, dynamic> toJson() => _$FlashcardToJson(this);

  Flashcard copyWith({
    String? id,
    String? title,
    String? question,
    String? hint,
    Map<String, CodeSolution>? solutions,
    String? dataStructureCategory,
    String? algorithmPattern,
    String? predefinedDifficulty,
    int? personalDifficulty,
    String? leetcodeNumber,
    DateTime? nextReview,
    int? interval,
    double? easeFactor,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? lastReviewedAt,
    List<String>? tags,
    List<String>? companies,
  }) {
    return Flashcard(
      id: id ?? this.id,
      title: title ?? this.title,
      question: question ?? this.question,
      hint: hint ?? this.hint,
      solutions: solutions ?? this.solutions,
      dataStructureCategory:
          dataStructureCategory ?? this.dataStructureCategory,
      algorithmPattern: algorithmPattern ?? this.algorithmPattern,
      predefinedDifficulty: predefinedDifficulty ?? this.predefinedDifficulty,
      personalDifficulty: personalDifficulty ?? this.personalDifficulty,
      leetcodeNumber: leetcodeNumber ?? this.leetcodeNumber,
      nextReview: nextReview ?? this.nextReview,
      interval: interval ?? this.interval,
      easeFactor: easeFactor ?? this.easeFactor,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      tags: tags ?? this.tags,
      companies: companies ?? this.companies,
    );
  }
}

@JsonSerializable()
class CodeSolution {
  final String code;
  final String timeComplexity;
  final String spaceComplexity;
  final List<String> keyPoints;
  final String approach; // brute force, optimized, etc.

  CodeSolution({
    required this.code,
    required this.timeComplexity,
    required this.spaceComplexity,
    required this.keyPoints,
    required this.approach,
  });

  factory CodeSolution.fromJson(Map<String, dynamic> json) =>
      _$CodeSolutionFromJson(json);

  Map<String, dynamic> toJson() => _$CodeSolutionToJson(this);
}
