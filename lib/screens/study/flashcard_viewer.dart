import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:provider/provider.dart';
import '../../models/flashcard.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/study_session_provider.dart';
import '../../utils/theme.dart';
import '../../utils/spaced_repetition.dart';

class FlashcardViewer extends StatefulWidget {
  final Flashcard flashcard;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final bool canGoNext;
  final bool canGoPrevious;

  const FlashcardViewer({
    super.key,
    required this.flashcard,
    required this.onNext,
    required this.onPrevious,
    required this.canGoNext,
    required this.canGoPrevious,
  });

  @override
  State<FlashcardViewer> createState() => _FlashcardViewerState();
}

class _FlashcardViewerState extends State<FlashcardViewer> {
  final GlobalKey<FlipCardState> _flipKey = GlobalKey<FlipCardState>();
  String _selectedLanguage = 'python';
  int? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    // Set default language to first available solution
    if (widget.flashcard.solutions.isNotEmpty) {
      _selectedLanguage = widget.flashcard.solutions.keys.first;
    }
  }

  @override
  void didUpdateWidget(covariant FlashcardViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flashcard.id != widget.flashcard.id) {
      setState(() {
        _selectedDifficulty = null;
        if (widget.flashcard.solutions.isNotEmpty) {
          _selectedLanguage = widget.flashcard.solutions.keys.first;
        }
      });
    }
  }

  void _handleReview(int quality) async {
    final provider = Provider.of<FlashcardProvider>(context, listen: false);
    final studyProvider = Provider.of<StudySessionProvider>(context, listen: false);
    
    // Update the card with spaced repetition
    final updatedCard = SpacedRepetition.calculateNextReview(widget.flashcard, quality);
    
    // Save to database (async)
    await provider.updateFlashcard(updatedCard);
    
    // Record in study session if there's an active session
    if (studyProvider.hasActiveSession) {
      studyProvider.recordCardResult(
        cardId: updatedCard.id,
        rating: quality,
        timeSpent: 30, // You might want to track actual time spent
        hintUsed: false, // Track if hint was viewed
        solutionViewed: true, // Assuming solution was viewed if rating
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Flashcard
          Expanded(
            child: FlipCard(
              key: _flipKey,
              direction: FlipDirection.HORIZONTAL,
              front: _buildQuestionSide(),
              back: _buildSolutionSide(),
            ),
          ),
          const SizedBox(height: 16),
          // Navigation and rating buttons
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildQuestionSide() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with problem info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.getDifficultyColor(
                    widget.flashcard.predefinedDifficulty,
                  ),
                  child: Text(
                    widget.flashcard.leetcodeNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.flashcard.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.flashcard.predefinedDifficulty} • ${widget.flashcard.dataStructureCategory}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Question content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Problem:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.flashcard.question,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    if (widget.flashcard.hint.isNotEmpty) ...[
                      Text(
                        'Hint:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.warningColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.warningColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          widget.flashcard.hint,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Flip instruction
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tap to flip and see solution',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionSide() {
    final solution = widget.flashcard.solutions[_selectedLanguage];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Solution',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
                const Spacer(),
                // Language selector
                if (widget.flashcard.solutions.length > 1)
                  DropdownButton<String>(
                    value: _selectedLanguage,
                    items: widget.flashcard.solutions.keys.map((lang) {
                      return DropdownMenuItem(
                        value: lang,
                        child: Text(lang.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedLanguage = value;
                        });
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Solution content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (solution != null) ...[
                      // Approach
                      Text(
                        'Approach: ${solution.approach}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Complexity
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Time: ${solution.timeComplexity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Space: ${solution.spaceComplexity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Code
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: HighlightView(
                          solution.code,
                          language: _selectedLanguage,
                          theme: githubTheme,
                          padding: const EdgeInsets.all(16),
                          textStyle: AppTheme.codeStyle,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Key points
                      if (solution.keyPoints.isNotEmpty) ...[
                        Text(
                          'Key Points:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...solution.keyPoints.map((point) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  point,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ] else ...[
                      const Center(
                        child: Text(
                          'No solution available for this language',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Column(
      children: [
        // Difficulty rating
        Text(
          'How difficult was this problem for you?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDifficultyButton(1, 'Again', AppTheme.errorColor),
            _buildDifficultyButton(2, 'Hard', AppTheme.warningColor),
            _buildDifficultyButton(3, 'Good', AppTheme.primaryColor),
            _buildDifficultyButton(4, 'Easy', AppTheme.successColor),
          ],
        ),
        const SizedBox(height: 16),
        // Navigation buttons
        Row(
          children: [
            if (widget.canGoPrevious)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onPrevious,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                ),
              ),
            if (widget.canGoPrevious && widget.canGoNext)
              const SizedBox(width: 16),
            if (widget.canGoNext)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectedDifficulty != null ? widget.onNext : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                ),
              ),
            if (!widget.canGoNext)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectedDifficulty != null ? widget.onNext : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Complete'),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyButton(int rating, String label, Color color) {
    final isSelected = _selectedDifficulty == rating;
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedDifficulty = rating;
            });
            _handleReview(rating);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? color : Colors.grey[200],
            foregroundColor: isSelected ? Colors.white : Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rating.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
