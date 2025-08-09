import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard.dart';

class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();

  static const _flashcardsKey = 'flashcards_data';

  Future<void> init() async {
    // No initialization needed for SharedPreferences
  }

  Future<List<Flashcard>> getAllFlashcards() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_flashcardsKey);
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((json) => Flashcard.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsertFlashcards(List<Flashcard> cards) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing cards
    final existingCards = await getAllFlashcards();
    final cardMap = {for (var card in existingCards) card.id: card};
    
    // Update with new cards
    for (final card in cards) {
      cardMap[card.id] = card;
    }
    
    // Save back
    final jsonList = cardMap.values.map((c) => c.toJson()).toList();
    await prefs.setString(_flashcardsKey, jsonEncode(jsonList));
  }

  Future<void> upsertFlashcard(Flashcard card) async {
    await upsertFlashcards([card]);
  }

  Future<void> clearFlashcards() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_flashcardsKey);
  }
}
