import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/database_service.dart';
import '../../utils/theme.dart';
import '../tests/reaction_time_test.dart';
import '../tests/nback_test.dart';
import '../tests/stroop_test.dart';
import '../tests/flanker_test.dart';

class ExperimentDetailScreen extends StatefulWidget {
  final Experiment experiment;

  const ExperimentDetailScreen({super.key, required this.experiment});

  @override
  State<ExperimentDetailScreen> createState() => _ExperimentDetailScreenState();
}

class _ExperimentDetailScreenState extends State<ExperimentDetailScreen> {
  late Experiment _experiment;
  List<TestResult> _baselineResults = [];
  List<TestResult> _interventionResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _experiment = widget.experiment;
    _loadResults();
  }

  Future<void> _loadResults() async {
    if (_experiment.startedAt == null) {
      setState(() => _isLoading = false);
      return;
    }

    final db = DatabaseService();
    final allResults = await db.getTestResults(
      _experiment.userId,
      testType: _experiment.targetTest,
      startDate: _experiment.startedAt,
    );

    final baselineEnd = _experiment.startedAt!.add(
      Duration(days: _experiment.baselineDays),
    );

    setState(() {
      _baselineResults = allResults
          .where((r) =>
              r.experimentId == _experiment.id &&
              r.timestamp.isBefore(baselineEnd))
          .toList();
      _interventionResults = allResults
          .where((r) =>
              r.experimentId == _experiment.id &&
              !r.timestamp.isBefore(baselineEnd))
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _startExperiment() async {
    final appState = context.read<AppState>();
    final updated = _experiment.copyWith(
      status: ExperimentStatus.baseline,
      startedAt: DateTime.now(),
    );
    await appState.updateExperiment(updated);
    setState(() => _experiment = updated);
  }

  Future<void> _advanceToIntervention() async {
    final appState = context.read<AppState>();
    final updated = _experiment.copyWith(
      status: ExperimentStatus.intervention,
    );
    await appState.updateExperiment(updated);
    setState(() => _experiment = updated);
  }

  Future<void> _completeExperiment() async {
    final appState = context.read<AppState>();
    final updated = _experiment.copyWith(
      status: ExperimentStatus.completed,
      completedAt: DateTime.now(),
    );
    await appState.updateExperiment(updated);
    setState(() => _experiment = updated);
  }

  void _takeTest() {
    Widget testScreen;
    switch (_experiment.targetTest) {
      case CognitiveTestType.reactionTime:
        testScreen = const ReactionTimeTestScreen();
        break;
      case CognitiveTestType.nBack:
        testScreen = const NBackTestScreen();
        break;
      case CognitiveTestType.stroop:
        testScreen = const StroopTestScreen();
        break;
      case CognitiveTestType.flanker:
        testScreen = const FlankerTestScreen();
        break;
      default:
        testScreen = const ReactionTimeTestScreen();
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => testScreen),
    ).then((_) => _loadResults());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Experiment'),
        backgroundColor: Colors.transparent,
        actions: [
          if (_experiment.status == ExperimentStatus.draft)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showDeleteDialog(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildStatusCard(),
                  const SizedBox(height: 24),
                  if (_experiment.status != ExperimentStatus.draft) ...[
                    _buildProgressSection(),
                    const SizedBox(height: 24),
                  ],
                  if (_experiment.status == ExperimentStatus.completed)
                    _buildResultsSection()
                  else
                    _buildActionSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.science_outlined,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _experiment.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Hypothesis',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _experiment.hypothesis,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Intervention',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _experiment.intervention,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                Icons.psychology_outlined,
                _experiment.targetTest.displayName,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                Icons.calendar_today_outlined,
                '${_experiment.totalDays} days',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;

    switch (_experiment.status) {
      case ExperimentStatus.draft:
        statusColor = AppTheme.textMuted;
        statusIcon = Icons.edit_outlined;
        statusText = 'Ready to Start';
        statusDescription = 'Start the experiment when you\'re ready';
        break;
      case ExperimentStatus.baseline:
        statusColor = AppTheme.warning;
        statusIcon = Icons.trending_flat;
        statusText = 'Baseline Phase';
        statusDescription = 'Testing your normal performance';
        break;
      case ExperimentStatus.intervention:
        statusColor = AppTheme.primaryBlue;
        statusIcon = Icons.play_arrow;
        statusText = 'Intervention Phase';
        statusDescription = 'Apply your intervention daily';
        break;
      case ExperimentStatus.completed:
        statusColor = AppTheme.success;
        statusIcon = Icons.check_circle_outline;
        statusText = 'Completed';
        statusDescription = 'Review your results below';
        break;
      case ExperimentStatus.cancelled:
        statusColor = AppTheme.error;
        statusIcon = Icons.cancel_outlined;
        statusText = 'Cancelled';
        statusDescription = 'This experiment was cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: statusColor,
                      ),
                ),
                Text(
                  statusDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final currentDay = _experiment.currentDay ?? 0;
    final totalDays = _experiment.totalDays;
    final progress = (currentDay / totalDays).clamp(0.0, 1.0);

    final isInBaseline = _experiment.isInBaseline;
    final baselineProgress = isInBaseline
        ? (currentDay / _experiment.baselineDays).clamp(0.0, 1.0)
        : 1.0;
    final interventionProgress = !isInBaseline
        ? ((currentDay - _experiment.baselineDays) / _experiment.interventionDays)
            .clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
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
                'Progress',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Day $currentDay of $totalDays',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryBlue,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Overall progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.surfaceMedium,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryBlue),
            ),
          ),
          const SizedBox(height: 20),

          // Phase breakdown
          Row(
            children: [
              Expanded(
                flex: _experiment.baselineDays,
                child: _buildPhaseProgress(
                  'Baseline',
                  baselineProgress,
                  _baselineResults.length,
                  isInBaseline,
                  AppTheme.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: _experiment.interventionDays,
                child: _buildPhaseProgress(
                  'Intervention',
                  interventionProgress,
                  _interventionResults.length,
                  !isInBaseline && _experiment.status != ExperimentStatus.completed,
                  AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseProgress(
    String label,
    double progress,
    int testCount,
    bool isActive,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.1) : AppTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: color.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: isActive ? color : AppTheme.textSecondary,
                    ),
              ),
              if (isActive)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppTheme.surfaceMedium,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$testCount tests',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    if (_experiment.status == ExperimentStatus.draft) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _startExperiment,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Experiment'),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _takeTest,
            icon: const Icon(Icons.psychology_outlined),
            label: Text('Take ${_experiment.targetTest.displayName} Test'),
          ),
        ),
        const SizedBox(height: 12),
        if (_experiment.status == ExperimentStatus.baseline &&
            _baselineResults.length >= 3)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _advanceToIntervention,
              child: const Text('Skip to Intervention Phase'),
            ),
          ),
        if (_experiment.status == ExperimentStatus.intervention &&
            _interventionResults.length >= 3)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _completeExperiment,
              child: const Text('Complete Experiment'),
            ),
          ),
      ],
    );
  }

  Widget _buildResultsSection() {
    if (_baselineResults.isEmpty || _interventionResults.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.info_outline,
              size: 48,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Insufficient Data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Not enough test data to calculate results.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Calculate statistics
    final baselineAvg = _average(_baselineResults.map((r) => r.primaryScore));
    final interventionAvg = _average(_interventionResults.map((r) => r.primaryScore));

    final isLowerBetter = _experiment.targetTest == CognitiveTestType.reactionTime;
    double effectSize;
    bool isImprovement;

    if (isLowerBetter) {
      effectSize = ((baselineAvg - interventionAvg) / baselineAvg) * 100;
      isImprovement = interventionAvg < baselineAvg;
    } else {
      effectSize = ((interventionAvg - baselineAvg) / baselineAvg) * 100;
      isImprovement = interventionAvg > baselineAvg;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Results',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),

        // Main result card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isImprovement
                ? AppTheme.success.withValues(alpha: 0.1)
                : AppTheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isImprovement
                  ? AppTheme.success.withValues(alpha: 0.3)
                  : AppTheme.error.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                isImprovement
                    ? Icons.trending_up
                    : Icons.trending_down,
                size: 48,
                color: isImprovement ? AppTheme.success : AppTheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                '${effectSize.abs().toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: isImprovement ? AppTheme.success : AppTheme.error,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                isImprovement ? 'Improvement' : 'Decline',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isImprovement ? AppTheme.success : AppTheme.error,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                isImprovement
                    ? 'Your hypothesis appears to be supported!'
                    : 'The intervention may not have had the expected effect.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Comparison chart
        _buildComparisonChart(baselineAvg, interventionAvg),
        const SizedBox(height: 24),

        // Stats comparison
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Baseline',
                '${baselineAvg.round()}${_baselineResults.first.primaryScoreUnit}',
                '${_baselineResults.length} tests',
                AppTheme.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Intervention',
                '${interventionAvg.round()}${_interventionResults.first.primaryScoreUnit}',
                '${_interventionResults.length} tests',
                AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComparisonChart(double baselineAvg, double interventionAvg) {
    final allResults = [..._baselineResults, ..._interventionResults];
    allResults.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (allResults.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    for (int i = 0; i < allResults.length; i++) {
      spots.add(FlSpot(i.toDouble(), allResults[i].primaryScore));
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Over Time',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.surfaceMedium,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.round()}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (allResults.length - 1).toDouble(),
                minY: minY - padding,
                maxY: maxY + padding,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    gradient: const LinearGradient(
                      colors: [AppTheme.warning, AppTheme.primaryBlue],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final isIntervention = index >= _baselineResults.length;
                        return FlDotCirclePainter(
                          radius: 4,
                          color: isIntervention
                              ? AppTheme.primaryBlue
                              : AppTheme.warning,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                extraLinesData: ExtraLinesData(
                  verticalLines: [
                    VerticalLine(
                      x: (_baselineResults.length - 0.5),
                      color: AppTheme.textMuted.withValues(alpha: 0.5),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                      label: VerticalLineLabel(
                        show: true,
                        labelResolver: (line) => 'Start Intervention',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Baseline', AppTheme.warning),
              const SizedBox(width: 24),
              _buildLegendItem('Intervention', AppTheme.primaryBlue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  double _average(Iterable<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        title: const Text('Delete Experiment?'),
        content: const Text(
          'This action cannot be undone. All data for this experiment will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              // TODO: Actually delete the experiment
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
