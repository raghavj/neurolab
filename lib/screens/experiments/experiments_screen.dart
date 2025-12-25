import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/database_service.dart';
import '../../utils/theme.dart';
import 'experiment_builder_screen.dart';
import 'experiment_detail_screen.dart';

class ExperimentsScreen extends StatefulWidget {
  const ExperimentsScreen({super.key});

  @override
  State<ExperimentsScreen> createState() => _ExperimentsScreenState();
}

class _ExperimentsScreenState extends State<ExperimentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Experiment> _experiments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExperiments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExperiments() async {
    final appState = context.read<AppState>();
    if (appState.currentUser == null) return;

    final db = DatabaseService();
    final experiments = await db.getExperiments(appState.currentUser!.id);

    setState(() {
      _experiments = experiments;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Experiments'),
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryBlue,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'My Experiments'),
            Tab(text: 'Templates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyExperimentsTab(),
          _buildTemplatesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ExperimentBuilderScreen(),
            ),
          ).then((_) => _loadExperiments());
        },
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
    );
  }

  Widget _buildMyExperimentsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeExperiments = _experiments
        .where((e) =>
            e.status == ExperimentStatus.baseline ||
            e.status == ExperimentStatus.intervention)
        .toList();
    final draftExperiments =
        _experiments.where((e) => e.status == ExperimentStatus.draft).toList();
    final completedExperiments = _experiments
        .where((e) => e.status == ExperimentStatus.completed)
        .toList();

    if (_experiments.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadExperiments,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activeExperiments.isNotEmpty) ...[
              Text(
                'Active',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...activeExperiments.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ExperimentCard(
                      experiment: e,
                      onTap: () => _openExperiment(e),
                    ),
                  )),
              const SizedBox(height: 16),
            ],
            if (draftExperiments.isNotEmpty) ...[
              Text(
                'Drafts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...draftExperiments.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ExperimentCard(
                      experiment: e,
                      onTap: () => _openExperiment(e),
                    ),
                  )),
              const SizedBox(height: 16),
            ],
            if (completedExperiments.isNotEmpty) ...[
              Text(
                'Completed',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...completedExperiments.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ExperimentCard(
                      experiment: e,
                      onTap: () => _openExperiment(e),
                    ),
                  )),
            ],
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Start Templates',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Pre-designed experiments based on cognitive science research',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          ...experimentTemplates.map((template) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _TemplateCard(
                  template: template,
                  onTap: () => _useTemplate(template),
                ),
              )),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.science_outlined,
                size: 50,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Experiments Yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Design experiments to test hypotheses about your cognition. Start with a template or create your own.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _tabController.animateTo(1);
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Browse Templates'),
            ),
          ],
        ),
      ),
    );
  }

  void _openExperiment(Experiment experiment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExperimentDetailScreen(experiment: experiment),
      ),
    ).then((_) => _loadExperiments());
  }

  void _useTemplate(ExperimentTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExperimentBuilderScreen(template: template),
      ),
    ).then((_) => _loadExperiments());
  }
}

class _ExperimentCard extends StatelessWidget {
  final Experiment experiment;
  final VoidCallback onTap;

  const _ExperimentCard({
    required this.experiment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: experiment.status == ExperimentStatus.baseline ||
                  experiment.status == ExperimentStatus.intervention
              ? Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getStatusColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getStatusIcon(),
                color: _getStatusColor(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    experiment.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          experiment.status.displayName,
                          style: TextStyle(
                            color: _getStatusColor(),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        experiment.targetTest.displayName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (experiment.status == ExperimentStatus.baseline ||
                experiment.status == ExperimentStatus.intervention)
              _buildProgressIndicator(context),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    final progress =
        (experiment.currentDay ?? 0) / experiment.totalDays;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: AppTheme.surfaceMedium,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryBlue),
            ),
            Center(
              child: Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (experiment.status) {
      case ExperimentStatus.draft:
        return AppTheme.textMuted;
      case ExperimentStatus.baseline:
        return AppTheme.warning;
      case ExperimentStatus.intervention:
        return AppTheme.primaryBlue;
      case ExperimentStatus.completed:
        return AppTheme.success;
      case ExperimentStatus.cancelled:
        return AppTheme.error;
    }
  }

  IconData _getStatusIcon() {
    switch (experiment.status) {
      case ExperimentStatus.draft:
        return Icons.edit_outlined;
      case ExperimentStatus.baseline:
        return Icons.trending_flat;
      case ExperimentStatus.intervention:
        return Icons.play_arrow;
      case ExperimentStatus.completed:
        return Icons.check_circle_outline;
      case ExperimentStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}

class _TemplateCard extends StatelessWidget {
  final ExperimentTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getTemplateIcon(),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${template.baselineDays + template.interventionDays} days',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Use',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              template.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTag(context, template.targetTest.displayName),
                const SizedBox(width: 8),
                _buildTag(
                  context,
                  '${template.baselineDays}d baseline',
                ),
                const SizedBox(width: 8),
                _buildTag(
                  context,
                  '${template.interventionDays}d intervention',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
            ),
      ),
    );
  }

  IconData _getTemplateIcon() {
    if (template.title.toLowerCase().contains('meditation')) {
      return Icons.self_improvement;
    } else if (template.title.toLowerCase().contains('caffeine')) {
      return Icons.coffee;
    } else if (template.title.toLowerCase().contains('sleep')) {
      return Icons.bedtime;
    } else if (template.title.toLowerCase().contains('exercise')) {
      return Icons.fitness_center;
    }
    return Icons.science;
  }
}
