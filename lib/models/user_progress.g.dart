// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String?,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      totalCardsStudied: (json['totalCardsStudied'] as num?)?.toInt() ?? 0,
      lastStudyDate: json['lastStudyDate'] == null
          ? null
          : DateTime.parse(json['lastStudyDate'] as String),
      settings: json['settings'] == null
          ? null
          : UserSettings.fromJson(json['settings'] as Map<String, dynamic>),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      lastSyncedAt: json['lastSyncedAt'] == null
          ? null
          : DateTime.parse(json['lastSyncedAt'] as String),
    );

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'displayName': instance.displayName,
      'currentStreak': instance.currentStreak,
      'longestStreak': instance.longestStreak,
      'totalCardsStudied': instance.totalCardsStudied,
      'lastStudyDate': instance.lastStudyDate?.toIso8601String(),
      'settings': instance.settings,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'lastSyncedAt': instance.lastSyncedAt.toIso8601String(),
    };

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) => UserSettings(
      dailyGoal: (json['dailyGoal'] as num?)?.toInt() ?? 15,
      sessionDuration: (json['sessionDuration'] as num?)?.toInt() ?? 30,
      notificationTime: json['notificationTime'] as String? ?? '09:00',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      theme: json['theme'] as String? ?? 'auto',
      defaultLanguage: json['defaultLanguage'] as String? ?? 'python',
      codeFontSize: (json['codeFontSize'] as num?)?.toInt() ?? 14,
      cloudSyncEnabled: json['cloudSyncEnabled'] as bool? ?? true,
      spacedRepetitionAlgorithm:
          json['spacedRepetitionAlgorithm'] as String? ?? 'SM-2',
    );

Map<String, dynamic> _$UserSettingsToJson(UserSettings instance) =>
    <String, dynamic>{
      'dailyGoal': instance.dailyGoal,
      'sessionDuration': instance.sessionDuration,
      'notificationTime': instance.notificationTime,
      'notificationsEnabled': instance.notificationsEnabled,
      'theme': instance.theme,
      'defaultLanguage': instance.defaultLanguage,
      'codeFontSize': instance.codeFontSize,
      'cloudSyncEnabled': instance.cloudSyncEnabled,
      'spacedRepetitionAlgorithm': instance.spacedRepetitionAlgorithm,
    };

FlashcardProgress _$FlashcardProgressFromJson(Map<String, dynamic> json) =>
    FlashcardProgress(
      id: json['id'] as String,
      userId: json['userId'] as String,
      flashcardId: json['flashcardId'] as String,
      personalDifficulty: (json['personalDifficulty'] as num?)?.toInt() ?? 2,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: (json['intervalDays'] as num?)?.toInt() ?? 1,
      nextReview: json['nextReview'] == null
          ? null
          : DateTime.parse(json['nextReview'] as String),
      lastReviewedAt: json['lastReviewedAt'] == null
          ? null
          : DateTime.parse(json['lastReviewedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$FlashcardProgressToJson(FlashcardProgress instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'flashcardId': instance.flashcardId,
      'personalDifficulty': instance.personalDifficulty,
      'reviewCount': instance.reviewCount,
      'easeFactor': instance.easeFactor,
      'intervalDays': instance.intervalDays,
      'nextReview': instance.nextReview?.toIso8601String(),
      'lastReviewedAt': instance.lastReviewedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

FlashcardWithProgress _$FlashcardWithProgressFromJson(
        Map<String, dynamic> json) =>
    FlashcardWithProgress(
      id: json['id'] as String,
      title: json['title'] as String,
      question: json['question'] as String,
      hint: json['hint'] as String,
      solutions: json['solutions'] as Map<String, dynamic>,
      dataStructureCategory: json['dataStructureCategory'] as String,
      algorithmPattern: json['algorithmPattern'] as String?,
      predefinedDifficulty: json['predefinedDifficulty'] as String,
      leetcodeNumber: json['leetcodeNumber'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      companies:
          (json['companies'] as List<dynamic>).map((e) => e as String).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      userId: json['userId'] as String?,
      personalDifficulty: (json['personalDifficulty'] as num?)?.toInt() ?? 2,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: (json['intervalDays'] as num?)?.toInt() ?? 1,
      nextReview: json['nextReview'] == null
          ? null
          : DateTime.parse(json['nextReview'] as String),
      lastReviewedAt: json['lastReviewedAt'] == null
          ? null
          : DateTime.parse(json['lastReviewedAt'] as String),
      progressUpdatedAt: json['progressUpdatedAt'] == null
          ? null
          : DateTime.parse(json['progressUpdatedAt'] as String),
    );

Map<String, dynamic> _$FlashcardWithProgressToJson(
        FlashcardWithProgress instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'question': instance.question,
      'hint': instance.hint,
      'solutions': instance.solutions,
      'dataStructureCategory': instance.dataStructureCategory,
      'algorithmPattern': instance.algorithmPattern,
      'predefinedDifficulty': instance.predefinedDifficulty,
      'leetcodeNumber': instance.leetcodeNumber,
      'tags': instance.tags,
      'companies': instance.companies,
      'createdAt': instance.createdAt.toIso8601String(),
      'userId': instance.userId,
      'personalDifficulty': instance.personalDifficulty,
      'reviewCount': instance.reviewCount,
      'easeFactor': instance.easeFactor,
      'intervalDays': instance.intervalDays,
      'nextReview': instance.nextReview?.toIso8601String(),
      'lastReviewedAt': instance.lastReviewedAt?.toIso8601String(),
      'progressUpdatedAt': instance.progressUpdatedAt?.toIso8601String(),
    };

SyncMetadata _$SyncMetadataFromJson(Map<String, dynamic> json) => SyncMetadata(
      userId: json['userId'] as String,
      lastSyncTimestamp: json['lastSyncTimestamp'] == null
          ? null
          : DateTime.parse(json['lastSyncTimestamp'] as String),
      deviceId: json['deviceId'] as String?,
      syncVersion: (json['syncVersion'] as num?)?.toInt() ?? 1,
      conflictResolutionNeeded:
          json['conflictResolutionNeeded'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SyncMetadataToJson(SyncMetadata instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'lastSyncTimestamp': instance.lastSyncTimestamp.toIso8601String(),
      'deviceId': instance.deviceId,
      'syncVersion': instance.syncVersion,
      'conflictResolutionNeeded': instance.conflictResolutionNeeded,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
