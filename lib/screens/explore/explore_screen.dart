import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import '../../data/code_templates.dart';
import '../../models/flashcard.dart';
import '../../data/grind75_questions.dart';
import 'dart:math' as math;

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String selectedLanguage = 'python';
  String? expandedCategory;
  
  final List<String> languages = ['python', 'javascript', 'java'];
  final Map<String, IconData> languageIcons = {
    'python': Icons.code,
    'javascript': Icons.javascript,
    'java': Icons.coffee,
  };

  final Map<String, IconData> categoryIcons = {
    'Two Pointers': Icons.compare_arrows,
    'Sliding Window': Icons.view_carousel,
    'Arrays': Icons.apps,
    'Strings': Icons.text_fields,
    'Linked Lists': Icons.link,
    'Stacks': Icons.layers,
    'Trees': Icons.account_tree,
    'Graphs': Icons.hub,
    'Heaps': Icons.vertical_align_top,
    'Binary Search': Icons.search,
    'Backtracking': Icons.undo,
    'Dynamic Programming': Icons.trending_up,
    'Tries': Icons.segment,
  };

  Flashcard? _getProblemOfTheDay() {
    final allQuestions = grind75Questions;
    if (allQuestions.isEmpty) return null;
    
    // Use date as seed for consistent daily problem
    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    final random = math.Random(seed);
    return allQuestions[random.nextInt(allQuestions.length)];
  }

  List<Flashcard> _getRecommendedProblems() {
    // For now, return random easy/medium problems
    final problems = grind75Questions
        .where((q) => q.predefinedDifficulty != 'Hard')
        .toList();
    problems.shuffle();
    return problems.take(4).toList();
  }

  void _copyToClipboard(String code, String title) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $title to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final problemOfDay = _getProblemOfTheDay();
    final recommendedProblems = _getRecommendedProblems();
    final categories = CodeTemplates.getCategories();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Problem of the Day
          if (problemOfDay != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.today_rounded,
                          color: theme.colorScheme.onPrimary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Problem of the Day',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      problemOfDay.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _buildDifficultyChip(
                              problemOfDay.predefinedDifficulty,
                              onPrimary: true,
                            ),
                            const SizedBox(width: 8),
                            _buildCategoryChip(
                              problemOfDay.dataStructureCategory,
                              onPrimary: true,
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.arrow_forward_rounded,
                            color: theme.colorScheme.onPrimary,
                          ),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/study',
                              arguments: {
                                'initialCards': [problemOfDay],
                                'mode': 'single',
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Code Templates Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Code Templates & Patterns',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Language selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: DropdownButton<String>(
                      value: selectedLanguage,
                      underline: const SizedBox(),
                      isDense: true,
                      borderRadius: BorderRadius.circular(12),
                      items: languages.map((lang) {
                        return DropdownMenuItem(
                          value: lang,
                          child: Row(
                            children: [
                              Icon(
                                languageIcons[lang],
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                lang[0].toUpperCase() + lang.substring(1),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedLanguage = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Code Templates Categories
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = categories[index];
                  final templates = CodeTemplates.getByCategory(category);
                  final isExpanded = expandedCategory == category;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: isExpanded ? 2 : 0,
                    color: isExpanded
                        ? theme.colorScheme.surfaceContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        leading: Icon(
                          categoryIcons[category] ?? Icons.code,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          category,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${templates.length} templates',
                          style: theme.textTheme.bodySmall,
                        ),
                        onExpansionChanged: (expanded) {
                          setState(() {
                            expandedCategory = expanded ? category : null;
                          });
                        },
                        children: templates.map((template) {
                          final code = template.code[selectedLanguage] ?? 
                                       template.code['python'] ?? 
                                       '';
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Template Header
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              template.title,
                                              style: theme.textTheme.bodyLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.copy, size: 20),
                                            onPressed: () => _copyToClipboard(
                                              code,
                                              template.title,
                                            ),
                                            tooltip: 'Copy code',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        template.description,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.lightbulb_outline,
                                            size: 16,
                                            color: theme.colorScheme.secondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              template.useCase,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.secondary,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Code Display
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E1E), // VS Code dark background
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                    border: Border.all(color: Colors.grey[700]!),
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: HighlightView(
                                      code,
                                      language: selectedLanguage,
                                      theme: vs2015Theme,
                                      padding: const EdgeInsets.all(16),
                                      textStyle: const TextStyle(
                                        fontFamily: 'Consolas, Monaco, monospace',
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Related Problems
                                if (template.relatedProblems.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        Text(
                                          'Try on:',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        ...template.relatedProblems.map((problem) {
                                          return Chip(
                                            label: Text(
                                              problem,
                                              style: theme.textTheme.labelSmall,
                                            ),
                                            backgroundColor: theme.colorScheme.secondaryContainer,
                                            side: BorderSide.none,
                                            visualDensity: VisualDensity.compact,
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
                childCount: categories.length,
              ),
            ),
          ),

          // Recommended Problems Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Text(
                    'Recommended for You',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recommendedProblems.length,
                    itemBuilder: (context, index) {
                      final problem = recommendedProblems[index];
                      return Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 12),
                        child: Card(
                          elevation: 0,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/study',
                                arguments: {
                                  'initialCards': [problem],
                                  'mode': 'single',
                                },
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    problem.title,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    children: [
                                      _buildDifficultyChip(problem.predefinedDifficulty),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          problem.dataStructureCategory,
                                          style: theme.textTheme.bodySmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Topics to Master Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Text(
                    'Topics to Master',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: 6, // Show first 6 categories
                    itemBuilder: (context, index) {
                      final topics = [
                        'Arrays', 'Trees', 'Dynamic Programming',
                        'Graphs', 'Linked Lists', 'Binary Search'
                      ];
                      final topic = topics[index];
                      final problemCount = grind75Questions
                          .where((q) => q.dataStructureCategory == topic)
                          .length;

                      return Card(
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: InkWell(
                          onTap: () {
                            // Navigate to topic
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  categoryIcons[topic] ?? Icons.category,
                                  color: theme.colorScheme.primary,
                                  size: 28,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      topic,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '$problemCount problems',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(String difficulty, {bool onPrimary = false}) {
    final theme = Theme.of(context);
    final difficultyColors = {
      'Easy': Colors.green,
      'Medium': Colors.orange,
      'Hard': Colors.red,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: onPrimary
            ? theme.colorScheme.onPrimary.withOpacity(0.2)
            : difficultyColors[difficulty]?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: onPrimary
              ? theme.colorScheme.onPrimary
              : difficultyColors[difficulty],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, {bool onPrimary = false}) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: onPrimary
            ? theme.colorScheme.onPrimary.withOpacity(0.2)
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: onPrimary
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
