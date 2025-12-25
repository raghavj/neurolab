import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/insights_service.dart';
import '../../utils/theme.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final InsightsService _insightsService = InsightsService();
  List<Insight>? _insights;
  bool _isLoading = true;
  CognitiveTestType _selectedTestType = CognitiveTestType.reactionTime;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    final appState = context.read<AppState>();
    if (appState.currentUser == null) return;

    setState(() => _isLoading = true);

    final insights =
        await _insightsService.generateInsights(appState.currentUser!.id);

    setState(() {
      _insights = insights;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final testCount = appState.recentResults.length;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadInsights,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Insights',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Personalized discoveries about your cognition',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Progress indicator
              if (testCount < 7) ...[
                _buildProgressCard(testCount),
                const SizedBox(height: 24),
              ],

              // Test type selector
              if (testCount >= 5) ...[
                _buildTestTypeSelector(appState),
                const SizedBox(height: 24),

                // Performance chart
                _buildPerformanceChart(appState),
                const SizedBox(height: 24),
              ],

              // Insights section
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_insights != null && _insights!.isNotEmpty) ...[
                Text(
                  'Discoveries',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ..._insights!.map((insight) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _InsightCard(insight: insight),
                    )),
              ] else if (testCount >= 7) ...[
                _buildNoInsightsCard(),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(int testCount) {
    final progress = (testCount / 7).clamp(0.0, 1.0);
    final remaining = 7 - testCount;

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
                  Icons.insights_outlined,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Building Your Profile',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '$remaining more tests to unlock insights',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.surfaceMedium,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryBlue),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$testCount / 7 tests completed',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildTestTypeSelector(AppState appState) {
    final availableTypes = <CognitiveTestType>{};
    for (final result in appState.recentResults) {
      availableTypes.add(result.testType);
    }

    if (availableTypes.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: availableTypes.map((type) {
          final isSelected = type == _selectedTestType;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(type.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedTestType = type);
                }
              },
              selectedColor: AppTheme.primaryBlue,
              backgroundColor: AppTheme.surfaceLight,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPerformanceChart(AppState appState) {
    final results = appState.recentResults
        .where((r) => r.testType == _selectedTestType)
        .toList()
        .reversed
        .take(14)
        .toList();

    if (results.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < results.length; i++) {
      spots.add(FlSpot(i.toDouble(), results[i].primaryScore));
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;

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
                'Performance Trend',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Last ${results.length} tests',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
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
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.round()}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (results.length / 4).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= results.length) {
                          return const Text('');
                        }
                        return Text(
                          DateFormat('M/d').format(results[index].timestamp),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
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
                maxX: (results.length - 1).toDouble(),
                minY: minY - padding,
                maxY: maxY + padding,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppTheme.primaryBlue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppTheme.primaryBlue,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => AppTheme.surfaceMedium,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final result = results[spot.spotIndex];
                        return LineTooltipItem(
                          '${spot.y.round()}${result.primaryScoreUnit}\n${DateFormat('MMM d').format(result.timestamp)}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_outlined,
            size: 48,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No patterns found yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Keep testing and logging your lifestyle factors. Insights appear when we detect meaningful correlations.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final Insight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getIconColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIcon(),
                  color: _getIconColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      insight.testType.displayName,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _buildEffectBadge(context),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildConfidenceIndicator(context),
              const Spacer(),
              Text(
                'Based on ${insight.sampleSize} data points',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getBorderColor() {
    switch (insight.direction) {
      case InsightDirection.positive:
        return AppTheme.success;
      case InsightDirection.negative:
        return AppTheme.warning;
      case InsightDirection.neutral:
        return AppTheme.textMuted;
    }
  }

  Color _getIconColor() {
    switch (insight.type) {
      case InsightType.sleepDuration:
      case InsightType.sleepQuality:
        return const Color(0xFF8B5CF6); // Purple
      case InsightType.caffeine:
        return const Color(0xFFF59E0B); // Amber
      case InsightType.exercise:
        return const Color(0xFF10B981); // Green
      case InsightType.stress:
        return const Color(0xFFEF4444); // Red
      case InsightType.mood:
        return const Color(0xFFF472B6); // Pink
      case InsightType.energy:
        return const Color(0xFF3B82F6); // Blue
      case InsightType.meditation:
        return const Color(0xFF14B8A6); // Teal
      case InsightType.timeOfDay:
        return const Color(0xFFFBBF24); // Yellow
      case InsightType.dayOfWeek:
        return const Color(0xFF6366F1); // Indigo
    }
  }

  IconData _getIcon() {
    switch (insight.type) {
      case InsightType.sleepDuration:
      case InsightType.sleepQuality:
        return Icons.bedtime_outlined;
      case InsightType.caffeine:
        return Icons.coffee_outlined;
      case InsightType.exercise:
        return Icons.fitness_center_outlined;
      case InsightType.stress:
        return Icons.psychology_alt_outlined;
      case InsightType.mood:
        return Icons.mood_outlined;
      case InsightType.energy:
        return Icons.bolt_outlined;
      case InsightType.meditation:
        return Icons.self_improvement_outlined;
      case InsightType.timeOfDay:
        return Icons.schedule_outlined;
      case InsightType.dayOfWeek:
        return Icons.calendar_today_outlined;
    }
  }

  Widget _buildEffectBadge(BuildContext context) {
    final isPositive = insight.direction == InsightDirection.positive;
    final color = isPositive ? AppTheme.success : AppTheme.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${insight.effectSize.abs().round()}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(BuildContext context) {
    final confidence = insight.confidence;
    String label;
    Color color;

    if (confidence >= 0.85) {
      label = 'High confidence';
      color = AppTheme.success;
    } else if (confidence >= 0.7) {
      label = 'Medium confidence';
      color = AppTheme.warning;
    } else {
      label = 'Low confidence';
      color = AppTheme.textMuted;
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
              ),
        ),
      ],
    );
  }
}
