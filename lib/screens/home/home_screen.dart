import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/flashcard_provider_v2.dart';
import '../../providers/study_session_provider.dart';
import '../../models/study_session.dart';
import '../../models/flashcard.dart';
import '../../utils/theme.dart';
import '../study/study_screen.dart';
import '../profile/profile_screen.dart';
import '../explore/explore_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize sample data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // V2 system initializes automatically when user is authenticated
    });
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await context.read<AuthProvider>().signOut();
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlashCode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  _navigateToProfile(context);
                  break;
                case 'logout':
                  _handleLogout(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout),
                    const SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          DashboardView(),
          StudyModesView(),
          ExploreScreen(),
          LibraryView(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.school),
            label: 'Study',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books),
            label: 'Library',
          ),
        ],
      ),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final flashcardProvider = context.watch<FlashcardProviderV2>();
    final studySessionProvider = context.watch<StudySessionProvider>();
    final user = authProvider.currentUser;

    if (user == null || flashcardProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = flashcardProvider.getBasicStatistics();
    final sessionStats = studySessionProvider.getSessionStatistics();
    final cardsForReview = flashcardProvider.getCardsForReview();
    final totalCards = flashcardProvider.flashcards.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${user.displayName ?? 'User'}!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.local_fire_department,
                          color: AppTheme.warningColor),
                      const SizedBox(width: 8),
                      Text('${studySessionProvider.currentStreak} day streak'),
                      const SizedBox(width: 16),
                      const Icon(Icons.star, color: AppTheme.successColor),
                      const SizedBox(width: 8),
                      Text('${stats['reviewedCards']}/$totalCards completed'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickActionCard(
                  context,
                  'Review\n${cardsForReview.length} cards',
                  Icons.refresh,
                  AppTheme.primaryColor,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudyScreen(mode: 'review'),
                      ),
                    );
                  },
                ),
                _buildQuickActionCard(
                  context,
                  'Sequential\nStudy',
                  Icons.play_arrow,
                  AppTheme.successColor,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudyScreen(mode: 'grind75'),
                      ),
                    );
                  },
                ),
                _buildQuickActionCard(
                  context,
                  'Random\nPractice',
                  Icons.shuffle,
                  AppTheme.warningColor,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudyScreen(mode: 'random'),
                      ),
                    );
                  },
                ),
                _buildQuickActionCard(
                  context,
                  'Timed\nChallenge',
                  Icons.timer,
                  AppTheme.errorColor,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudyScreen(mode: 'timed'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Statistics
          Text(
            'Your Progress',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatRow('Total Cards', '${stats['totalCards']}'),
                  const Divider(),
                  _buildStatRow('Cards Reviewed', '${stats['reviewedCards']}'),
                  const Divider(),
                  _buildStatRow('Cards Mastered', '${stats['masteredCards']}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Category Progress
          Text(
            'Category Progress',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: ((stats['categoryStats'] as Map<String, int>)
                    .entries
                    .toList()
                      ..sort((a, b) => b.value.compareTo(a.value)))
                    .take(5)
                    .map((entry) {
                      // Calculate category progress from flashcard data
                      final categoryCards = flashcardProvider.flashcards
                          .where((card) => card.dataStructureCategory == entry.key)
                          .toList();
                      final completedInCategory = categoryCards
                          .where((card) => card.reviewCount > 0)
                          .length;
                      final mastery = categoryCards.isNotEmpty 
                          ? completedInCategory / categoryCards.length
                          : 0.0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: _buildCategoryProgress(
                          entry.key,
                          completedInCategory,
                          mastery,
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: 140,
      child: ElevatedButton(
        onPressed: () {
          debugPrint('QuickAction tapped: $title');
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening $title')),
          );
          onTap();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryProgress(String category, int completed, double mastery) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(category),
            Text('$completed solved'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: mastery,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            mastery > 0.7
                ? AppTheme.successColor
                : mastery > 0.4
                    ? AppTheme.warningColor
                    : AppTheme.errorColor,
          ),
        ),
      ],
    );
  }
}

class StudyModesView extends StatelessWidget {
  const StudyModesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: StudyMode.values.map((mode) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Text(
              mode.icon,
              style: const TextStyle(fontSize: 32),
            ),
            title: Text(mode.displayName),
            subtitle: Text(mode.description),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              String modeStr;
              switch (mode) {
                case StudyMode.spacedRepetition:
                  modeStr = 'review';
                  break;
                case StudyMode.sequential:
                  modeStr = 'grind75';
                  break;
                case StudyMode.category:
                  modeStr = 'category';
                  break;
                case StudyMode.random:
                  modeStr = 'random';
                  break;
                case StudyMode.timed:
                  modeStr = 'timed';
                  break;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudyScreen(mode: modeStr),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}

class ProgressView extends StatelessWidget {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streak Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    size: 48,
                    color: AppTheme.warningColor,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.progress.currentStreak}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Text('Day Streak'),
                      Text(
                        'Best: ${user.progress.longestStreak} days',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Course Progress
          Text(
            'Course Progress',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${user.progress.grind75Completed}/75',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        '${(user.progress.grind75Completed / 75 * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: user.progress.grind75Completed / 75,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 16),
                  // Weekly breakdown
                  ...user.progress.weeklyProgress.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Week ${entry.key}'),
                          Text('${entry.value}/15 completed'),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Category Mastery
          Text(
            'Category Mastery',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...user.progress.categoryMastery.entries.map((entry) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(entry.key),
                subtitle: LinearProgressIndicator(
                  value: entry.value,
                  backgroundColor: Colors.grey[300],
                ),
                trailing: Text(
                  '${(entry.value * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class LibraryView extends StatelessWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    final flashcardProvider = context.watch<FlashcardProviderV2>();

    if (flashcardProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final cards = flashcardProvider.filteredCards;

    return Column(
      children: [
        // Filter Bar
        Container(
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: flashcardProvider.selectedCategory == null &&
                      flashcardProvider.selectedDifficulty == null,
                  onSelected: (_) => flashcardProvider.clearFilters(),
                ),
                const SizedBox(width: 8),
                ...['Easy', 'Medium', 'Hard'].map((difficulty) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(difficulty),
                      selected: flashcardProvider.selectedDifficulty == difficulty,
                      onSelected: (selected) {
                        flashcardProvider.setDifficulty(
                          selected ? difficulty : null,
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        // Cards List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.getDifficultyColor(
                      card.predefinedDifficulty,
                    ),
                    child: Text(
                      card.leetcodeNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(card.title),
                  subtitle: Text(
                    '${card.dataStructureCategory} • ${card.predefinedDifficulty}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (card.reviewCount > 0)
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.successColor,
                          size: 20,
                        ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  onTap: () {
                    // Convert FlashcardWithProgress to Flashcard for StudyScreen compatibility
                    final flashcard = Flashcard(
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
                    );
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudyScreen(
                          initialCards: [flashcard],
                          mode: 'single',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
