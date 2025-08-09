// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudySession _$StudySessionFromJson(Map<String, dynamic> json) => StudySession(
      id: json['id'] as String,
      userId: json['userId'] as String,
      mode: json['mode'] as String,
      targetTags: (json['targetTags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      targetCategories: (json['targetCategories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      cardIds:
          (json['cardIds'] as List<dynamic>).map((e) => e as String).toList(),
      results: (json['results'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, SessionCardResult.fromJson(e as Map<String, dynamic>)),
      ),
      totalCards: (json['totalCards'] as num).toInt(),
      completedCards: (json['completedCards'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$StudySessionToJson(StudySession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'mode': instance.mode,
      'targetTags': instance.targetTags,
      'targetCategories': instance.targetCategories,
      'startedAt': instance.startedAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'duration': instance.duration,
      'cardIds': instance.cardIds,
      'results': instance.results,
      'totalCards': instance.totalCards,
      'completedCards': instance.completedCards,
    };

SessionCardResult _$SessionCardResultFromJson(Map<String, dynamic> json) =>
    SessionCardResult(
      cardId: json['cardId'] as String,
      rating: (json['rating'] as num).toInt(),
      timeSpent: (json['timeSpent'] as num).toInt(),
      hintUsed: json['hintUsed'] as bool? ?? false,
      solutionViewed: json['solutionViewed'] as bool? ?? false,
      reviewedAt: json['reviewedAt'] == null
          ? null
          : DateTime.parse(json['reviewedAt'] as String),
    );

Map<String, dynamic> _$SessionCardResultToJson(SessionCardResult instance) =>
    <String, dynamic>{
      'cardId': instance.cardId,
      'rating': instance.rating,
      'timeSpent': instance.timeSpent,
      'hintUsed': instance.hintUsed,
      'solutionViewed': instance.solutionViewed,
      'reviewedAt': instance.reviewedAt.toIso8601String(),
    };
