import '../models/flashcard.dart';

class LocalDb {
  LocalDb._();
  static final LocalDb instance = throw UnsupportedError(
    'Cannot create LocalDb without dart:io or dart:html',
  );

  Future<void> init() async {
    throw UnimplementedError();
  }

  Future<List<Flashcard>> getAllFlashcards() async {
    throw UnimplementedError();
  }

  Future<void> upsertFlashcards(List<Flashcard> cards) async {
    throw UnimplementedError();
  }

  Future<void> upsertFlashcard(Flashcard card) async {
    throw UnimplementedError();
  }

  Future<void> clearFlashcards() async {
    throw UnimplementedError();
  }
}
