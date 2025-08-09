import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/flashcard.dart';

class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();

  static const _dbName = 'flashcards.db';
  static const _dbVersion = 1;

  static const tableFlashcards = 'flashcards';

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;

    final dir = await getApplicationSupportDirectory();
    final dbPath = p.join(dir.path, _dbName);

    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableFlashcards (
            id TEXT PRIMARY KEY,
            json TEXT NOT NULL
          );
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_flashcards_id ON $tableFlashcards(id);');
      },
    );
  }

  Future<List<Flashcard>> getAllFlashcards() async {
    final db = _ensureDb();
    final rows = await db.query(tableFlashcards, orderBy: 'id ASC');
    return rows
        .map((r) => Flashcard.fromJson(jsonDecode(r['json'] as String) as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsertFlashcards(List<Flashcard> cards) async {
    final db = _ensureDb();
    final batch = db.batch();
    for (final c in cards) {
      batch.insert(
        tableFlashcards,
        {'id': c.id, 'json': jsonEncode(c.toJson())},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertFlashcard(Flashcard c) async {
    final db = _ensureDb();
    await db.insert(
      tableFlashcards,
      {'id': c.id, 'json': jsonEncode(c.toJson())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearFlashcards() async {
    final db = _ensureDb();
    await db.delete(tableFlashcards);
  }

  Database _ensureDb() {
    final db = _db;
    if (db == null) {
      throw StateError('LocalDb not initialized. Call LocalDb.instance.init() first.');
    }
    return db;
  }
}
