// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Flashcard _$FlashcardFromJson(Map<String, dynamic> json) => Flashcard(
      id: json['id'] as String,
      title: json['title'] as String,
      question: json['question'] as String,
      hint: json['hint'] as String,
      solutions: (json['solutions'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, CodeSolution.fromJson(e as Map<String, dynamic>)),
      ),
      dataStructureCategory: json['dataStructureCategory'] as String,
      algorithmPattern: json['algorithmPattern'] as String?,
      predefinedDifficulty: json['predefinedDifficulty'] as String,
      personalDifficulty: (json['personalDifficulty'] as num?)?.toInt() ?? 2,
      leetcodeNumber: json['leetcodeNumber'] as String,
      nextReview: json['nextReview'] == null
          ? null
          : DateTime.parse(json['nextReview'] as String),
      interval: (json['interval'] as num?)?.toInt() ?? 1,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      lastReviewedAt: json['lastReviewedAt'] == null
          ? null
          : DateTime.parse(json['lastReviewedAt'] as String),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      companies: (json['companies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$FlashcardToJson(Flashcard instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'question': instance.question,
      'hint': instance.hint,
      'solutions': instance.solutions,
      'dataStructureCategory': instance.dataStructureCategory,
      'algorithmPattern': instance.algorithmPattern,
      'predefinedDifficulty': instance.predefinedDifficulty,
      'personalDifficulty': instance.personalDifficulty,
      'leetcodeNumber': instance.leetcodeNumber,
      'nextReview': instance.nextReview?.toIso8601String(),
      'interval': instance.interval,
      'easeFactor': instance.easeFactor,
      'reviewCount': instance.reviewCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastReviewedAt': instance.lastReviewedAt?.toIso8601String(),
      'tags': instance.tags,
      'companies': instance.companies,
    };

CodeSolution _$CodeSolutionFromJson(Map<String, dynamic> json) => CodeSolution(
      code: json['code'] as String,
      timeComplexity: json['timeComplexity'] as String,
      spaceComplexity: json['spaceComplexity'] as String,
      keyPoints:
          (json['keyPoints'] as List<dynamic>).map((e) => e as String).toList(),
      approach: json['approach'] as String,
    );

Map<String, dynamic> _$CodeSolutionToJson(CodeSolution instance) =>
    <String, dynamic>{
      'code': instance.code,
      'timeComplexity': instance.timeComplexity,
      'spaceComplexity': instance.spaceComplexity,
      'keyPoints': instance.keyPoints,
      'approach': instance.approach,
    };
