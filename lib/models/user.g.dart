// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] == null
          ? null
          : DateTime.parse(json['lastLoginAt'] as String),
      progress: json['progress'] == null
          ? null
          : UserProgress.fromJson(json['progress'] as Map<String, dynamic>),
      settings: json['settings'] == null
          ? null
          : UserSettings.fromJson(json['settings'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'displayName': instance.displayName,
      'photoUrl': instance.photoUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastLoginAt': instance.lastLoginAt.toIso8601String(),
      'progress': instance.progress,
      'settings': instance.settings,
    };

UserProgress _$UserProgressFromJson(Map<String, dynamic> json) => UserProgress(
      totalCardsStudied: (json['totalCardsStudied'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      lastStudyDate: json['lastStudyDate'] == null
          ? null
          : DateTime.parse(json['lastStudyDate'] as String),
      categoryProgress:
          (json['categoryProgress'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ),
      categoryMastery: (json['categoryMastery'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      grind75Completed: (json['grind75Completed'] as num?)?.toInt() ?? 0,
      weeklyProgress: (json['weeklyProgress'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(int.parse(k), (e as num).toInt()),
      ),
    );

Map<String, dynamic> _$UserProgressToJson(UserProgress instance) =>
    <String, dynamic>{
      'totalCardsStudied': instance.totalCardsStudied,
      'currentStreak': instance.currentStreak,
      'longestStreak': instance.longestStreak,
      'lastStudyDate': instance.lastStudyDate?.toIso8601String(),
      'categoryProgress': instance.categoryProgress,
      'categoryMastery': instance.categoryMastery,
      'grind75Completed': instance.grind75Completed,
      'weeklyProgress':
          instance.weeklyProgress.map((k, e) => MapEntry(k.toString(), e)),
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
