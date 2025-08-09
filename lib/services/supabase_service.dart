import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/flashcard.dart';
import 'config.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  Future<void> init() async {
    // Supabase.initialize should be called once in main()
    // This method exists for symmetry with LocalDb.init()
  }

  // Pull all flashcards (expects a table with columns: id TEXT PRIMARY KEY, json JSONB)
  Future<List<Flashcard>> pullFlashcards() async {
    final res = await client
        .from(AppConfig.tableFlashcards)
        .select('*');

    return res
        .map((row) {
          final jsonField = row['json'];
          if (jsonField is Map<String, dynamic>) {
            return Flashcard.fromJson(jsonField);
          }
          if (jsonField is String) {
            return Flashcard.fromJson(jsonDecode(jsonField) as Map<String, dynamic>);
          }
          throw StateError('Unexpected json field type: ${jsonField.runtimeType}');
        })
        .toList();
  }

  // Upsert many
  Future<void> upsertFlashcards(List<Flashcard> cards) async {
    if (cards.isEmpty) return;
    final payload = cards
        .map((c) => {
              'id': c.id,
              // store as JSONB if the column is json/jsonb, or text if text
              'json': c.toJson(),
            })
        .toList();

    await client
        .from(AppConfig.tableFlashcards)
        .upsert(payload, onConflict: 'id');
  }

  // Upsert one
  Future<void> upsertFlashcard(Flashcard c) async {
    await client.from(AppConfig.tableFlashcards).upsert({
      'id': c.id,
      'json': c.toJson(),
    }, onConflict: 'id');
  }

  // Delete all (useful for testing)
  Future<void> clearRemote() async {
    await client.from(AppConfig.tableFlashcards).delete().neq('id', '');
  }
}
