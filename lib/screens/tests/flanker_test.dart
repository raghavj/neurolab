import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/theme.dart';
import '../../widgets/brain_visualization.dart';

enum FlankerState {
  instructions,
  ready,
  fixation,
  stimulus,
  feedback,
  completed,
}

enum FlankerTrialType {
  congruent,   // All arrows same direction: >>>>> or <<<<<
  incongruent, // Center different: >><>> or <<><<
  neutral,     // No flankers: ---->---- or ----<----
}

class FlankerTestScreen extends StatefulWidget {
  const FlankerTestScreen({super.key});

  @override
  State<FlankerTestScreen> createState() => _FlankerTestScreenState();
}

class _FlankerTestScreenState extends State<FlankerTestScreen> {
  static const int totalTrials = 40;
  static const int fixationDurationMs = 500;
  static const int feedbackDurationMs = 300;
  static const int maxResponseMs = 2000;

  FlankerState _state = FlankerState.instructions;
  int _currentTrial = 0;
  final Random _random = Random();

  FlankerTrialType? _trialType;
  bool? _targetIsRight; // true = right arrow, false = left arrow
  DateTime? _stimulusShownAt;
  bool? _lastCorrect;
  Timer? _timer;

  // Results
  final List<int> _congruentTimes = [];
  final List<int> _incongruentTimes = [];
  final List<int> _neutralTimes = [];
  int _congruentErrors = 0;
  int _incongruentErrors = 0;
  int _neutralErrors = 0;
  int _missedTrials = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTest() {
    setState(() {
      _state = FlankerState.ready;
      _currentTrial = 0;
      _congruentTimes.clear();
      _incongruentTimes.clear();
      _neutralTimes.clear();
      _congruentErrors = 0;
      _incongruentErrors = 0;
      _neutralErrors = 0;
      _missedTrials = 0;
    });

    Future.delayed(const Duration(seconds: 2), () {
      _startTrial();
    });
  }

  void _startTrial() {
    if (_currentTrial >= totalTrials) {
      _completeTest();
      return;
    }

    // Show fixation
    setState(() {
      _state = FlankerState.fixation;
      _lastCorrect = null;
    });

    _timer = Timer(const Duration(milliseconds: fixationDurationMs), () {
      _showStimulus();
    });
  }

  void _showStimulus() {
    // Determine trial type
    final typeRoll = _random.nextDouble();
    if (typeRoll < 0.4) {
      _trialType = FlankerTrialType.congruent;
    } else if (typeRoll < 0.8) {
      _trialType = FlankerTrialType.incongruent;
    } else {
      _trialType = FlankerTrialType.neutral;
    }

    // Random target direction
    _targetIsRight = _random.nextBool();

    setState(() {
      _state = FlankerState.stimulus;
      _stimulusShownAt = DateTime.now();
    });

    HapticFeedback.lightImpact();

    // Set timeout
    _timer = Timer(const Duration(milliseconds: maxResponseMs), () {
      _handleMissed();
    });
  }

  void _handleResponse(bool respondedRight) {
    if (_state != FlankerState.stimulus) return;

    _timer?.cancel();
    final reactionTime =
        DateTime.now().difference(_stimulusShownAt!).inMilliseconds;
    final isCorrect = respondedRight == _targetIsRight;

    HapticFeedback.mediumImpact();

    // Record result
    switch (_trialType!) {
      case FlankerTrialType.congruent:
        if (isCorrect) {
          _congruentTimes.add(reactionTime);
        } else {
          _congruentErrors++;
        }
        break;
      case FlankerTrialType.incongruent:
        if (isCorrect) {
          _incongruentTimes.add(reactionTime);
        } else {
          _incongruentErrors++;
        }
        break;
      case FlankerTrialType.neutral:
        if (isCorrect) {
          _neutralTimes.add(reactionTime);
        } else {
          _neutralErrors++;
        }
        break;
    }

    setState(() {
      _state = FlankerState.feedback;
      _lastCorrect = isCorrect;
    });

    _timer = Timer(const Duration(milliseconds: feedbackDurationMs), () {
      _currentTrial++;
      _startTrial();
    });
  }

  void _handleMissed() {
    _missedTrials++;
    setState(() {
      _state = FlankerState.feedback;
      _lastCorrect = false;
    });

    _timer = Timer(const Duration(milliseconds: feedbackDurationMs), () {
      _currentTrial++;
      _startTrial();
    });
  }

  Future<void> _completeTest() async {
    setState(() {
      _state = FlankerState.completed;
    });

    final congruentMean = _calculateMean(_congruentTimes);
    final incongruentMean = _calculateMean(_incongruentTimes);
    final flankerEffect = incongruentMean - congruentMean;

    final totalCorrect = _congruentTimes.length +
        _incongruentTimes.length +
        _neutralTimes.length;
    final accuracy = totalCorrect / totalTrials * 100;

    // Save result
    final appState = context.read<AppState>();
    final result = TestResult(
      id: appState.generateId(),
      usernId: appState.currentUser!.id,
      testType: CognitiveTestType.flanker,
      timestamp: DateTime.now(),
      primaryScore: flankerEffect,
      primaryScoreUnit: 'ms',
      detailedMetrics: {
        'flanker_effect': flankerEffect,
        'congruent_mean': congruentMean,
        'incongruent_mean': incongruentMean,
        'neutral_mean': _calculateMean(_neutralTimes),
        'congruent_errors': _congruentErrors,
        'incongruent_errors': _incongruentErrors,
        'neutral_errors': _neutralErrors,
        'missed_trials': _missedTrials,
        'accuracy': accuracy,
      },
      trialCount: totalTrials,
      correctTrials: totalCorrect,
    );

    await appState.saveTestResult(result);
  }

  double _calculateMean(List<int> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  String _getStimulusDisplay() {
    final target = _targetIsRight! ? '>' : '<';

    switch (_trialType!) {
      case FlankerTrialType.congruent:
        return '$target$target$target$target$target';
      case FlankerTrialType.incongruent:
        final flanker = _targetIsRight! ? '<' : '>';
        return '$flanker$flanker$target$flanker$flanker';
      case FlankerTrialType.neutral:
        return '- - $target - -';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _state == FlankerState.instructions || _state == FlankerState.completed
          ? AppBar(
              title: const Text('Flanker'),
              backgroundColor: Colors.transparent,
            )
          : null,
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case FlankerState.instructions:
        return _buildInstructions();
      case FlankerState.ready:
        return _buildReadyScreen();
      case FlankerState.fixation:
      case FlankerState.stimulus:
      case FlankerState.feedback:
        return _buildGameScreen();
      case FlankerState.completed:
        return _buildCompletedScreen();
    }
  }

  Widget _buildInstructions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
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
                  Icons.arrow_forward,
                  size: 64,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(height: 24),
                Text(
                  'Flanker Test',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'This test measures your selective attention and ability to filter distractions.',
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
            'Focus on the center',
            'A row of arrows will appear. Focus on the CENTER arrow.',
          ),
          const SizedBox(height: 16),
          _buildInstructionStep(
            '2',
            'Ignore the flankers',
            'The surrounding arrows may point differently - ignore them!',
          ),
          const SizedBox(height: 16),
          _buildInstructionStep(
            '3',
            'Respond quickly',
            'Tap LEFT or RIGHT based on the center arrow direction.',
          ),
          const SizedBox(height: 24),

          // Examples
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Examples',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildExampleRow('>>>>>', 'Congruent', 'Answer: RIGHT'),
                const SizedBox(height: 12),
                _buildExampleRow('<<><<', 'Incongruent', 'Answer: RIGHT'),
                const SizedBox(height: 12),
                _buildExampleRow('- - < - -', 'Neutral', 'Answer: LEFT'),
              ],
            ),
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

  Widget _buildExampleRow(String arrows, String type, String answer) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          arrows,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 4,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              type,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              answer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.accentTeal,
                  ),
            ),
          ],
        ),
      ],
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
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadyScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Get Ready...',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Focus on the CENTER arrow',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameScreen() {
    return Column(
      children: [
        // Progress
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trial ${_currentTrial + 1}/$totalTrials',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_lastCorrect != null)
                Icon(
                  _lastCorrect! ? Icons.check_circle : Icons.cancel,
                  color: _lastCorrect! ? AppTheme.success : AppTheme.error,
                  size: 28,
                ),
            ],
          ),
        ),

        const Spacer(),

        // Stimulus area
        Center(
          child: Container(
            height: 120,
            alignment: Alignment.center,
            child: _state == FlankerState.fixation
                ? const Text(
                    '+',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w300,
                      color: AppTheme.textMuted,
                    ),
                  )
                : _state == FlankerState.stimulus
                    ? Text(
                        _getStimulusDisplay(),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 8,
                        ),
                      )
                    : null,
          ),
        ),

        const Spacer(),

        // Response buttons
        Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 80,
                  child: ElevatedButton(
                    onPressed: _state == FlankerState.stimulus
                        ? () => _handleResponse(false)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceLight,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back, size: 32),
                        SizedBox(width: 8),
                        Text('LEFT', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 80,
                  child: ElevatedButton(
                    onPressed: _state == FlankerState.stimulus
                        ? () => _handleResponse(true)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceLight,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('RIGHT', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCompletedScreen() {
    final congruentMean = _calculateMean(_congruentTimes);
    final incongruentMean = _calculateMean(_incongruentTimes);
    final neutralMean = _calculateMean(_neutralTimes);
    final flankerEffect = incongruentMean - congruentMean;

    final totalCorrect = _congruentTimes.length +
        _incongruentTimes.length +
        _neutralTimes.length;
    final totalErrors = _congruentErrors + _incongruentErrors + _neutralErrors;
    final accuracy = totalCorrect / totalTrials * 100;

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

          // Flanker Effect (primary metric)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  'Flanker Effect',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${flankerEffect.round()}ms',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getFlankerFeedback(flankerEffect),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentTeal,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'The cost of filtering out distracting flankers',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Reaction times
          Text(
            'Reaction Times',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildConditionCard(
                  'Congruent',
                  '${congruentMean.round()}ms',
                  '>>>>',
                  AppTheme.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildConditionCard(
                  'Neutral',
                  '${neutralMean.round()}ms',
                  '- - > - -',
                  AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildConditionCard(
                  'Incongruent',
                  '${incongruentMean.round()}ms',
                  '<<><<',
                  AppTheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Accuracy
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${accuracy.round()}%',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppTheme.success,
                            ),
                      ),
                      Text(
                        'Accuracy',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$totalErrors',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: totalErrors > 5
                                  ? AppTheme.error
                                  : AppTheme.textPrimary,
                            ),
                      ),
                      Text(
                        'Errors',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Brain visualization
          const BrainActivationCard(
            testType: CognitiveTestType.flanker,
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

  Widget _buildConditionCard(
    String title,
    String value,
    String example,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            example,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: AppTheme.textMuted,
                ),
          ),
        ],
      ),
    );
  }

  String _getFlankerFeedback(double effect) {
    if (effect < 30) return 'Excellent focus!';
    if (effect < 60) return 'Very Good';
    if (effect < 90) return 'Good';
    if (effect < 120) return 'Average';
    return 'Keep practicing';
  }
}
