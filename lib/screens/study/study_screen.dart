import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/flashcard.dart';
import '../../providers/flashcard_provider_v2.dart';
import '../../providers/study_session_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import 'flashcard_viewer.dart';

class StudyScreen extends StatefulWidget {
  final List<Flashcard>? initialCards;
  final String mode;

  const StudyScreen({
    super.key,
    this.initialCards,
    this.mode = 'review',
  });

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  late List<Flashcard> _cards;
  int _currentIndex = 0;
  bool _isLoading = true;
  DateTime? _sessionStartTime;
  DateTime? _cardStartTime;
  Duration _timeLimit = const Duration(minutes: 5); // 5 minutes per card for timed mode
  Duration _remainingTime = const Duration(minutes: 5);
  bool _isTimedMode = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  void _loadCards() {
    if (widget.initialCards != null) {
      _cards = widget.initialCards!;
      setState(() {
        _isLoading = false;
      });
      _startSession();
    } else {
      // Delay to ensure context is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final flashcardProvider = context.read<FlashcardProviderV2>();
        
        switch (widget.mode) {
          case 'review':
            // Convert FlashcardWithProgress to Flashcard
            _cards = flashcardProvider.getCardsForReview().map((card) => Flashcard(
              id: card.id,
              title: card.title,
              question: card.question,
              hint: card.hint,
              solutions: card.solutions.map((key, value) => MapEntry(key, 
                CodeSolution.fromJson(value as Map<String, dynamic>))),
              dataStructureCategory: card.dataStructureCategory,
              algorithmPattern: card.algorithmPattern,
              predefinedDifficulty: card.predefinedDifficulty,
              leetcodeNumber: card.leetcodeNumber,
              tags: card.tags,
              companies: card.companies,
              personalDifficulty: card.personalDifficulty,
              reviewCount: card.reviewCount,
              easeFactor: card.easeFactor,
              interval: card.intervalDays,
              nextReview: card.nextReview,
              lastReviewedAt: card.lastReviewedAt,
              createdAt: card.createdAt,
            )).toList();
            break;
          case 'grind75':
            // Convert FlashcardWithProgress to Flashcard - show all cards in sequential order
            _cards = flashcardProvider.flashcards.map((card) => Flashcard(
              id: card.id,
              title: card.title,
              question: card.question,
              hint: card.hint,
              solutions: card.solutions.map((key, value) => MapEntry(key,
                CodeSolution.fromJson(value as Map<String, dynamic>))),
              dataStructureCategory: card.dataStructureCategory,
              algorithmPattern: card.algorithmPattern,
              predefinedDifficulty: card.predefinedDifficulty,
              leetcodeNumber: card.leetcodeNumber,
              tags: card.tags,
              companies: card.companies,
              personalDifficulty: card.personalDifficulty,
              reviewCount: card.reviewCount,
              easeFactor: card.easeFactor,
              interval: card.intervalDays,
              nextReview: card.nextReview,
              lastReviewedAt: card.lastReviewedAt,
              createdAt: card.createdAt,
            )).toList();
            break;
          case 'category':
            // Show category selection dialog
            _showCategorySelection(context, flashcardProvider);
            return;
          case 'timed':
            // Get random cards for timed challenge
            final allCards = flashcardProvider.flashcards.map((card) => Flashcard(
              id: card.id,
              title: card.title,
              question: card.question,
              hint: card.hint,
              solutions: card.solutions.map((key, value) => MapEntry(key,
                CodeSolution.fromJson(value as Map<String, dynamic>))),
              dataStructureCategory: card.dataStructureCategory,
              algorithmPattern: card.algorithmPattern,
              predefinedDifficulty: card.predefinedDifficulty,
              leetcodeNumber: card.leetcodeNumber,
              tags: card.tags,
              companies: card.companies,
              personalDifficulty: card.personalDifficulty,
              reviewCount: card.reviewCount,
              easeFactor: card.easeFactor,
              interval: card.intervalDays,
              nextReview: card.nextReview,
              lastReviewedAt: card.lastReviewedAt,
              createdAt: card.createdAt,
            )).toList();
            allCards.shuffle();
            _cards = allCards.take(5).toList(); // 5 cards for timed challenge
            break;
          case 'random':
            final allCards = flashcardProvider.flashcards.map((card) => Flashcard(
              id: card.id,
              title: card.title,
              question: card.question,
              hint: card.hint,
              solutions: card.solutions.map((key, value) => MapEntry(key, 
                CodeSolution.fromJson(value as Map<String, dynamic>))),
              dataStructureCategory: card.dataStructureCategory,
              algorithmPattern: card.algorithmPattern,
              predefinedDifficulty: card.predefinedDifficulty,
              leetcodeNumber: card.leetcodeNumber,
              tags: card.tags,
              companies: card.companies,
              personalDifficulty: card.personalDifficulty,
              reviewCount: card.reviewCount,
              easeFactor: card.easeFactor,
              interval: card.intervalDays,
              nextReview: card.nextReview,
              lastReviewedAt: card.lastReviewedAt,
              createdAt: card.createdAt,
            )).toList();
            allCards.shuffle();
            _cards = allCards.take(10).toList(); // Random 10 cards
            break;
          default:
            _cards = flashcardProvider.flashcards.map((card) => Flashcard(
              id: card.id,
              title: card.title,
              question: card.question,
              hint: card.hint,
              solutions: card.solutions.map((key, value) => MapEntry(key, 
                CodeSolution.fromJson(value as Map<String, dynamic>))),
              dataStructureCategory: card.dataStructureCategory,
              algorithmPattern: card.algorithmPattern,
              predefinedDifficulty: card.predefinedDifficulty,
              leetcodeNumber: card.leetcodeNumber,
              tags: card.tags,
              companies: card.companies,
              personalDifficulty: card.personalDifficulty,
              reviewCount: card.reviewCount,
              easeFactor: card.easeFactor,
              interval: card.intervalDays,
              nextReview: card.nextReview,
              lastReviewedAt: card.lastReviewedAt,
              createdAt: card.createdAt,
            )).toList();
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
            _isTimedMode = widget.mode == 'timed';
          });
          _startSession();
        }
      });
    }
  }

  void _startSession() {
    if (_cards.isNotEmpty) {
      _sessionStartTime = DateTime.now();
      final sessionProvider = context.read<StudySessionProvider>();
      final authProvider = context.read<AuthProvider>();
      
      if (authProvider.currentUser != null) {
        sessionProvider.startSession(
          userId: authProvider.currentUser!.id,
          cards: _cards,
          mode: widget.mode,
        );
      }
      
      // Start timer for first card if in timed mode
      if (_isTimedMode) {
        _startCardTimer();
      }
    }
  }

  void _nextCard() {
    _stopTimer();
    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
      });
      if (_isTimedMode) {
        _startCardTimer();
      }
    } else {
      _showSessionComplete();
    }
  }

  void _startCardTimer() {
    if (!_isTimedMode) return;
    
    _cardStartTime = DateTime.now();
    _remainingTime = _timeLimit;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingTime = _timeLimit - DateTime.now().difference(_cardStartTime!);
          if (_remainingTime.inSeconds <= 0) {
            _remainingTime = Duration.zero;
            _handleTimeUp();
          }
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _handleTimeUp() {
    _stopTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Time\'s up! Moving to next card.'),
        backgroundColor: Colors.orange,
      ),
    );
    // Auto-advance to next card
    _nextCard();
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _showSessionComplete() async {
    // Complete the session
    final sessionProvider = context.read<StudySessionProvider>();
    if (sessionProvider.hasActiveSession) {
      await sessionProvider.completeSession();
    }

    if (!mounted) return;

    // Calculate session stats
    final duration = _sessionStartTime != null 
        ? DateTime.now().difference(_sessionStartTime!)
        : Duration.zero;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.celebration,
          color: AppTheme.successColor,
          size: 48,
        ),
        title: const Text('Session Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.quiz, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text('Problems studied: ${_cards.length}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.timer, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text('Time spent: $minutes min $seconds sec'),
                    ],
                  ),
                  if (sessionProvider.sessions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department, color: AppTheme.warningColor, size: 20),
                        const SizedBox(width: 8),
                        Text('Current streak: ${sessionProvider.currentStreak} days'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Great job! Your progress has been saved.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              setState(() {
                _currentIndex = 0; // Restart session
              });
              _startSession(); // Start new session
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Study Again'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to home
            },
            icon: const Icon(Icons.home),
            label: const Text('Return Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showCategorySelection(BuildContext context, FlashcardProviderV2 flashcardProvider) {
    final categories = flashcardProvider.flashcards
        .map((card) => card.dataStructureCategory)
        .toSet()
        .toList()
        ..sort();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Category'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final categoryCards = flashcardProvider.flashcards
                  .where((card) => card.dataStructureCategory == category)
                  .length;
              
              return ListTile(
                title: Text(category),
                subtitle: Text('$categoryCards cards'),
                onTap: () {
                  Navigator.of(context).pop();
                  _loadCategoryCards(flashcardProvider, category);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Go back to home screen if user cancels category selection
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    ).then((_) {
      // If dialog is dismissed without selection (e.g., back button), go back to home
      if (mounted && _isLoading) {
        Navigator.of(context).pop();
      }
    });
  }

  void _loadCategoryCards(FlashcardProviderV2 flashcardProvider, String category) {
    _cards = flashcardProvider.flashcards
        .where((card) => card.dataStructureCategory == category)
        .map((card) => Flashcard(
          id: card.id,
          title: card.title,
          question: card.question,
          hint: card.hint,
          solutions: card.solutions.map((key, value) => MapEntry(key,
            CodeSolution.fromJson(value as Map<String, dynamic>))),
          dataStructureCategory: card.dataStructureCategory,
          algorithmPattern: card.algorithmPattern,
          predefinedDifficulty: card.predefinedDifficulty,
          leetcodeNumber: card.leetcodeNumber,
          tags: card.tags,
          companies: card.companies,
          personalDifficulty: card.personalDifficulty,
          reviewCount: card.reviewCount,
          easeFactor: card.easeFactor,
          interval: card.intervalDays,
          nextReview: card.nextReview,
          lastReviewedAt: card.lastReviewedAt,
          createdAt: card.createdAt,
        )).toList();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _startSession();
    }
  }

  String _getModeDisplayName(String mode) {
    switch (mode) {
      case 'grind75':
        return 'Sequential Study';
      case 'review':
        return 'Review';
      case 'random':
        return 'Random';
      case 'timed':
        return 'Timed Challenge';
      case 'category':
        return 'Category';
      default:
        return mode.toUpperCase();
    }
  }

  @override
  void dispose() {
    // Clean up timer
    _stopTimer();
    
    // Complete session if still active when leaving screen
    // Use try-catch to handle cases where context is no longer available
    try {
      final sessionProvider = context.read<StudySessionProvider>();
      if (sessionProvider.hasActiveSession) {
        sessionProvider.completeSession();
      }
    } catch (e) {
      // Context is no longer available, which is fine during disposal
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Study Session'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No cards available for study',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Try a different study mode or add more cards',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final currentCard = _cards[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('${_getModeDisplayName(widget.mode)} Mode'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_currentIndex + 1}/${_cards.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator and timer
          Column(
            children: [
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _cards.length,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
              if (_isTimedMode) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: _remainingTime.inSeconds <= 30
                      ? Colors.red.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer,
                        color: _remainingTime.inSeconds <= 30 ? Colors.red : Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Time remaining: ${_remainingTime.inMinutes}:${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: _remainingTime.inSeconds <= 30 ? Colors.red : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          // Flashcard viewer
          Expanded(
            child: FlashcardViewer(
              key: ValueKey(currentCard.id),
              flashcard: currentCard,
              onNext: _nextCard,
              onPrevious: _previousCard,
              canGoNext: _currentIndex < _cards.length - 1,
              canGoPrevious: _currentIndex > 0,
            ),
          ),
        ],
      ),
    );
  }
}
