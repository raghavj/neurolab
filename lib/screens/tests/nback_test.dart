import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/theme.dart';
import '../../widgets/brain_visualization.dart';

enum NBackState {
  instructions,
  ready,
  showStimulus,
  waitResponse,
  feedback,
  completed,
}

class NBackTestScreen extends StatefulWidget {
  const NBackTestScreen({super.key});

  @override
  State<NBackTestScreen> createState() => _NBackTestScreenState();
}

class _NBackTestScreenState extends State<NBackTestScreen> {
  static const int nLevel = 2; // 2-back
  static const int totalTrials = 25;
  static const int stimulusDurationMs = 500;
  static const int interStimulusMs = 2000;
  static const double matchProbability = 0.33;

  NBackState _state = NBackState.instructions;
  int _currentTrial = 0;
  final List<int> _sequence = [];
  final List<bool> _isMatch = [];
  final List<bool?> _responses = [];

  int? _currentPosition;
  Timer? _trialTimer;
  bool _canRespond = false;
  bool? _lastFeedback;

  final Random _random = Random();

  // Statistics
  int get hits => _countHits();
  int get misses => _countMisses();
  int get falseAlarms => _countFalseAlarms();
  int get correctRejections => _countCorrectRejections();

  @override
  void dispose() {
    _trialTimer?.cancel();
    super.dispose();
  }

  void _generateSequence() {
    _sequence.clear();
    _isMatch.clear();
    _responses.clear();

    for (int i = 0; i < totalTrials; i++) {
      if (i < nLevel) {
        // First N trials can't be matches
        _sequence.add(_random.nextInt(9));
        _isMatch.add(false);
      } else {
        // Decide if this should be a match
        bool shouldMatch = _random.nextDouble() < matchProbability;

        if (shouldMatch) {
          _sequence.add(_sequence[i - nLevel]);
          _isMatch.add(true);
        } else {
          // Generate non-matching position
          int newPos;
          do {
            newPos = _random.nextInt(9);
          } while (newPos == _sequence[i - nLevel]);
          _sequence.add(newPos);
          _isMatch.add(false);
        }
      }
      _responses.add(null);
    }
  }

  void _startTest() {
    _generateSequence();
    setState(() {
      _state = NBackState.ready;
      _currentTrial = 0;
    });

    Future.delayed(const Duration(seconds: 2), () {
      _runTrial();
    });
  }

  void _runTrial() {
    if (_currentTrial >= totalTrials) {
      _completeTest();
      return;
    }

    // Show stimulus
    setState(() {
      _state = NBackState.showStimulus;
      _currentPosition = _sequence[_currentTrial];
      _canRespond = _currentTrial >= nLevel;
      _lastFeedback = null;
    });

    HapticFeedback.lightImpact();

    // Hide stimulus after duration
    _trialTimer = Timer(const Duration(milliseconds: stimulusDurationMs), () {
      setState(() {
        _state = NBackState.waitResponse;
        _currentPosition = null;
      });

      // Wait for response window
      _trialTimer = Timer(const Duration(milliseconds: interStimulusMs), () {
        _nextTrial();
      });
    });
  }

  void _handleMatch() {
    if (!_canRespond || _responses[_currentTrial] != null) return;

    _trialTimer?.cancel();
    HapticFeedback.mediumImpact();

    setState(() {
      _responses[_currentTrial] = true;
      _lastFeedback = _isMatch[_currentTrial]; // true if correct
      _state = NBackState.feedback;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      _nextTrial();
    });
  }

  void _nextTrial() {
    // If no response was given, mark as null (no response)
    _currentTrial++;
    if (_currentTrial >= totalTrials) {
      _completeTest();
    } else {
      _runTrial();
    }
  }

  Future<void> _completeTest() async {
    setState(() {
      _state = NBackState.completed;
    });

    // Calculate accuracy
    final accuracy = (hits + correctRejections) / totalTrials;

    // Save result
    final appState = context.read<AppState>();
    final result = TestResult(
      id: appState.generateId(),
      usernId: appState.currentUser!.id,
      testType: CognitiveTestType.nBack,
      timestamp: DateTime.now(),
      primaryScore: accuracy * 100,
      primaryScoreUnit: '%',
      detailedMetrics: {
        'n_level': nLevel,
        'hits': hits,
        'misses': misses,
        'false_alarms': falseAlarms,
        'correct_rejections': correctRejections,
        'd_prime': _calculateDPrime(),
      },
      trialCount: totalTrials,
      correctTrials: hits + correctRejections,
    );

    await appState.saveTestResult(result);
  }

  int _countHits() {
    int count = 0;
    for (int i = nLevel; i < totalTrials; i++) {
      if (_isMatch[i] && _responses[i] == true) count++;
    }
    return count;
  }

  int _countMisses() {
    int count = 0;
    for (int i = nLevel; i < totalTrials; i++) {
      if (_isMatch[i] && _responses[i] != true) count++;
    }
    return count;
  }

  int _countFalseAlarms() {
    int count = 0;
    for (int i = nLevel; i < totalTrials; i++) {
      if (!_isMatch[i] && _responses[i] == true) count++;
    }
    return count;
  }

  int _countCorrectRejections() {
    int count = 0;
    for (int i = nLevel; i < totalTrials; i++) {
      if (!_isMatch[i] && _responses[i] != true) count++;
    }
    return count;
  }

  double _calculateDPrime() {
    // Calculate d' (d-prime) - a measure of sensitivity
    final totalMatches = _isMatch.where((m) => m).length;
    final totalNonMatches = totalTrials - nLevel - totalMatches;

    if (totalMatches == 0 || totalNonMatches == 0) return 0;

    double hitRate = hits / totalMatches;
    double faRate = falseAlarms / totalNonMatches;

    // Correct for extreme values
    hitRate = hitRate.clamp(0.01, 0.99);
    faRate = faRate.clamp(0.01, 0.99);

    // Z-score transformation (approximation)
    double zHit = _normalInverse(hitRate);
    double zFa = _normalInverse(faRate);

    return zHit - zFa;
  }

  double _normalInverse(double p) {
    // Approximation of inverse normal CDF
    double a = 0.147;
    double x = 2 * p - 1;
    double lnTerm = log(1 - x * x);
    double term1 = (2 / (pi * a)) + (lnTerm / 2);
    double term2 = lnTerm / a;
    return x.sign * sqrt(sqrt(term1 * term1 - term2) - term1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _state == NBackState.instructions || _state == NBackState.completed
          ? AppBar(
              title: const Text('N-Back'),
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
      case NBackState.instructions:
        return _buildInstructions();
      case NBackState.ready:
        return _buildReadyScreen();
      case NBackState.showStimulus:
      case NBackState.waitResponse:
      case NBackState.feedback:
        return _buildGameScreen();
      case NBackState.completed:
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
                  Icons.grid_view,
                  size: 64,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(height: 24),
                Text(
                  '$nLevel-Back Test',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'This test measures your working memory capacity.',
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
            'Watch the grid',
            'A square will light up briefly in the 3x3 grid.',
          ),
          const SizedBox(height: 16),
          _buildInstructionStep(
            '2',
            'Remember $nLevel back',
            'Compare the current position to where it was $nLevel steps ago.',
          ),
          const SizedBox(height: 16),
          _buildInstructionStep(
            '3',
            'Tap for matches',
            'If the position matches $nLevel steps back, tap the "Match" button.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppTheme.accentTeal),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'The first $nLevel positions are practice - just watch and remember!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
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
            'Watch the grid carefully',
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
              if (_lastFeedback != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _lastFeedback!
                        ? AppTheme.success.withValues(alpha: 0.2)
                        : AppTheme.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _lastFeedback! ? 'Correct!' : 'Wrong',
                    style: TextStyle(
                      color: _lastFeedback! ? AppTheme.success : AppTheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const Spacer(),

        // 3x3 Grid
        Center(
          child: Container(
            width: 280,
            height: 280,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                final isActive = _currentPosition == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primaryBlue
                        : AppTheme.surfaceMedium,
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              },
            ),
          ),
        ),

        const Spacer(),

        // Match button
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              if (_currentTrial < nLevel)
                Text(
                  'Watch and remember...',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _canRespond && _responses[_currentTrial] == null
                        ? _handleMatch
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentTeal,
                    ),
                    child: const Text(
                      'MATCH',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                _currentTrial >= nLevel
                    ? 'Tap if this matches $nLevel positions ago'
                    : 'Trial ${_currentTrial + 1} of $nLevel practice rounds',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedScreen() {
    final accuracy = (hits + correctRejections) / (totalTrials - nLevel) * 100;
    final dPrime = _calculateDPrime();

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
                  'Accuracy',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${accuracy.round()}%',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getAccuracyFeedback(accuracy),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentTeal,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Signal Detection metrics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signal Detection',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Hits',
                        '$hits',
                        'Correct matches',
                        AppTheme.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricItem(
                        'Misses',
                        '$misses',
                        'Missed matches',
                        AppTheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'False Alarms',
                        '$falseAlarms',
                        'Wrong matches',
                        AppTheme.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricItem(
                        'Correct Rej.',
                        '$correctRejections',
                        'Right non-matches',
                        AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // d-prime
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "d' (Sensitivity)",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'How well you distinguish matches from non-matches',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  dPrime.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.primaryBlue,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Brain visualization
          const BrainActivationCard(
            testType: CognitiveTestType.nBack,
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

  Widget _buildMetricItem(
    String label,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }

  String _getAccuracyFeedback(double accuracy) {
    if (accuracy >= 90) return 'Excellent!';
    if (accuracy >= 80) return 'Very Good';
    if (accuracy >= 70) return 'Good';
    if (accuracy >= 60) return 'Average';
    return 'Keep practicing';
  }
}
