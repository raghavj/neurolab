import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/theme.dart';
import '../../widgets/brain_visualization.dart';

enum TestState {
  instructions,
  waiting,
  ready,
  stimulus,
  tooEarly,
  result,
  completed,
}

class ReactionTimeTestScreen extends StatefulWidget {
  const ReactionTimeTestScreen({super.key});

  @override
  State<ReactionTimeTestScreen> createState() => _ReactionTimeTestScreenState();
}

class _ReactionTimeTestScreenState extends State<ReactionTimeTestScreen> {
  static const int totalTrials = 10;
  static const int minWaitMs = 2000;
  static const int maxWaitMs = 5000;
  static const int maxReactionMs = 2000;

  TestState _state = TestState.instructions;
  int _currentTrial = 0;
  final List<int> _reactionTimes = [];
  int _falseStarts = 0;
  int _missedTrials = 0;

  DateTime? _stimulusShownAt;
  Timer? _waitTimer;
  Timer? _timeoutTimer;
  int? _lastReactionTime;

  final Random _random = Random();

  @override
  void dispose() {
    _waitTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startTest() {
    setState(() {
      _state = TestState.waiting;
      _currentTrial = 0;
      _reactionTimes.clear();
      _falseStarts = 0;
      _missedTrials = 0;
    });
    _startTrial();
  }

  void _startTrial() {
    // Random delay between min and max wait time
    final waitDuration = minWaitMs + _random.nextInt(maxWaitMs - minWaitMs);

    setState(() {
      _state = TestState.waiting;
    });

    _waitTimer = Timer(Duration(milliseconds: waitDuration), () {
      if (_state == TestState.waiting) {
        _showStimulus();
      }
    });
  }

  void _showStimulus() {
    setState(() {
      _state = TestState.stimulus;
      _stimulusShownAt = DateTime.now();
    });

    // Haptic feedback when stimulus appears
    HapticFeedback.mediumImpact();

    // Set timeout for missed response
    _timeoutTimer = Timer(const Duration(milliseconds: maxReactionMs), () {
      if (_state == TestState.stimulus) {
        _handleMissedTrial();
      }
    });
  }

  void _handleTap() {
    switch (_state) {
      case TestState.waiting:
        _handleFalseStart();
        break;
      case TestState.stimulus:
        _handleValidResponse();
        break;
      case TestState.tooEarly:
      case TestState.result:
        // Tap to continue
        _nextTrialOrComplete();
        break;
      default:
        break;
    }
  }

  void _handleFalseStart() {
    _waitTimer?.cancel();
    HapticFeedback.heavyImpact();

    setState(() {
      _state = TestState.tooEarly;
      _falseStarts++;
    });
  }

  void _handleValidResponse() {
    _timeoutTimer?.cancel();

    final reactionTime =
        DateTime.now().difference(_stimulusShownAt!).inMilliseconds;
    _reactionTimes.add(reactionTime);

    HapticFeedback.lightImpact();

    setState(() {
      _state = TestState.result;
      _lastReactionTime = reactionTime;
    });
  }

  void _handleMissedTrial() {
    HapticFeedback.heavyImpact();

    setState(() {
      _missedTrials++;
      _state = TestState.result;
      _lastReactionTime = null;
    });
  }

  void _nextTrialOrComplete() {
    _currentTrial++;

    if (_currentTrial >= totalTrials) {
      _completeTest();
    } else {
      _startTrial();
    }
  }

  Future<void> _completeTest() async {
    setState(() {
      _state = TestState.completed;
    });

    // Save the result
    final appState = context.read<AppState>();
    final result = ReactionTimeResult(
      id: appState.generateId(),
      usernId: appState.currentUser!.id,
      timestamp: DateTime.now(),
      reactionTimes: _reactionTimes,
      falseStarts: _falseStarts,
      missedTrials: _missedTrials,
    );

    await appState.saveTestResult(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      appBar: _state == TestState.instructions || _state == TestState.completed
          ? AppBar(
              title: const Text('Reaction Time'),
              backgroundColor: Colors.transparent,
            )
          : null,
      body: SafeArea(
        child: GestureDetector(
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (_state) {
      case TestState.waiting:
        return AppTheme.error.withOpacity(0.9);
      case TestState.stimulus:
        return AppTheme.success;
      case TestState.tooEarly:
        return AppTheme.warning;
      default:
        return AppTheme.background;
    }
  }

  Widget _buildContent() {
    switch (_state) {
      case TestState.instructions:
        return _buildInstructions();
      case TestState.waiting:
        return _buildWaitingScreen();
      case TestState.stimulus:
        return _buildStimulusScreen();
      case TestState.tooEarly:
        return _buildTooEarlyScreen();
      case TestState.result:
        return _buildResultScreen();
      case TestState.completed:
        return _buildCompletedScreen();
      default:
        return const SizedBox();
    }
  }

  Widget _buildInstructions() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.speed,
                  size: 64,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(height: 24),
                Text(
                  'Psychomotor Vigilance Test',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'This test measures your alertness and processing speed.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildInstructionStep(
            '1',
            'Wait for green',
            'The screen will turn red. Wait patiently.',
          ),
          const SizedBox(height: 16),
          _buildInstructionStep(
            '2',
            'Tap when green',
            'When the screen turns green, tap as fast as you can!',
          ),
          const SizedBox(height: 16),
          _buildInstructionStep(
            '3',
            "Don't tap early",
            'Tapping before it turns green counts as a false start.',
          ),
          const SizedBox(height: 32),
          Text(
            '$totalTrials trials',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startTest,
              child: const Text('Begin Test'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Wait...',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Trial ${_currentTrial + 1} of $totalTrials',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStimulusScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'TAP!',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 64,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTooEarlyScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_rounded,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 24),
          Text(
            'Too Early!',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Wait for the screen to turn green',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 32),
          Text(
            'Tap to continue',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white54,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_lastReactionTime != null) ...[
            Text(
              '${_lastReactionTime}ms',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 72,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _getReactionFeedback(_lastReactionTime!),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ] else ...[
            const Icon(
              Icons.timer_off,
              size: 64,
              color: AppTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Missed!',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.error,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'You took too long to respond',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
          const SizedBox(height: 32),
          Text(
            'Trial ${_currentTrial + 1} of $totalTrials',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text(
            'Tap to continue',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textMuted,
                ),
          ),
        ],
      ),
    );
  }

  String _getReactionFeedback(int ms) {
    if (ms < 200) return 'Incredible!';
    if (ms < 250) return 'Excellent!';
    if (ms < 300) return 'Very Good';
    if (ms < 350) return 'Good';
    if (ms < 400) return 'Average';
    if (ms < 500) return 'Below Average';
    return 'Keep practicing';
  }

  Widget _buildCompletedScreen() {
    if (_reactionTimes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'No Valid Trials',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'All trials were missed or false starts',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      );
    }

    final sorted = List<int>.from(_reactionTimes)..sort();
    final median = sorted.length.isOdd
        ? sorted[sorted.length ~/ 2]
        : (sorted[sorted.length ~/ 2 - 1] + sorted[sorted.length ~/ 2]) ~/ 2;
    final mean = _reactionTimes.reduce((a, b) => a + b) ~/ _reactionTimes.length;
    final fastest = sorted.first;
    final slowest = sorted.last;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Test Complete!',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 32),
          // Primary metric
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  'Median Reaction Time',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${median}ms',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getReactionFeedback(median),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentTeal,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Detailed metrics
          Row(
            children: [
              Expanded(child: _buildMetricCard('Mean', '${mean}ms')),
              const SizedBox(width: 16),
              Expanded(child: _buildMetricCard('Fastest', '${fastest}ms')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Slowest', '${slowest}ms')),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Valid Trials',
                  '${_reactionTimes.length}/$totalTrials',
                ),
              ),
            ],
          ),
          if (_falseStarts > 0 || _missedTrials > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (_falseStarts > 0)
                  Expanded(
                    child: _buildMetricCard(
                      'False Starts',
                      '$_falseStarts',
                      color: AppTheme.warning,
                    ),
                  ),
                if (_falseStarts > 0 && _missedTrials > 0)
                  const SizedBox(width: 16),
                if (_missedTrials > 0)
                  Expanded(
                    child: _buildMetricCard(
                      'Missed',
                      '$_missedTrials',
                      color: AppTheme.error,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 32),
          // Brain visualization
          const BrainActivationCard(
            testType: CognitiveTestType.reactionTime,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Dashboard'),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _startTest,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, {Color? color}) {
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
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color ?? AppTheme.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}
