import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/theme.dart';
import '../tests/reaction_time_test.dart';
import '../tests/nback_test.dart';
import '../tests/stroop_test.dart';
import '../tests/flanker_test.dart';
import '../tests/trail_making_test.dart';
import 'test_info_sheet.dart';
import 'lifestyle_log_screen.dart';
import 'insights_screen.dart';
import '../experiments/experiments_screen.dart';
import '../settings/export_data_screen.dart';
import '../settings/notification_settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _HomeTab(),
          _TestsTab(),
          InsightsScreen(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        backgroundColor: AppTheme.surfaceLight,
        indicatorColor: AppTheme.primaryBlue.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: 'Tests',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              _getGreeting(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              user?.name ?? 'Scientist',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 24),

            // Quick actions row
            Row(
              children: [
                Expanded(child: _QuickTestCard()),
                const SizedBox(width: 12),
                Expanded(child: _LifestyleLogCard()),
              ],
            ),
            const SizedBox(height: 24),

            // Stats summary
            if (appState.recentResults.isNotEmpty) ...[
              _StatsSummary(results: appState.recentResults),
              const SizedBox(height: 24),
            ],

            // Recent results
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (appState.recentResults.isEmpty)
              _EmptyResultsCard()
            else
              ...appState.recentResults.take(5).map(
                    (result) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ResultCard(result: result),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _QuickTestCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ReactionTimeTestScreen(),
          ),
        );
      },
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.speed,
                color: Colors.white,
                size: 24,
              ),
            ),
            const Spacer(),
            const Text(
              'Quick Test',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Reaction time',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LifestyleLogCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final hasLoggedToday = appState.todayLog != null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LifestyleLogScreen(),
          ),
        );
      },
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: hasLoggedToday
              ? Border.all(color: AppTheme.success.withValues(alpha: 0.5), width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentTeal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_note,
                    color: AppTheme.accentTeal,
                    size: 24,
                  ),
                ),
                if (hasLoggedToday) ...[
                  const Spacer(),
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.success,
                    size: 20,
                  ),
                ],
              ],
            ),
            const Spacer(),
            Text(
              hasLoggedToday ? 'Update Log' : 'Daily Log',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasLoggedToday ? 'Logged today' : 'Track factors',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsSummary extends StatelessWidget {
  final List<TestResult> results;

  const _StatsSummary({required this.results});

  @override
  Widget build(BuildContext context) {
    // Get stats for reaction time tests
    final rtResults = results
        .where((r) => r.testType == CognitiveTestType.reactionTime)
        .toList();

    if (rtResults.isEmpty) return const SizedBox.shrink();

    final latestScore = rtResults.first.primaryScore;
    final avgScore = rtResults.map((r) => r.primaryScore).reduce((a, b) => a + b) /
        rtResults.length;

    // Calculate trend
    String trend = '';
    Color trendColor = AppTheme.textMuted;
    if (rtResults.length >= 2) {
      final recentAvg = rtResults.take(3).map((r) => r.primaryScore).reduce((a, b) => a + b) /
          (rtResults.length >= 3 ? 3 : rtResults.length);
      final diff = avgScore - recentAvg;
      if (diff > 10) {
        trend = 'Improving';
        trendColor = AppTheme.success;
      } else if (diff < -10) {
        trend = 'Declining';
        trendColor = AppTheme.error;
      } else {
        trend = 'Stable';
        trendColor = AppTheme.textSecondary;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reaction Time',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (trend.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: trendColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Latest',
                  value: '${latestScore.round()}ms',
                  color: AppTheme.primaryBlue,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.surfaceMedium,
              ),
              Expanded(
                child: _StatItem(
                  label: 'Average',
                  value: '${avgScore.round()}ms',
                  color: AppTheme.textSecondary,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.surfaceMedium,
              ),
              Expanded(
                child: _StatItem(
                  label: 'Tests',
                  value: '${rtResults.length}',
                  color: AppTheme.accentTeal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _EmptyResultsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.surfaceMedium,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.science_outlined,
            size: 48,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No tests yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your first cognitive test to start tracking your performance.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final TestResult result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getTestIcon(result.testType),
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.testType.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  DateFormat('MMM d, h:mm a').format(result.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.primaryScore.round()}${result.primaryScoreUnit}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryBlue,
                    ),
              ),
              Text(
                '${(result.accuracy * 100).round()}% accuracy',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getTestIcon(CognitiveTestType type) {
    switch (type) {
      case CognitiveTestType.reactionTime:
        return Icons.speed;
      case CognitiveTestType.nBack:
        return Icons.grid_view;
      case CognitiveTestType.stroop:
        return Icons.color_lens;
      case CognitiveTestType.trailMaking:
        return Icons.timeline;
      case CognitiveTestType.flanker:
        return Icons.arrow_forward;
    }
  }
}

class _TestsTab extends StatelessWidget {
  const _TestsTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cognitive Tests',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Scientifically validated assessments',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _TestListItem(
              testType: CognitiveTestType.reactionTime,
              isAvailable: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReactionTimeTestScreen(),
                  ),
                );
              },
              onInfoTap: () => _showTestInfo(context, CognitiveTestType.reactionTime),
            ),
            const SizedBox(height: 12),
            _TestListItem(
              testType: CognitiveTestType.nBack,
              isAvailable: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NBackTestScreen(),
                  ),
                );
              },
              onInfoTap: () => _showTestInfo(context, CognitiveTestType.nBack),
            ),
            const SizedBox(height: 12),
            _TestListItem(
              testType: CognitiveTestType.stroop,
              isAvailable: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StroopTestScreen(),
                  ),
                );
              },
              onInfoTap: () => _showTestInfo(context, CognitiveTestType.stroop),
            ),
            const SizedBox(height: 12),
            _TestListItem(
              testType: CognitiveTestType.flanker,
              isAvailable: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FlankerTestScreen(),
                  ),
                );
              },
              onInfoTap: () => _showTestInfo(context, CognitiveTestType.flanker),
            ),
            const SizedBox(height: 12),
            _TestListItem(
              testType: CognitiveTestType.trailMaking,
              isAvailable: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TrailMakingTestScreen(),
                  ),
                );
              },
              onInfoTap: () => _showTestInfo(context, CognitiveTestType.trailMaking),
            ),
          ],
        ),
      ),
    );
  }

  void _showTestInfo(BuildContext context, CognitiveTestType testType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TestInfoSheet(testType: testType),
    );
  }
}

class _TestListItem extends StatelessWidget {
  final CognitiveTestType testType;
  final bool isAvailable;
  final VoidCallback onTap;
  final VoidCallback onInfoTap;

  const _TestListItem({
    required this.testType,
    required this.isAvailable,
    required this.onTap,
    required this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isAvailable ? 1.0 : 0.6,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isAvailable ? onTap : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? AppTheme.primaryBlue.withOpacity(0.1)
                          : AppTheme.surfaceMedium,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getTestIcon(testType),
                      color: isAvailable ? AppTheme.primaryBlue : AppTheme.textMuted,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              testType.displayName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (!isAvailable) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceMedium,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Coming Soon',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          testType.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: onInfoTap,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTestIcon(CognitiveTestType type) {
    switch (type) {
      case CognitiveTestType.reactionTime:
        return Icons.speed;
      case CognitiveTestType.nBack:
        return Icons.grid_view;
      case CognitiveTestType.stroop:
        return Icons.color_lens;
      case CognitiveTestType.trailMaking:
        return Icons.timeline;
      case CognitiveTestType.flanker:
        return Icons.arrow_forward;
    }
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  user?.name.isNotEmpty == true
                      ? user!.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? 'Scientist',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Member since ${user != null ? DateFormat('MMMM yyyy').format(user.createdAt) : ''}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            _buildStatRow(context, appState),
            const SizedBox(height: 24),

            // Experiments button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExperimentsScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.science_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Self-Experiments',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Test hypotheses about your cognition',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, AppState appState) {
    final testCount = appState.recentResults.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(context, testCount.toString(), 'Tests'),
        _buildStatItem(context, '0', 'Insights'),
        _buildStatItem(context, '0', 'Experiments'),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primaryBlue,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _buildSettingsTile(
          context,
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Reminders for daily tests',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationSettingsScreen(),
              ),
            );
          },
        ),
        _buildSettingsTile(
          context,
          icon: Icons.download_outlined,
          title: 'Export Data',
          subtitle: 'Download your test history',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ExportDataScreen(),
              ),
            );
          },
        ),
        _buildSettingsTile(
          context,
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy',
          subtitle: 'Data storage and security',
          onTap: () {},
        ),
        _buildSettingsTile(
          context,
          icon: Icons.help_outline,
          title: 'Help & About',
          subtitle: 'Learn more about NeuroLab',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.textSecondary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppTheme.textMuted,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
