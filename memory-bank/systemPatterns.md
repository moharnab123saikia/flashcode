# System Patterns - LeetCode Flashcards App

## Architecture Overview

### High-Level System Design
```
┌─────────────────────────────────────────────────────────────────┐
│                    Flutter Application Layer                   │
├─────────────────────────────────────────────────────────────────┤
│  Screens/Widgets  │  Providers  │  Services  │  Data Models    │
├─────────────────────────────────────────────────────────────────┤
│                     Business Logic Layer                       │
├─────────────────────────────────────────────────────────────────┤
│  Local Storage    │              │  Cloud Storage             │
│  (SQLite)        │   Sync Layer │  (Supabase PostgreSQL)    │
└─────────────────────────────────────────────────────────────────┘
```

## Core Design Patterns

### 1. Repository Pattern
**Purpose**: Abstract data layer to support offline-first architecture

```dart
abstract class FlashcardRepository {
  Future<List<Flashcard>> getAllFlashcards();
  Future<Flashcard?> getFlashcardById(String id);
  Future<void> updateProgress(String flashcardId, StudySession session);
  Stream<List<Flashcard>> watchDueFlashcards();
}

class OfflineFirstFlashcardRepository implements FlashcardRepository {
  final LocalDatabase _localDb;
  final SupabaseService _cloudDb;
  final SyncService _syncService;
  
  // Always read from local, sync in background
  @override
  Future<List<Flashcard>> getAllFlashcards() async {
    return await _localDb.getAllFlashcards();
  }
}
```

### 2. Provider State Management Pattern
**Purpose**: Reactive UI updates with centralized state

```dart
class FlashcardProvider extends ChangeNotifier {
  final FlashcardRepository _repository;
  
  List<Flashcard> _flashcards = [];
  Flashcard? _currentFlashcard;
  bool _isLoading = false;
  
  // Reactive getters
  List<Flashcard> get flashcards => _flashcards;
  Flashcard? get currentFlashcard => _currentFlashcard;
  bool get isLoading => _isLoading;
  
  // Business logic methods
  Future<void> loadNextDueFlashcard() async {
    _isLoading = true;
    notifyListeners();
    
    _currentFlashcard = await _repository.getNextDueFlashcard();
    
    _isLoading = false;
    notifyListeners();
  }
}
```

### 3. Service Layer Pattern
**Purpose**: Encapsulate business logic and external integrations

#### Spaced Repetition Service
```dart
class SpacedRepetitionService {
  static const double initialEaseFactor = 2.5;
  static const int initialInterval = 1;
  
  StudyResult calculateNextReview({
    required int difficultyRating, // 1-4 user rating
    required double currentEaseFactor,
    required int currentInterval,
    required int reviewCount,
  }) {
    // SuperMemo 2 algorithm implementation
    double newEaseFactor = currentEaseFactor;
    int newInterval = currentInterval;
    
    if (difficultyRating >= 3) {
      // Success: increase interval
      if (reviewCount == 0) {
        newInterval = 1;
      } else if (reviewCount == 1) {
        newInterval = 6;
      } else {
        newInterval = (currentInterval * currentEaseFactor).round();
      }
      
      newEaseFactor = currentEaseFactor + 
          (0.1 - (5 - difficultyRating) * (0.08 + (5 - difficultyRating) * 0.02));
    } else {
      // Failure: reset interval
      newInterval = 1;
    }
    
    return StudyResult(
      nextReviewDate: DateTime.now().add(Duration(days: newInterval)),
      newEaseFactor: math.max(1.3, newEaseFactor),
      newInterval: newInterval,
    );
  }
}
```

#### Sync Service Pattern
```dart
class SyncService {
  final LocalDatabase _localDb;
  final SupabaseService _cloudDb;
  
  Future<void> syncToCloud() async {
    final unsyncedSessions = await _localDb.getUnsyncedStudySessions();
    
    for (final session in unsyncedSessions) {
      try {
        await _cloudDb.insertStudySession(session);
        await _localDb.markSessionAsSynced(session.id);
      } catch (e) {
        // Log error, continue with other sessions
        print('Failed to sync session ${session.id}: $e');
      }
    }
  }
  
  Future<void> syncFromCloud() async {
    final lastSyncTimestamp = await _localDb.getLastSyncTimestamp();
    final newFlashcards = await _cloudDb.getFlashcardsModifiedAfter(lastSyncTimestamp);
    
    for (final flashcard in newFlashcards) {
      await _localDb.upsertFlashcard(flashcard);
    }
    
    await _localDb.updateLastSyncTimestamp(DateTime.now());
  }
}
```

## Data Flow Patterns

### 1. Offline-First Data Flow
```
User Action → Provider → Service → Local DB → UI Update
                ↓
            Background Sync → Cloud DB
```

**Implementation**:
- All user actions immediately update local SQLite
- UI reactively updates from local data
- Background service syncs to Supabase when online
- Conflict resolution handled by sync service

### 2. Study Session Flow
```
Load Due Cards → Present Card → User Rating → Update Progress → Next Card
     ↑                                           ↓
     └─────────── Schedule Next Review ←─────────┘
```

**Key Components**:
- `StudySessionProvider`: Manages current study state
- `SpacedRepetitionService`: Calculates review schedules
- `FlashcardRepository`: Persists progress data

### 3. Data Synchronization Pattern
```
Local Change → Queue for Sync → Background Upload → Mark as Synced
                    ↓
Cloud Change → Background Download → Merge with Local → Update UI
```

## Component Relationships

### Screen → Provider → Service → Repository Hierarchy

#### Study Screen Architecture
```dart
class StudyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<StudySessionProvider>(
      builder: (context, studyProvider, child) {
        if (studyProvider.currentFlashcard == null) {
          return LoadingScreen();
        }
        
        return FlashcardViewer(
          flashcard: studyProvider.currentFlashcard!,
          onRating: (rating) => studyProvider.submitRating(rating),
        );
      },
    );
  }
}
```

#### Provider Dependencies
```dart
class StudySessionProvider extends ChangeNotifier {
  final FlashcardRepository _flashcardRepo;
  final SpacedRepetitionService _spacedRepetition;
  final StudySessionRepository _sessionRepo;
  
  StudySessionProvider({
    required FlashcardRepository flashcardRepository,
    required SpacedRepetitionService spacedRepetitionService,
    required StudySessionRepository sessionRepository,
  }) : _flashcardRepo = flashcardRepository,
       _spacedRepetition = spacedRepetitionService,
       _sessionRepo = sessionRepository;
}
```

## Critical Implementation Paths

### 1. App Startup Sequence
```
1. Initialize SQLite database
2. Check for schema migrations
3. Initialize Supabase connection
4. Load cached flashcards from local DB
5. Start background sync process
6. Navigate to appropriate screen
```

### 2. Study Session Lifecycle
```
1. Query due flashcards from local DB
2. Apply spaced repetition algorithm for ordering
3. Present flashcard to user
4. Capture user rating and time spent
5. Calculate next review date using SuperMemo 2
6. Update local progress immediately
7. Queue progress for cloud sync
8. Load next flashcard
```

### 3. Data Synchronization Process
```
1. Background timer triggers sync check
2. Upload any unsynced local changes
3. Download remote changes since last sync
4. Apply conflict resolution rules
5. Update local database with merged data
6. Notify UI providers of data changes
```

## Error Handling Patterns

### 1. Network Failure Handling
```dart
class ResilientSupabaseService {
  Future<T> withRetry<T>(Future<T> Function() operation) async {
    int attempts = 0;
    const maxAttempts = 3;
    
    while (attempts < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) rethrow;
        
        await Future.delayed(Duration(seconds: 2 * attempts));
      }
    }
    
    throw Exception('Operation failed after $maxAttempts attempts');
  }
}
```

### 2. Data Consistency Patterns
```dart
class TransactionalRepository {
  Future<void> updateProgressWithTransaction(StudySession session) async {
    await _localDb.transaction((txn) async {
      // Update flashcard progress
      await txn.update('user_flashcard_progress', {
        'ease_factor': session.newEaseFactor,
        'interval_days': session.newInterval,
        'next_review_date': session.nextReviewDate.toIso8601String(),
        'review_count': session.reviewCount + 1,
        'last_reviewed_at': DateTime.now().toIso8601String(),
      }, where: 'flashcard_id = ?', whereArgs: [session.flashcardId]);
      
      // Insert study session record
      await txn.insert('study_sessions', session.toMap());
    });
  }
}
```

## Performance Optimization Patterns

### 1. Lazy Loading Pattern
```dart
class FlashcardProvider extends ChangeNotifier {
  final Map<String, Flashcard> _flashcardCache = {};
  
  Future<Flashcard> getFlashcard(String id) async {
    if (_flashcardCache.containsKey(id)) {
      return _flashcardCache[id]!;
    }
    
    final flashcard = await _repository.getFlashcardById(id);
    _flashcardCache[id] = flashcard;
    return flashcard;
  }
}
```

### 2. Batch Operations Pattern
```dart
class BatchSyncService {
  Future<void> batchUploadSessions() async {
    const batchSize = 50;
    final sessions = await _localDb.getUnsyncedStudySessions();
    
    for (int i = 0; i < sessions.length; i += batchSize) {
      final batch = sessions.sublist(
        i, 
        math.min(i + batchSize, sessions.length)
      );
      
      await _cloudDb.batchInsertStudySessions(batch);
      
      // Mark as synced
      await _localDb.markSessionsAsSynced(
        batch.map((s) => s.id).toList()
      );
    }
  }
}
```

## Security Patterns

### 1. Data Validation Pattern
```dart
class SecureFlashcardService {
  Future<void> updateProgress(StudySession session) async {
    // Validate input
    if (session.difficultyRating < 1 || session.difficultyRating > 4) {
      throw ArgumentError('Invalid difficulty rating');
    }
    
    if (session.timeSpentSeconds < 0) {
      throw ArgumentError('Invalid time spent');
    }
    
    // Sanitize before storage
    final sanitizedSession = session.copyWith(
      timeSpentSeconds: math.min(session.timeSpentSeconds, 3600), // Max 1 hour
    );
    
    await _repository.updateProgress(sanitizedSession);
  }
}
```

### 2. Authentication Context Pattern
```dart
class AuthenticatedService {
  final SupabaseClient _supabase;
  
  Future<String?> get currentUserId async {
    final user = _supabase.auth.currentUser;
    return user?.id;
  }
  
  Future<List<StudySession>> getUserStudySessions() async {
    final userId = await currentUserId;
    if (userId == null) {
      throw UnauthorizedException('User not authenticated');
    }
    
    return await _supabase
        .from('study_sessions')
        .select()
        .eq('user_id', userId);
  }
}
```

These patterns form the backbone of the application architecture, ensuring scalability, maintainability, and robust offline-first functionality.
