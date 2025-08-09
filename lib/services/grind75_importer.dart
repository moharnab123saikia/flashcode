import '../data/grind75_questions.dart';
import '../models/flashcard.dart';
import 'supabase_service.dart';
import 'local_db.dart';

class Grind75Importer {
  static Future<void> importGrind75Questions() async {
    try {
      print('Starting Grind75 questions import...');
      
      // Get the questions
      final questions = grind75Questions;
      print('Found ${questions.length} Grind75 questions to import');
      
      // Save to local database first
      final localDb = LocalDb.instance;
      await localDb.init();
      
      for (final question in questions) {
        await localDb.upsertFlashcard(question);
        print('Saved locally: ${question.title}');
      }
      
      // Save to Supabase
      final supabaseService = SupabaseService.instance;
      for (final question in questions) {
        await supabaseService.upsertFlashcard(question);
        print('Saved to Supabase: ${question.title}');
      }
      
      print('✅ Successfully imported all ${questions.length} Grind75 questions!');
      
    } catch (e) {
      print('❌ Error importing Grind75 questions: $e');
      rethrow;
    }
  }
  
  static Future<List<Flashcard>> getGrind75QuestionsByWeek(int week) async {
    // Since we removed grind75Week and grind75Order, return all questions for now
    // TODO: Implement proper week-based filtering if needed
    return grind75Questions.toList();
  }
  
  static Future<Map<String, int>> getGrind75Statistics() async {
    final stats = <String, int>{};
    
    // Count by difficulty
    stats['Easy'] = grind75Questions.where((q) => q.predefinedDifficulty == 'Easy').length;
    stats['Medium'] = grind75Questions.where((q) => q.predefinedDifficulty == 'Medium').length;
    stats['Hard'] = grind75Questions.where((q) => q.predefinedDifficulty == 'Hard').length;
    
    // Count by data structure
    final categories = grind75Questions.map((q) => q.dataStructureCategory).toSet();
    for (final category in categories) {
      stats[category] = grind75Questions.where((q) => q.dataStructureCategory == category).length;
    }
    
    // Count by week - removed since grind75Week property no longer exists
    // TODO: Implement week-based counting if needed
    
    return stats;
  }
}
