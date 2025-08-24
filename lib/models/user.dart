import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final UserProgress progress;
  final UserSettings settings;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    UserProgress? progress,
    UserSettings? settings,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastLoginAt = lastLoginAt ?? DateTime.now(),
        progress = progress ?? UserProgress(),
        settings = settings ?? UserSettings();

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    UserProgress? progress,
    UserSettings? settings,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      progress: progress ?? this.progress,
      settings: settings ?? this.settings,
    );
  }
}

@JsonSerializable()
class UserProgress {
  final int totalCardsStudied;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStudyDate;
  final Map<String, int> categoryProgress; // category -> completed count
  final Map<String, double> categoryMastery; // category -> mastery percentage
  final int grind75Completed;
  final Map<int, int> weeklyProgress; // week number -> completed count

  UserProgress({
    this.totalCardsStudied = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastStudyDate,
    Map<String, int>? categoryProgress,
    Map<String, double>? categoryMastery,
    this.grind75Completed = 0,
    Map<int, int>? weeklyProgress,
  })  : categoryProgress = categoryProgress ?? {},
        categoryMastery = categoryMastery ?? {},
        weeklyProgress = weeklyProgress ?? {};

  factory UserProgress.fromJson(Map<String, dynamic> json) =>
      _$UserProgressFromJson(json);

  Map<String, dynamic> toJson() => _$UserProgressToJson(this);
}

@JsonSerializable()
class UserSettings {
  final int dailyGoal;
  final int sessionDuration; // in minutes
  final String notificationTime; // HH:mm format
  final bool notificationsEnabled;
  final String theme; // 'light', 'dark', 'auto'
  final String defaultLanguage; // 'python', 'java', 'csharp'
  final int codeFontSize;
  final bool cloudSyncEnabled;
  final String spacedRepetitionAlgorithm; // 'SM-2', 'Anki', etc.

  UserSettings({
    this.dailyGoal = 15,
    this.sessionDuration = 30,
    this.notificationTime = '09:00',
    this.notificationsEnabled = true,
    this.theme = 'auto',
    this.defaultLanguage = 'python',
    this.codeFontSize = 14,
    this.cloudSyncEnabled = true,
    this.spacedRepetitionAlgorithm = 'SM-2',
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$UserSettingsToJson(this);
}
