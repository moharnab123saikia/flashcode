import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/flashcard_provider.dart';
import '../../providers/study_session_provider.dart';
import '../../models/flashcard.dart';
import '../../models/study_session.dart';
import '../../models/difficulty.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: colorScheme.surface,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Your Progress',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              ),
            ),
            
            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Overall Statistics
                  _buildOverallStats(context),
                  const SizedBox(height: 24),
                  
                  // Study Streak
                  _buildStudyStreak(context),
                  const SizedBox(height: 24),
                  
                  // Weekly Progress Chart
                  _buildWeeklyProgress(context),
                  const SizedBox(height: 24),
                  
                  // Category Progress
                  _buildCategoryProgress(context),
                  const SizedBox(height: 24),
                  
                  // Difficulty Distribution
                  _buildDifficultyDistribution(context),
                  const SizedBox(height: 24),
                  
                  // Recent Sessions
                  _buildRecentSessions(context),
                  const SizedBox(height: 80), // Bottom padding for FAB
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStats(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final flashcardProvider = context.watch<FlashcardProvider>();
    final sessionProvider = context.watch<StudySessionProvider>();
    
    final totalProblems = flashcardProvider.flashcards.length;
    final masteredCount = flashcardProvider.flashcards
        .where((card) => card.personalDifficulty == Difficulty.easy)
        .length;
    final inProgressCount = flashcardProvider.flashcards
        .where((card) => card.reviewCount > 0 && card.personalDifficulty != Difficulty.easy)
        .length;
    final notStartedCount = flashcardProvider.flashcards
        .where((card) => card.reviewCount == 0)
        .length;
    
    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Progress',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: totalProblems > 0 ? masteredCount / totalProblems : 0,
                minHeight: 20,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(masteredCount / totalProblems * 100).toStringAsFixed(1)}% Complete',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            
            // Stats Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  'Mastered',
                  masteredCount.toString(),
                  Colors.green,
                ),
                _buildStatItem(
                  context,
                  'In Progress',
                  inProgressCount.toString(),
                  Colors.orange,
                ),
                _buildStatItem(
                  context,
                  'Not Started',
                  notStartedCount.toString(),
                  Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildStudyStreak(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sessionProvider = context.watch<StudySessionProvider>();
    
    final currentStreak = sessionProvider.currentStreak;
    final longestStreak = sessionProvider.longestStreak;
    
    return Card(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department,
              size: 48,
              color: currentStreak > 0 ? Colors.orange : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Study Streak',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$currentStreak ${currentStreak == 1 ? 'day' : 'days'}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Longest: $longestStreak days',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSecondaryContainer.withOpacity(0.7),
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

  Widget _buildWeeklyProgress(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Mock data for weekly progress
    final weeklyData = [
      ('Mon', 5),
      ('Tue', 8),
      ('Wed', 3),
      ('Thu', 12),
      ('Fri', 7),
      ('Sat', 15),
      ('Sun', 10),
    ];
    
    return Card(
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Week',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 20,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => colorScheme.inverseSurface,
                      tooltipPadding: const EdgeInsets.all(8),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${weeklyData[group.x.toInt()].$1}\n${rod.toY.toInt()} problems',
                          TextStyle(
                            color: colorScheme.onInverseSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < weeklyData.length) {
                            return Text(
                              weeklyData[value.toInt()].$1,
                              style: theme.textTheme.bodySmall,
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: weeklyData.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.$2.toDouble(),
                          color: colorScheme.primary,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryProgress(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final flashcardProvider = context.watch<FlashcardProvider>();
    
    // Calculate progress by category
    final categoryProgress = <String, Map<String, int>>{};
    for (final card in flashcardProvider.flashcards) {
      final category = card.dataStructureCategory;
      categoryProgress[category] ??= {'total': 0, 'mastered': 0};
      categoryProgress[category]!['total'] = categoryProgress[category]!['total']! + 1;
      if (card.personalDifficulty == Difficulty.easy) {
        categoryProgress[category]!['mastered'] = categoryProgress[category]!['mastered']! + 1;
      }
    }
    
    return Card(
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress by Category',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...categoryProgress.entries.map((entry) {
              final progress = entry.value['mastered']! / entry.value['total']!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          '${entry.value['mastered']}/${entry.value['total']}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCategoryColor(entry.key, colorScheme),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category, ColorScheme colorScheme) {
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    final index = category.hashCode.abs() % colors.length;
    return colors[index];
  }

  Widget _buildDifficultyDistribution(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final flashcardProvider = context.watch<FlashcardProvider>();
    
    // Calculate difficulty distribution
    final easyCount = flashcardProvider.flashcards
        .where((card) => card.predefinedDifficulty == 'Easy')
        .length;
    final mediumCount = flashcardProvider.flashcards
        .where((card) => card.predefinedDifficulty == 'Medium')
        .length;
    final hardCount = flashcardProvider.flashcards
        .where((card) => card.predefinedDifficulty == 'Hard')
        .length;
    
    final total = easyCount + mediumCount + hardCount;
    
    return Card(
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Difficulty Distribution',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: Colors.green,
                      value: easyCount.toDouble(),
                      title: '${(easyCount / total * 100).toStringAsFixed(0)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.orange,
                      value: mediumCount.toDouble(),
                      title: '${(mediumCount / total * 100).toStringAsFixed(0)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.red,
                      value: hardCount.toDouble(),
                      title: '${(hardCount / total * 100).toStringAsFixed(0)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('Easy', Colors.green, easyCount),
                _buildLegendItem('Medium', Colors.orange, mediumCount),
                _buildLegendItem('Hard', Colors.red, hardCount),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text('$label ($count)'),
      ],
    );
  }

  Widget _buildRecentSessions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sessionProvider = context.watch<StudySessionProvider>();
    
    final recentSessions = sessionProvider.sessions.take(5).toList();
    
    return Card(
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Study Sessions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (recentSessions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No study sessions yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...recentSessions.map((session) {
                final duration = session.completedAt?.difference(session.startedAt);
                final durationText = duration != null
                    ? '${duration.inMinutes} min'
                    : 'In progress';
                
                // Calculate correct count from results
                final correctCount = session.results.values
                    .where((result) => result.rating >= 3)
                    .length;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      correctCount.toString(),
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    '$correctCount/${session.totalCards} correct',
                    style: theme.textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    _formatDate(session.startedAt),
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: Text(
                    durationText,
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
