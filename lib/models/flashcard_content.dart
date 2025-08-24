import 'package:json_annotation/json_annotation.dart';

part 'flashcard_content.g.dart';

@JsonSerializable()
class FlashcardContent {
  final String id;
  final String title;
  final String question;
  final String hint;
  final Map<String, CodeSolution> solutions;
  final String dataStructureCategory;
  final String? algorithmPattern;
  final String predefinedDifficulty; // Easy/Medium/Hard
  final String leetcodeNumber;
  final DateTime createdAt;
  final List<String> tags;
  final List<String> companies;

  FlashcardContent({
    required this.id,
    required this.title,
    required this.question,
    required this.hint,
    required this.solutions,
    required this.dataStructureCategory,
    this.algorithmPattern,
    required this.predefinedDifficulty,
    required this.leetcodeNumber,
    DateTime? createdAt,
    List<String>? tags,
    List<String>? companies,
  })  : createdAt = createdAt ?? DateTime.now(),
        tags = tags ?? [],
        companies = companies ?? [];

  factory FlashcardContent.fromJson(Map<String, dynamic> json) =>
      _$FlashcardContentFromJson(json);

  Map<String, dynamic> toJson() => _$FlashcardContentToJson(this);

  FlashcardContent copyWith({
    String? id,
    String? title,
    String? question,
    String? hint,
    Map<String, CodeSolution>? solutions,
    String? dataStructureCategory,
    String? algorithmPattern,
    String? predefinedDifficulty,
    String? leetcodeNumber,
    DateTime? createdAt,
    List<String>? tags,
    List<String>? companies,
  }) {
    return FlashcardContent(
      id: id ?? this.id,
      title: title ?? this.title,
      question: question ?? this.question,
      hint: hint ?? this.hint,
      solutions: solutions ?? this.solutions,
      dataStructureCategory: dataStructureCategory ?? this.dataStructureCategory,
      algorithmPattern: algorithmPattern ?? this.algorithmPattern,
      predefinedDifficulty: predefinedDifficulty ?? this.predefinedDifficulty,
      leetcodeNumber: leetcodeNumber ?? this.leetcodeNumber,
      createdAt: createdAt ?? this.createdAt,
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
