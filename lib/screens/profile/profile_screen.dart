import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/flashcard_provider_v2.dart';
import '../../providers/study_session_provider.dart';
import '../../utils/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final flashcardProvider = context.watch<FlashcardProviderV2>();
    final user = authProvider.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    final totalCards = flashcardProvider.flashcards.length;
    final completedCards = flashcardProvider.flashcards.where((card) => card.reviewCount > 0).length;
    final masteredCards = flashcardProvider.flashcards.where((card) => card.personalDifficulty == 4).length;
    final stats = flashcardProvider.getBasicStatistics();

    // Calculate total study time (mock data for now)
    final totalMinutes = completedCards * 5; // Assume 5 minutes per card average
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Profile Header
          SliverAppBar(
            expandedHeight: 280.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user.displayName?.isNotEmpty == true 
                              ? user.displayName![0].toUpperCase()
                              : 'U',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Name
                      Text(
                        user.displayName ?? 'User',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Email
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Join Date
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'Member since ${_formatDate(user.createdAt)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  // TODO: Navigate to settings
                },
              ),
            ],
          ),

          // Stats Cards
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              delegate: SliverChildListDelegate([
                _buildStatCard(
                  icon: Icons.local_fire_department,
                  title: 'Current Streak',
                  value: '${flashcardProvider.userProfile?.currentStreak ?? 0}',
                  subtitle: 'days',
                  color: Colors.orange,
                ),
                _buildStatCard(
                  icon: Icons.trending_up,
                  title: 'Best Streak',
                  value: '${flashcardProvider.userProfile?.longestStreak ?? 0}',
                  subtitle: 'days',
                  color: Colors.red,
                ),
                _buildStatCard(
                  icon: Icons.check_circle,
                  title: 'Completed',
                  value: '$completedCards',
                  subtitle: 'of $totalCards cards',
                  color: Colors.green,
                ),
                _buildStatCard(
                  icon: Icons.star,
                  title: 'Mastered',
                  value: '$masteredCards',
                  subtitle: 'cards',
                  color: Colors.amber,
                ),
                _buildStatCard(
                  icon: Icons.timer,
                  title: 'Study Time',
                  value: hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
                  subtitle: 'total',
                  color: Colors.blue,
                ),
                _buildStatCard(
                  icon: Icons.emoji_events,
                  title: 'Accuracy',
                  value: '${_calculateAccuracy(context)}%',
                  subtitle: 'success rate',
                  color: Colors.purple,
                ),
              ]),
            ),
          ),

          // Category Progress Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Category Progress',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Category Cards
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final categories = stats['categoryStats'] as Map<String, int>;
                  final sortedCategories = categories.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  
                  if (index >= sortedCategories.length) return null;
                  
                  final category = sortedCategories[index];
                  
                  // Calculate category progress from flashcard data
                  final categoryCards = flashcardProvider.flashcards
                      .where((card) => card.dataStructureCategory == category.key)
                      .toList();
                  final completedInCategory = categoryCards
                      .where((card) => card.reviewCount > 0)
                      .length;
                  final progress = categoryCards.isNotEmpty 
                      ? completedInCategory / categoryCards.length
                      : 0.0;
                  
                  return _buildCategoryCard(
                    category: category.key,
                    total: category.value,
                    completed: completedInCategory,
                    progress: progress,
                  );
                },
                childCount: (stats['categoryStats'] as Map).length,
              ),
            ),
          ),

          // Achievements Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Achievements',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Achievement Badges
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              delegate: SliverChildListDelegate([
                _buildAchievementBadge(
                  icon: Icons.rocket_launch,
                  label: 'Started',
                  unlocked: true,
                ),
                _buildAchievementBadge(
                  icon: Icons.local_fire_department,
                  label: '7 Day Streak',
                  unlocked: (flashcardProvider.userProfile?.currentStreak ?? 0) >= 7,
                ),
                _buildAchievementBadge(
                  icon: Icons.whatshot,
                  label: '30 Day Streak',
                  unlocked: (flashcardProvider.userProfile?.longestStreak ?? 0) >= 30,
                ),
                _buildAchievementBadge(
                  icon: Icons.school,
                  label: '10 Cards',
                  unlocked: completedCards >= 10,
                ),
                _buildAchievementBadge(
                  icon: Icons.emoji_events,
                  label: '50 Cards',
                  unlocked: completedCards >= 50,
                ),
                _buildAchievementBadge(
                  icon: Icons.military_tech,
                  label: '100 Cards',
                  unlocked: completedCards >= 100,
                ),
                _buildAchievementBadge(
                  icon: Icons.star,
                  label: 'Master',
                  unlocked: masteredCards >= 25,
                ),
                _buildAchievementBadge(
                  icon: Icons.workspace_premium,
                  label: 'Complete',
                  unlocked: completedCards == totalCards,
                ),
              ]),
            ),
          ),

          // Reset Progress Section
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  onPressed: () => _handleResetProgress(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Progress'),
                ),
              ),
            ),
          ),

          // Sign Out Button
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverToBoxAdapter(
              child: ElevatedButton.icon(
                onPressed: () => _handleSignOut(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required String category,
    required int total,
    required int completed,
    required double progress,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '$completed / $total',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.7
                    ? Colors.green
                    : progress > 0.4
                        ? Colors.orange
                        : Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% Complete',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge({
    required IconData icon,
    required String label,
    required bool unlocked,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: unlocked ? Colors.amber.withOpacity(0.1) : Colors.grey[200],
            border: Border.all(
              color: unlocked ? Colors.amber : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: unlocked ? Colors.amber[700] : Colors.grey[400],
            size: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: unlocked ? Colors.grey[800] : Colors.grey[400],
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _handleResetProgress(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Progress'),
          content: const Text(
            'This will reset all your review progress, difficulty ratings, and study statistics while keeping the flashcards. This action cannot be undone.\n\nAre you sure you want to continue?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                
                // Show loading snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 16),
                        Text('Resetting progress...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
                
                try {
                  await context.read<FlashcardProviderV2>().resetProgress('');
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Progress reset successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error resetting progress: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Reset Progress'),
            ),
          ],
        );
      },
    );
  }


  void _handleSignOut(BuildContext context) {
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
                Navigator.of(context).pop(); // Close profile screen
                await context.read<AuthProvider>().signOut();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  int _calculateAccuracy(BuildContext context) {
    // Calculate accuracy based on session statistics
    final sessionProvider = Provider.of<StudySessionProvider>(context, listen: false);
    final stats = sessionProvider.getSessionStatistics();
    final accuracy = stats['averageAccuracy'] as double;
    return accuracy.round();
  }
}
