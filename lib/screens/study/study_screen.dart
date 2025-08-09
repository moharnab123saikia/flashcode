import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/flashcard.dart';
import '../../providers/flashcard_provider.dart';
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
    } else {
      // Delay to ensure context is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final flashcardProvider = context.read<FlashcardProvider>();
        
        switch (widget.mode) {
          case 'review':
            _cards = flashcardProvider.getCardsForReview();
            break;
          case 'grind75':
            _cards = flashcardProvider.flashcards; // Get all cards for now
            break;
          case 'random':
            _cards = List.from(flashcardProvider.flashcards)..shuffle();
            _cards = _cards.take(10).toList(); // Random 10 cards
            break;
          default:
            _cards = flashcardProvider.flashcards;
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  void _nextCard() {
    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _showSessionComplete();
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _showSessionComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Complete!'),
        content: Text('You\'ve completed ${_cards.length} flashcards.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to home
            },
            child: const Text('Done'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              setState(() {
                _currentIndex = 0; // Restart session
              });
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
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
        title: Text('${widget.mode.toUpperCase()} Mode'),
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
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _cards.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.primaryColor,
            ),
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
