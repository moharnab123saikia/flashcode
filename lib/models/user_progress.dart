import 'package:json_annotation/json_annotation.dart';

part 'user_progress.g.dart';

@JsonSerializable()
class UserProfile {
  final String userId;
  final String? displayName;
  final int currentStreak;
  final int longestStreak;
  final int totalCardsStudied;
  final DateTime? lastStudyDate;
  final UserSettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastSyncedAt;

  UserProfile({
    required this.userId,
    this.displayName,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalCardsStudied = 0,
    this.lastStudyDate,
    UserSettings? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncedAt,
  })  : settings = settings ?? UserSettings(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        lastSyncedAt = lastSyncedAt ?? DateTime.now();

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  UserProfile copyWith({
    String? userId,
    String? displayName,
    int? currentStreak,
    int? longestStreak,
    int? totalCardsStudied,
    DateTime? lastStudyDate,
    UserSettings? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalCardsStudied: totalCardsStudied ?? this.totalCardsStudied,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  // Calculate category progress from flashcard progress
  Map<String, int> calculateCategoryProgress(List<FlashcardProgress> progressList) {
    final categoryProgress = <String, int>{};
    for (final progress in progressList) {
      if (progress.reviewCount > 0) {
        // You'll need to get the category from the flashcard content
        // This is a placeholder - actual implementation would need category lookup
        final category = progress.flashcardId; // Replace with actual category lookup
        categoryProgress[category] = (categoryProgress[category] ?? 0) + 1;
      }
    }
    return categoryProgress;
  }

  // Calculate category mastery from flashcard progress
  Map<String, double> calculateCategoryMastery(List<FlashcardProgress> progressList) {
    final categoryMastery = <String, double>{};
    final categoryTotals = <String, int>{};
    final categoryMastered = <String, int>{};

    for (final progress in progressList) {
      // You'll need to get the category from the flashcard content
      final category = progress.flashcardId; // Replace with actual category lookup
      categoryTotals[category] = (categoryTotals[category] ?? 0) + 1;
      
      if (progress.personalDifficulty >= 4) {
        categoryMastered[category] = (categoryMastered[category] ?? 0) + 1;
      }
    }

    for (final category in categoryTotals.keys) {
      final total = categoryTotals[category]!;
      final mastered = categoryMastered[category] ?? 0;
      categoryMastery[category] = total > 0 ? mastered / total : 0.0;
    }

    return categoryMastery;
  }
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

  UserSettings copyWith({
    int? dailyGoal,
    int? sessionDuration,
    String? notificationTime,
    bool? notificationsEnabled,
    String? theme,
    String? defaultLanguage,
    int? codeFontSize,
    bool? cloudSyncEnabled,
    String? spacedRepetitionAlgorithm,
  }) {
    return UserSettings(
      dailyGoal: dailyGoal ?? this.dailyGoal,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      notificationTime: notificationTime ?? this.notificationTime,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      theme: theme ?? this.theme,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      codeFontSize: codeFontSize ?? this.codeFontSize,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      spacedRepetitionAlgorithm: spacedRepetitionAlgorithm ?? this.spacedRepetitionAlgorithm,
    );
  }
}

@JsonSerializable()
class FlashcardProgress {
  final String id;
  final String userId;
  final String flashcardId;
  final int personalDifficulty; // 1-4 for spaced repetition
  final int reviewCount;
  final double easeFactor;
  final int intervalDays;
  final DateTime? nextReview;
  final DateTime? lastReviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  FlashcardProgress({
    required this.id,
    required this.userId,
    required this.flashcardId,
    this.personalDifficulty = 2,
    this.reviewCount = 0,
    this.easeFactor = 2.5,
    this.intervalDays = 1,
    this.nextReview,
    this.lastReviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory FlashcardProgress.fromJson(Map<String, dynamic> json) =>
      _$FlashcardProgressFromJson(json);

  Map<String, dynamic> toJson() => _$FlashcardProgressToJson(this);

  FlashcardProgress copyWith({
    String? id,
    String? userId,
    String? flashcardId,
    int? personalDifficulty,
    int? reviewCount,
    double? easeFactor,
    int? intervalDays,
    DateTime? nextReview,
    DateTime? lastReviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlashcardProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      flashcardId: flashcardId ?? this.flashcardId,
      personalDifficulty: personalDifficulty ?? this.personalDifficulty,
      reviewCount: reviewCount ?? this.reviewCount,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      nextReview: nextReview ?? this.nextReview,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if this card is due for review
  bool get isDueForReview {
    if (nextReview == null) return true;
    return nextReview!.isBefore(DateTime.now()) || 
           nextReview!.isAtSameMomentAs(DateTime.now());
  }

  // Check if this card has been reviewed
  bool get hasBeenReviewed => reviewCount > 0;

  // Check if this card is mastered (high personal difficulty)
  bool get isMastered => personalDifficulty >= 4;
}

@JsonSerializable()
class FlashcardWithProgress {
  final String id;
  final String title;
  final String question;
  final String hint;
  final Map<String, dynamic> solutions; // Will be CodeSolution objects
  final String dataStructureCategory;
  final String? algorithmPattern;
  final String predefinedDifficulty;
  final String leetcodeNumber;
  final List<String> tags;
  final List<String> companies;
  final DateTime createdAt;
  
  // Progress data (nullable for cards without progress)
  final String? userId;
  final int personalDifficulty;
  final int reviewCount;
  final double easeFactor;
  final int intervalDays;
  final DateTime? nextReview;
  final DateTime? lastReviewedAt;
  final DateTime? progressUpdatedAt;

  FlashcardWithProgress({
    required this.id,
    required this.title,
    required this.question,
    required this.hint,
    required this.solutions,
    required this.dataStructureCategory,
    this.algorithmPattern,
    required this.predefinedDifficulty,
    required this.leetcodeNumber,
    required this.tags,
    required this.companies,
    required this.createdAt,
    this.userId,
    this.personalDifficulty = 2,
    this.reviewCount = 0,
    this.easeFactor = 2.5,
    this.intervalDays = 1,
    this.nextReview,
    this.lastReviewedAt,
    this.progressUpdatedAt,
  });

  factory FlashcardWithProgress.fromJson(Map<String, dynamic> json) =>
      _$FlashcardWithProgressFromJson(json);

  Map<String, dynamic> toJson() => _$FlashcardWithProgressToJson(this);

  FlashcardWithProgress copyWith({
    String? id,
    String? title,
    String? question,
    String? hint,
    Map<String, dynamic>? solutions,
    String? dataStructureCategory,
    String? algorithmPattern,
    String? predefinedDifficulty,
    String? leetcodeNumber,
    List<String>? tags,
    List<String>? companies,
    DateTime? createdAt,
    String? userId,
    int? personalDifficulty,
    int? reviewCount,
    double? easeFactor,
    int? intervalDays,
    DateTime? nextReview,
    DateTime? lastReviewedAt,
    DateTime? progressUpdatedAt,
  }) {
    return FlashcardWithProgress(
      id: id ?? this.id,
      title: title ?? this.title,
      question: question ?? this.question,
      hint: hint ?? this.hint,
      solutions: solutions ?? this.solutions,
      dataStructureCategory: dataStructureCategory ?? this.dataStructureCategory,
      algorithmPattern: algorithmPattern ?? this.algorithmPattern,
      predefinedDifficulty: predefinedDifficulty ?? this.predefinedDifficulty,
      leetcodeNumber: leetcodeNumber ?? this.leetcodeNumber,
      tags: tags ?? this.tags,
      companies: companies ?? this.companies,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      personalDifficulty: personalDifficulty ?? this.personalDifficulty,
      reviewCount: reviewCount ?? this.reviewCount,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      nextReview: nextReview ?? this.nextReview,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      progressUpdatedAt: progressUpdatedAt ?? this.progressUpdatedAt,
    );
  }

  // Check if this card is due for review
  bool get isDueForReview {
    if (nextReview == null) return true;
    return nextReview!.isBefore(DateTime.now()) || 
           nextReview!.isAtSameMomentAs(DateTime.now());
  }

  // Check if this card has been reviewed
  bool get hasBeenReviewed => reviewCount > 0;

  // Check if this card is mastered
  bool get isMastered => personalDifficulty >= 4;

  // Create progress object from this card
  FlashcardProgress toProgress() {
    return FlashcardProgress(
      id: '', // Will be generated by database
      userId: userId ?? '',
      flashcardId: id,
      personalDifficulty: personalDifficulty,
      reviewCount: reviewCount,
      easeFactor: easeFactor,
      intervalDays: intervalDays,
      nextReview: nextReview,
      lastReviewedAt: lastReviewedAt,
      updatedAt: progressUpdatedAt ?? DateTime.now(),
    );
  }
}

@JsonSerializable()
class SyncMetadata {
  final String userId;
  final DateTime lastSyncTimestamp;
  final String? deviceId;
  final int syncVersion;
  final bool conflictResolutionNeeded;
  final DateTime createdAt;
  final DateTime updatedAt;

  SyncMetadata({
    required this.userId,
    DateTime? lastSyncTimestamp,
    this.deviceId,
    this.syncVersion = 1,
    this.conflictResolutionNeeded = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : lastSyncTimestamp = lastSyncTimestamp ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory SyncMetadata.fromJson(Map<String, dynamic> json) =>
      _$SyncMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$SyncMetadataToJson(this);

  SyncMetadata copyWith({
    String? userId,
    DateTime? lastSyncTimestamp,
    String? deviceId,
    int? syncVersion,
    bool? conflictResolutionNeeded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SyncMetadata(
      userId: userId ?? this.userId,
      lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
      deviceId: deviceId ?? this.deviceId,
      syncVersion: syncVersion ?? this.syncVersion,
      conflictResolutionNeeded: conflictResolutionNeeded ?? this.conflictResolutionNeeded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
