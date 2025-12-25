import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/theme.dart';
import '../../widgets/brain_visualization.dart';

enum StroopState {
  instructions,
  ready,
  showStimulus,
  feedback,
  completed,
}

enum StroopTrialType {
  congruent,   // Word matches ink color (e.g., "RED" in red)
  incongruent, // Word doesn't match ink color (e.g., "RED" in blue)
  neutral,     // Non-color word (e.g., "XXXX" in red)
}

class StroopColor {
  final String name;
  final Color color;

  const StroopColor(this.name, this.color);
}

class StroopTestScreen extends StatefulWidget {
  const StroopTestScreen({super.key});

  @override
  State<StroopTestScreen> createState() => _StroopTestScreenState();
}

class _StroopTestScreenState extends State<StroopTestScreen> {
  static const int totalTrials = 30;
  static const int feedbackDurationMs = 300;

  static const List<StroopColor> colors = [
    StroopColor('RED', Color(0xFFEF4444)),
    StroopColor('BLUE', Color(0xFF3B82F6)),
    StroopColor('GREEN', Color(0xFF22C55E)),
    StroopColor('YELLOW', Color(0xFFEAB308)),
  ];

  StroopState _state = StroopState.instructions;
  int _currentTrial = 0;
  final Random _random = Random();

  String? _currentWord;
  Color? _currentColor;
  int? _correctColorIndex;
  StroopTrialType? _currentTrialType;
  DateTime? _stimulusShownAt;
  bool? _lastCorrect;

  // Results tracking
  final List<int> _congruentTimes = [];
  final List<int> _incongruentTimes = [];
  final List<int> _neutralTimes = [];
  int _congruentErrors = 0;
  int _incongruentErrors = 0;
  int _neutralErrors = 0;

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTest() {
    setState(() {
      _state = StroopState.ready;
      _currentTrial = 0;
      _congruentTimes.clear();
      _incongruentTimes.clear();
      _neutralTimes.clear();
      _congruentErrors = 0;
      _incongruentErrors = 0;
      _neutralErrors = 0;
    });

    Future.delayed(const Duration(seconds: 2), () {
      _showNextStimulus();
    });
  }

  void _showNextStimulus() {
    if (_currentTrial >= totalTrials) {
      _completeTest();
      return;
    }

    // Determine trial type (roughly equal distribution)
    final typeRoll = _random.nextDouble();
    if (typeRoll < 0.33) {
      _currentTrialType = StroopTrialType.congruent;
    } else if (typeRoll < 0.66) {
      _currentTrialType = StroopTrialType.incongruent;
    } else {
      _currentTrialType = StroopTrialType.neutral;
    }

    // Select ink color (this is what participant needs to identify)
    _correctColorIndex = _random.nextInt(colors.length);
    _currentColor = colors[_correctColorIndex!].color;

    // Select word based on trial type
    switch (_currentTrialType!) {
      case StroopTrialType.congruent:
        _currentWord = colors[_correctColorIndex!].name;
        break;
      case StroopTrialType.incongruent:
        int wordIndex;
        do {
          wordIndex = _random.nextInt(colors.length);
        } while (wordIndex == _correctColorIndex);
        _currentWord = colors[wordIndex].name;
        break;
      case StroopTrialType.neutral:
        _currentWord = 'XXXX';
        break;
    }

    setState(() {
      _state = StroopState.showStimulus;
      _stimulusShownAt = DateTime.now();
      _lastCorrect = null;
    });

    HapticFeedback.lightImpact();
  }

  void _handleResponse(int colorIndex) {
    if (_state != StroopState.showStimulus) return;

    final reactionTime =
        DateTime.now().difference(_stimulusShownAt!).inMilliseconds;
    final isCorrect = colorIndex == _correctColorIndex;

    HapticFeedback.mediumImpact();

    // Record result
    switch (_currentTrialType!) {
      case StroopTrialType.congruent:
        if (isCorrect) {
          _congruentTimes.add(reactionTime);
        } else {
          _congruentErrors++;
        }
        break;
      case StroopTrialType.incongruent:
        if (isCorrect) {
          _incongruentTimes.add(reactionTime);
        } else {
          _incongruentErrors++;
        }
        break;
      case StroopTrialType.neutral:
        if (isCorrect) {
          _neutralTimes.add(reactionTime);
        } else {
          _neutralErrors++;
        }
        break;
    }

    setState(() {
      _state = StroopState.feedback;
      _lastCorrect = isCorrect;
    });

    _timer = Timer(const Duration(milliseconds: feedbackDurationMs), () {
      _currentTrial++;
      _showNextStimulus();
    });
  }

  Future<void> _completeTest() async {
    setState(() {
      _state = StroopState.completed;
    });

    // Calculate metrics
    final congruentMean = _calculateMean(_congruentTimes);
    final incongruentMean = _calculateMean(_incongruentTimes);
    final stroopEffect = incongruentMean - congruentMean;

    final totalCorrect = _congruentTimes.length +
        _incongruentTimes.length +
        _neutralTimes.length;
    final accuracy = totalCorrect / totalTrials * 100;

    // Save result
    final appState = context.read<AppState>();
    final result = TestResult(
      id: appState.generateId(),
      usernId: appState.currentUser!.id,
      testType: CognitiveTestType.stroop,
      timestamp: DateTime.now(),
      primaryScore: stroopEffect,
      primaryScoreUnit: 'ms',
      detailedMetrics: {
        'stroop_effect': stroopEffect,
        'congruent_mean': congruentMean,
        'incongruent_mean': incongruentMean,
        'neutral_mean': _calculateMean(_neutralTimes),
        'congruent_errors': _congruentErrors,
        'incongruent_errors': _incongruentErrors,
        'neutral_errors': _neutralErrors,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _state == StroopState.instructions || _state == StroopState.completed
          ? AppBar(
              title: const Text('Stroop'),
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
      case StroopState.instructions:
        return _buildInstructions();
      case StroopState.ready:
        return _buildReadyScreen();
      case StroopState.showStimulus:
      case StroopState.feedback:
        return _buildGameScreen();
      case StroopState.completed:
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
                  Icons.color_lens,
                  size: 64,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(height: 24),
                Text(
                  'Stroop Test',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'This test measures your cognitive control and ability to suppress automatic responses.',
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
            'See a word',
            'A color word will appear on screen.',
          ),
          const SizedBox(height: 16),
          _buildInstructionStep(
            '2',
            'Ignore the word',
            "Don't read the word! Focus on the INK COLOR.",
          ),
          const SizedBox(height: 16),
          _buildInstructionStep(
            '3',
            'Tap the ink color',
            'Select the button matching the color of the text.',
          ),
          const SizedBox(height: 24),

          // Example
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Example',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'BLUE',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: colors[0].color, // RED
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'The word says "BLUE" but the ink is RED.\nCorrect answer: RED',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
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
            'Name the INK COLOR, not the word!',
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

        // Word display
        if (_currentWord != null)
          Text(
            _currentWord!,
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: _currentColor,
            ),
          ),

        const Spacer(),

        // Color buttons
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildColorButton(0)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildColorButton(1)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildColorButton(2)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildColorButton(3)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildColorButton(int index) {
    final color = colors[index];
    final isCorrectAnswer =
        _state == StroopState.feedback && index == _correctColorIndex;
    final isWrongAnswer = _state == StroopState.feedback &&
        _lastCorrect == false &&
        index != _correctColorIndex;

    return SizedBox(
      height: 64,
      child: ElevatedButton(
        onPressed:
            _state == StroopState.showStimulus ? () => _handleResponse(index) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isCorrectAnswer
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
          ),
        ),
        child: Text(
          color.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            decoration: isWrongAnswer ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedScreen() {
    final congruentMean = _calculateMean(_congruentTimes);
    final incongruentMean = _calculateMean(_incongruentTimes);
    final neutralMean = _calculateMean(_neutralTimes);
    final stroopEffect = incongruentMean - congruentMean;

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

          // Stroop Effect (primary metric)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  'Stroop Effect',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${stroopEffect.round()}ms',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getStroopFeedback(stroopEffect),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentTeal,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'The interference cost when word and color conflict',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Reaction times by condition
          Text(
            'Reaction Times by Condition',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildConditionCard(
                  'Congruent',
                  '${congruentMean.round()}ms',
                  'Word = Color',
                  AppTheme.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildConditionCard(
                  'Neutral',
                  '${neutralMean.round()}ms',
                  'XXXX',
                  AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildConditionCard(
                  'Incongruent',
                  '${incongruentMean.round()}ms',
                  'Word ≠ Color',
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
            testType: CognitiveTestType.stroop,
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
    String subtitle,
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
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
          ),
        ],
      ),
    );
  }

  String _getStroopFeedback(double effect) {
    if (effect < 50) return 'Excellent control!';
    if (effect < 100) return 'Very Good';
    if (effect < 150) return 'Good';
    if (effect < 200) return 'Average';
    return 'Keep practicing';
  }
}
