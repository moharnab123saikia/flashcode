import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/flashcard_content.dart';
import '../models/user_progress.dart';

class LocalDbV2 {
  LocalDbV2._();
  static final LocalDbV2 instance = LocalDbV2._();

  static const _dbName = 'flashcards_v2.db';
  static const _dbVersion = 3; // Force clean rebuild with correct schema

  // Table names
  static const tableFlashcardContent = 'flashcard_content';
  static const tableUserProfile = 'user_profile';
  static const tableFlashcardProgress = 'flashcard_progress';

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;

    final dir = await getApplicationSupportDirectory();
    final dbPath = p.join(dir.path, _dbName);

    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        // Flashcard content table (static data)
        await db.execute('''
          CREATE TABLE $tableFlashcardContent (
            id TEXT PRIMARY KEY,
            json TEXT NOT NULL
          );
        ''');

        // User profile table (one record per user)
        await db.execute('''
          CREATE TABLE $tableUserProfile (
            user_id TEXT PRIMARY KEY,
            json TEXT NOT NULL
          );
        ''');

        // Flashcard progress table (per card progress, per user)
        await db.execute('''
          CREATE TABLE $tableFlashcardProgress (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            flashcard_id TEXT NOT NULL,
            json TEXT NOT NULL
          );
        ''');

        // Create indexes
        await db.execute('CREATE INDEX IF NOT EXISTS idx_flashcard_content_id ON $tableFlashcardContent(id);');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_flashcard_progress_card_id ON $tableFlashcardProgress(flashcard_id);');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Migration from v1 to v2: Add user_id column to tables
          
          // Migrate user_profile table
          try {
            final userProfileInfo = await db.rawQuery("PRAGMA table_info($tableUserProfile)");
            final hasUserId = userProfileInfo.any((column) => column['name'] == 'user_id');
            
            if (!hasUserId) {
              // Recreate the user_profile table with user_id column
              await db.execute('DROP TABLE IF EXISTS ${tableUserProfile}_backup');
              await db.execute('CREATE TABLE ${tableUserProfile}_backup AS SELECT * FROM $tableUserProfile');
              await db.execute('DROP TABLE $tableUserProfile');
              
              await db.execute('''
                CREATE TABLE $tableUserProfile (
                  user_id TEXT PRIMARY KEY,
                  json TEXT NOT NULL
                );
              ''');
              
              // Migrate existing data with a default user_id if any exists
              final backupRows = await db.query('${tableUserProfile}_backup');
              for (final row in backupRows) {
                await db.insert(
                  tableUserProfile,
                  {
                    'user_id': 'migrated_user',
                    'json': row['json'],
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
              
              // Clean up backup table
              await db.execute('DROP TABLE ${tableUserProfile}_backup');
            }
          } catch (e) {
            // If migration fails, recreate the table from scratch
            await db.execute('DROP TABLE IF EXISTS $tableUserProfile');
            await db.execute('''
              CREATE TABLE $tableUserProfile (
                user_id TEXT PRIMARY KEY,
                json TEXT NOT NULL
              );
            ''');
          }
          
          // Migrate flashcard_progress table
          try {
            final progressInfo = await db.rawQuery("PRAGMA table_info($tableFlashcardProgress)");
            final hasUserIdProgress = progressInfo.any((column) => column['name'] == 'user_id');
            
            if (!hasUserIdProgress) {
              // Recreate the flashcard_progress table with user_id column
              await db.execute('DROP TABLE IF EXISTS ${tableFlashcardProgress}_backup');
              await db.execute('CREATE TABLE ${tableFlashcardProgress}_backup AS SELECT * FROM $tableFlashcardProgress');
              await db.execute('DROP TABLE $tableFlashcardProgress');
              
              await db.execute('''
                CREATE TABLE $tableFlashcardProgress (
                  id TEXT PRIMARY KEY,
                  user_id TEXT NOT NULL,
                  flashcard_id TEXT NOT NULL,
                  json TEXT NOT NULL
                );
              ''');
              
              // Migrate existing data with a default user_id if any exists
              final backupRows = await db.query('${tableFlashcardProgress}_backup');
              for (final row in backupRows) {
                await db.insert(
                  tableFlashcardProgress,
                  {
                    'id': row['id'],
                    'user_id': 'migrated_user',
                    'flashcard_id': row['flashcard_id'] ?? row['id'],
                    'json': row['json'],
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
              
              // Clean up backup table
              await db.execute('DROP TABLE ${tableFlashcardProgress}_backup');
              
              // Recreate index
              await db.execute('CREATE INDEX IF NOT EXISTS idx_flashcard_progress_card_id ON $tableFlashcardProgress(flashcard_id);');
            }
          } catch (e) {
            // If migration fails, recreate the table from scratch
            await db.execute('DROP TABLE IF EXISTS $tableFlashcardProgress');
            await db.execute('''
              CREATE TABLE $tableFlashcardProgress (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                flashcard_id TEXT NOT NULL,
                json TEXT NOT NULL
              );
            ''');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_flashcard_progress_card_id ON $tableFlashcardProgress(flashcard_id);');
          }
        }
      },
    );
  }

  // ============================================
  // FLASHCARD CONTENT (Static Data)
  // ============================================

  Future<List<FlashcardContent>> getAllFlashcardContent() async {
    final db = _ensureDb();
    final rows = await db.query(tableFlashcardContent, orderBy: 'id ASC');
    return rows
        .map((r) => FlashcardContent.fromJson(jsonDecode(r['json'] as String) as Map<String, dynamic>))
        .toList();
  }

  Future<FlashcardContent?> getFlashcardContent(String id) async {
    final db = _ensureDb();
    final rows = await db.query(
      tableFlashcardContent, 
      where: 'id = ?', 
      whereArgs: [id]
    );
    
    if (rows.isEmpty) return null;
    
    return FlashcardContent.fromJson(
      jsonDecode(rows.first['json'] as String) as Map<String, dynamic>
    );
  }

  Future<void> upsertFlashcardContent(List<FlashcardContent> cards) async {
    final db = _ensureDb();
    final batch = db.batch();
    for (final card in cards) {
      batch.insert(
        tableFlashcardContent,
        {'id': card.id, 'json': jsonEncode(card.toJson())},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> clearFlashcardContent() async {
    final db = _ensureDb();
    await db.delete(tableFlashcardContent);
  }

  // ============================================
  // USER PROFILE
  // ============================================

  Future<UserProfile?> getUserProfile({String? userId}) async {
    final db = _ensureDb();
    
    if (userId == null || userId.isEmpty) {
      // Get any profile (for backward compatibility)
      final rows = await db.query(tableUserProfile, limit: 1);
      if (rows.isEmpty) return null;
      return UserProfile.fromJson(
        jsonDecode(rows.first['json'] as String) as Map<String, dynamic>
      );
    }
    
    final rows = await db.query(
      tableUserProfile, 
      where: 'user_id = ?', 
      whereArgs: [userId]
    );
    
    if (rows.isEmpty) return null;
    
    return UserProfile.fromJson(
      jsonDecode(rows.first['json'] as String) as Map<String, dynamic>
    );
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final db = _ensureDb();
    await db.insert(
      tableUserProfile,
      {'user_id': profile.userId, 'json': jsonEncode(profile.toJson())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearUserProfile({String? userId}) async {
    final db = _ensureDb();
    if (userId == null || userId.isEmpty) {
      // Clear all profiles
      await db.delete(tableUserProfile);
    } else {
      await db.delete(
        tableUserProfile,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }
  }

  // ============================================
  // FLASHCARD PROGRESS
  // ============================================

  Future<List<FlashcardProgress>> getAllFlashcardProgress({String? userId}) async {
    final db = _ensureDb();
    
    List<Map<String, Object?>> rows;
    if (userId == null || userId.isEmpty) {
      // Get all progress (for backward compatibility)
      rows = await db.query(tableFlashcardProgress, orderBy: 'flashcard_id ASC');
    } else {
      rows = await db.query(
        tableFlashcardProgress,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'flashcard_id ASC',
      );
    }
    
    return rows
        .map((r) => FlashcardProgress.fromJson(jsonDecode(r['json'] as String) as Map<String, dynamic>))
        .toList();
  }

  Future<FlashcardProgress?> getFlashcardProgress(String flashcardId, {String? userId}) async {
    final db = _ensureDb();
    
    List<Map<String, Object?>> rows;
    if (userId == null || userId.isEmpty) {
      rows = await db.query(
        tableFlashcardProgress,
        where: 'flashcard_id = ?',
        whereArgs: [flashcardId],
      );
    } else {
      rows = await db.query(
        tableFlashcardProgress,
        where: 'flashcard_id = ? AND user_id = ?',
        whereArgs: [flashcardId, userId],
      );
    }
    
    if (rows.isEmpty) return null;
    
    return FlashcardProgress.fromJson(
      jsonDecode(rows.first['json'] as String) as Map<String, dynamic>
    );
  }

  Future<void> saveFlashcardProgress(FlashcardProgress progress) async {
    final db = _ensureDb();
    await db.insert(
      tableFlashcardProgress,
      {
        'id': progress.id.isNotEmpty ? progress.id : progress.flashcardId,
        'user_id': progress.userId,
        'flashcard_id': progress.flashcardId,
        'json': jsonEncode(progress.toJson())
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveFlashcardProgressBatch(List<FlashcardProgress> progressList) async {
    final db = _ensureDb();
    final batch = db.batch();
    
    for (final progress in progressList) {
      batch.insert(
        tableFlashcardProgress,
        {
          'id': progress.id.isNotEmpty ? progress.id : progress.flashcardId,
          'user_id': progress.userId,
          'flashcard_id': progress.flashcardId,
          'json': jsonEncode(progress.toJson())
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  Future<void> deleteFlashcardProgress(String flashcardId, {String? userId}) async {
    final db = _ensureDb();
    if (userId == null || userId.isEmpty) {
      await db.delete(
        tableFlashcardProgress,
        where: 'flashcard_id = ?',
        whereArgs: [flashcardId],
      );
    } else {
      await db.delete(
        tableFlashcardProgress,
        where: 'flashcard_id = ? AND user_id = ?',
        whereArgs: [flashcardId, userId],
      );
    }
  }

  Future<void> clearFlashcardProgress({String? userId}) async {
    final db = _ensureDb();
    if (userId == null || userId.isEmpty) {
      // Clear all progress
      await db.delete(tableFlashcardProgress);
    } else {
      await db.delete(
        tableFlashcardProgress,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }
  }

  // ============================================
  // COMBINED OPERATIONS
  // ============================================

  /// Get flashcards with user progress combined
  Future<List<FlashcardWithProgress>> getFlashcardsWithProgress({String? userId}) async {
    final content = await getAllFlashcardContent();
    final progress = await getAllFlashcardProgress(userId: userId);
    
    final progressMap = <String, FlashcardProgress>{};
    for (final p in progress) {
      progressMap[p.flashcardId] = p;
    }
    
    return content.map((card) {
      final userProgress = progressMap[card.id];
      
      return FlashcardWithProgress(
        id: card.id,
        title: card.title,
        question: card.question,
        hint: card.hint,
        solutions: card.solutions.map((key, value) => MapEntry(key, value.toJson())),
        dataStructureCategory: card.dataStructureCategory,
        algorithmPattern: card.algorithmPattern,
        predefinedDifficulty: card.predefinedDifficulty,
        leetcodeNumber: card.leetcodeNumber,
        tags: card.tags,
        companies: card.companies,
        createdAt: card.createdAt,
        userId: userProgress?.userId,
        personalDifficulty: userProgress?.personalDifficulty ?? 2,
        reviewCount: userProgress?.reviewCount ?? 0,
        easeFactor: userProgress?.easeFactor ?? 2.5,
        intervalDays: userProgress?.intervalDays ?? 1,
        nextReview: userProgress?.nextReview,
        lastReviewedAt: userProgress?.lastReviewedAt,
        progressUpdatedAt: userProgress?.updatedAt,
      );
    }).toList();
  }

  /// Get cards due for review
  Future<List<FlashcardWithProgress>> getCardsDueForReview({String? userId}) async {
    final cardsWithProgress = await getFlashcardsWithProgress(userId: userId);
    final now = DateTime.now();
    
    return cardsWithProgress.where((card) {
      if (card.nextReview == null) return true;
      return card.nextReview!.isBefore(now) || card.nextReview!.isAtSameMomentAs(now);
    }).toList();
  }

  /// Get study statistics
  Future<Map<String, dynamic>> getStudyStats({String? userId}) async {
    final profile = await getUserProfile(userId: userId);
    final progress = await getAllFlashcardProgress(userId: userId);
    final now = DateTime.now();
    
    final studiedToday = progress.where((p) => 
      p.lastReviewedAt != null && 
      _isSameDay(p.lastReviewedAt!, now)
    ).length;
    
    final dueForReview = progress.where((p) => 
      p.nextReview == null || 
      p.nextReview!.isBefore(now) || 
      p.nextReview!.isAtSameMomentAs(now)
    ).length;
    
    final mastered = progress.where((p) => p.personalDifficulty >= 4).length;
    
    return {
      'currentStreak': profile?.currentStreak ?? 0,
      'longestStreak': profile?.longestStreak ?? 0,
      'totalCardsStudied': profile?.totalCardsStudied ?? 0,
      'studiedToday': studiedToday,
      'dueForReview': dueForReview,
      'mastered': mastered,
      'totalProgress': progress.length,
      'lastStudyDate': profile?.lastStudyDate?.toIso8601String(),
    };
  }

  // ============================================
  // BULK OPERATIONS
  // ============================================

  /// Clear all user data (profile and progress, but keep flashcard content)
  Future<void> clearUserData() async {
    await clearUserProfile();
    await clearFlashcardProgress();
  }

  /// Clear all data
  Future<void> clearAllData() async {
    await clearFlashcardContent();
    await clearUserProfile();
    await clearFlashcardProgress();
  }

  /// Export all data for backup
  Future<Map<String, dynamic>> exportData() async {
    final profile = await getUserProfile();
    final progress = await getAllFlashcardProgress();
    final content = await getAllFlashcardContent();
    
    return {
      'version': _dbVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profile?.toJson(),
      'progress': progress.map((p) => p.toJson()).toList(),
      'content': content.map((c) => c.toJson()).toList(),
    };
  }

  /// Import data from backup
  Future<void> importData(Map<String, dynamic> data) async {
    // Clear existing data
    await clearAllData();
    
    // Import profile
    if (data['profile'] != null) {
      final profile = UserProfile.fromJson(data['profile'] as Map<String, dynamic>);
      await saveUserProfile(profile);
    }
    
    // Import progress
    if (data['progress'] != null) {
      final progressList = (data['progress'] as List)
          .map((p) => FlashcardProgress.fromJson(p as Map<String, dynamic>))
          .toList();
      await saveFlashcardProgressBatch(progressList);
    }
    
    // Import content
    if (data['content'] != null) {
      final contentList = (data['content'] as List)
          .map((c) => FlashcardContent.fromJson(c as Map<String, dynamic>))
          .toList();
      await upsertFlashcardContent(contentList);
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  Database _ensureDb() {
    final db = _db;
    if (db == null) {
      throw StateError('LocalDbV2 not initialized. Call LocalDbV2.instance.init() first.');
    }
    return db;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Close database connection
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
