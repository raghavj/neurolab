import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/theme.dart';
import '../../widgets/brain_visualization.dart';

enum TrailMakingState {
  instructions,
  ready,
  playing,
  error,
  completed,
}

enum TrailMakingPart {
  partA, // Numbers only: 1-2-3-4-5...
  partB, // Alternating: 1-A-2-B-3-C...
}

class TrailMakingTestScreen extends StatefulWidget {
  const TrailMakingTestScreen({super.key});

  @override
  State<TrailMakingTestScreen> createState() => _TrailMakingTestScreenState();
}

class _TrailMakingTestScreenState extends State<TrailMakingTestScreen> {
  static const int nodeCount = 12;

  TrailMakingState _state = TrailMakingState.instructions;
  TrailMakingPart _currentPart = TrailMakingPart.partA;

  List<_TrailNode> _nodes = [];
  int _currentIndex = 0;
  List<Offset> _pathPoints = [];
  Offset? _currentTouchPoint;

  DateTime? _startTime;
  int? _partATime;
  int? _partBTime;
  int _partAErrors = 0;
  int _partBErrors = 0;

  Timer? _errorTimer;
  Size? _gridSize;

  @override
  void dispose() {
    _errorTimer?.cancel();
    super.dispose();
  }

  void _generateNodes() {
    final random = Random();
    _nodes = [];
    _pathPoints = [];
    _currentIndex = 0;

    // Generate labels based on part
    List<String> labels;
    if (_currentPart == TrailMakingPart.partA) {
      labels = List.generate(nodeCount, (i) => '${i + 1}');
    } else {
      labels = [];
      for (int i = 0; i < nodeCount ~/ 2; i++) {
        labels.add('${i + 1}');
        labels.add(String.fromCharCode(65 + i)); // A, B, C...
      }
    }

    // Generate random positions with minimum spacing
    const double nodeRadius = 24;
    const double minSpacing = 70;
    const double padding = 40;

    final size = _gridSize ?? const Size(300, 400);
    final maxX = size.width - padding * 2;
    final maxY = size.height - padding * 2;

    for (int i = 0; i < labels.length; i++) {
      Offset position;
      bool validPosition;
      int attempts = 0;

      do {
        validPosition = true;
        position = Offset(
          padding + random.nextDouble() * maxX,
          padding + random.nextDouble() * maxY,
        );

        // Check distance from other nodes
        for (final node in _nodes) {
          final distance = (position - node.position).distance;
          if (distance < minSpacing) {
            validPosition = false;
            break;
          }
        }

        attempts++;
        if (attempts > 100) break; // Prevent infinite loop
      } while (!validPosition);

      _nodes.add(_TrailNode(
        label: labels[i],
        position: position,
        index: i,
      ));
    }
  }

  void _startPart() {
    _generateNodes();
    setState(() {
      _state = TrailMakingState.ready;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _state = TrailMakingState.playing;
          _startTime = DateTime.now();
        });
      }
    });
  }

  void _handleNodeTap(_TrailNode node) {
    if (_state != TrailMakingState.playing) return;

    if (node.index == _currentIndex) {
      // Correct!
      HapticFeedback.lightImpact();

      setState(() {
        _nodes[node.index] = node.copyWith(isCompleted: true);
        _pathPoints.add(node.position);
        _currentIndex++;
      });

      // Check if part is complete
      if (_currentIndex >= _nodes.length) {
        _completePart();
      }
    } else if (node.index > _currentIndex) {
      // Wrong node - show error
      HapticFeedback.heavyImpact();

      if (_currentPart == TrailMakingPart.partA) {
        _partAErrors++;
      } else {
        _partBErrors++;
      }

      setState(() {
        _state = TrailMakingState.error;
        _nodes[node.index] = node.copyWith(isError: true);
      });

      _errorTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _state = TrailMakingState.playing;
            _nodes[node.index] = node.copyWith(isError: false);
          });
        }
      });
    }
  }

  void _completePart() {
    final elapsed = DateTime.now().difference(_startTime!).inMilliseconds;

    if (_currentPart == TrailMakingPart.partA) {
      _partATime = elapsed;
      setState(() {
        _currentPart = TrailMakingPart.partB;
        _state = TrailMakingState.instructions;
      });
    } else {
      _partBTime = elapsed;
      _completeTest();
    }
  }

  Future<void> _completeTest() async {
    setState(() {
      _state = TrailMakingState.completed;
    });

    // Primary score is Part B time (executive function)
    // Also calculate B-A difference as a measure of cognitive flexibility
    final bMinusA = _partBTime! - _partATime!;

    final appState = context.read<AppState>();
    final result = TestResult(
      id: appState.generateId(),
      usernId: appState.currentUser!.id,
      testType: CognitiveTestType.trailMaking,
      timestamp: DateTime.now(),
      primaryScore: _partBTime!.toDouble(),
      primaryScoreUnit: 'ms',
      detailedMetrics: {
        'part_a_time': _partATime,
        'part_b_time': _partBTime,
        'b_minus_a': bMinusA,
        'part_a_errors': _partAErrors,
        'part_b_errors': _partBErrors,
      },
      trialCount: 2,
      correctTrials: 2,
    );

    await appState.saveTestResult(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _state == TrailMakingState.instructions ||
              _state == TrailMakingState.completed
          ? AppBar(
              title: const Text('Trail Making'),
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
      case TrailMakingState.instructions:
        return _buildInstructions();
      case TrailMakingState.ready:
        return _buildReadyScreen();
      case TrailMakingState.playing:
      case TrailMakingState.error:
        return _buildGameScreen();
      case TrailMakingState.completed:
        return _buildCompletedScreen();
    }
  }

  Widget _buildInstructions() {
    final isPartA = _currentPart == TrailMakingPart.partA;

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
                  Icons.timeline,
                  size: 64,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(height: 24),
                Text(
                  isPartA ? 'Trail Making - Part A' : 'Trail Making - Part B',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  isPartA
                      ? 'This test measures processing speed and visual attention.'
                      : 'This part measures cognitive flexibility and executive function.',
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
            isPartA ? 'Connect the numbers' : 'Alternate numbers & letters',
            isPartA
                ? 'Tap the circles in order: 1 → 2 → 3 → 4...'
                : 'Tap in alternating order: 1 → A → 2 → B → 3 → C...',
          ),
          const SizedBox(height: 16),
          _buildInstructionStep(
            '2',
            'Go as fast as you can',
            'Speed matters! Try to complete as quickly as possible.',
          ),
          const SizedBox(height: 16),
          _buildInstructionStep(
            '3',
            'Avoid mistakes',
            'Tapping the wrong circle will briefly show an error.',
          ),
          const SizedBox(height: 24),

          // Visual example
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Example Sequence',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: isPartA
                      ? [
                          _buildExampleNode('1'),
                          _buildArrow(),
                          _buildExampleNode('2'),
                          _buildArrow(),
                          _buildExampleNode('3'),
                          _buildArrow(),
                          _buildExampleNode('4'),
                        ]
                      : [
                          _buildExampleNode('1'),
                          _buildArrow(),
                          _buildExampleNode('A'),
                          _buildArrow(),
                          _buildExampleNode('2'),
                          _buildArrow(),
                          _buildExampleNode('B'),
                        ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startPart,
              child: Text(isPartA ? 'Start Part A' : 'Start Part B'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleNode(String label) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.arrow_forward,
        size: 16,
        color: AppTheme.textMuted,
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
            _currentPart == TrailMakingPart.partA
                ? 'Connect: 1 → 2 → 3 → 4...'
                : 'Alternate: 1 → A → 2 → B...',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currentPart == TrailMakingPart.partA ? 'Part A' : 'Part B',
                  style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Next: ${_currentIndex < _nodes.length ? _nodes[_currentIndex].label : "Done"}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${_currentIndex}/${_nodes.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),

        // Game area
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (_gridSize == null ||
                  _gridSize!.width != constraints.maxWidth ||
                  _gridSize!.height != constraints.maxHeight) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    _gridSize = Size(constraints.maxWidth, constraints.maxHeight);
                    if (_nodes.isEmpty) {
                      _generateNodes();
                    }
                  });
                });
              }

              return Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Path lines
                      if (_pathPoints.length >= 2)
                        CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: _PathPainter(_pathPoints),
                        ),

                      // Nodes
                      ..._nodes.map((node) => Positioned(
                            left: node.position.dx - 24,
                            top: node.position.dy - 24,
                            child: _buildNode(node),
                          )),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Error indicator
        if (_state == TrailMakingState.error)
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Wrong! Find the correct next circle.',
              style: TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNode(_TrailNode node) {
    Color backgroundColor;
    Color textColor = Colors.white;
    Color borderColor = Colors.transparent;

    if (node.isCompleted) {
      backgroundColor = AppTheme.success;
    } else if (node.isError) {
      backgroundColor = AppTheme.error;
    } else if (node.index == _currentIndex) {
      backgroundColor = AppTheme.primaryBlue;
      borderColor = Colors.white;
    } else {
      backgroundColor = AppTheme.surfaceMedium;
      textColor = AppTheme.textPrimary;
    }

    return GestureDetector(
      onTap: () => _handleNodeTap(node),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 3),
          boxShadow: node.index == _currentIndex
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            node.label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedScreen() {
    final partASeconds = _partATime! / 1000;
    final partBSeconds = _partBTime! / 1000;
    final bMinusA = (_partBTime! - _partATime!) / 1000;

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

          // Part B (primary metric)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  'Part B Time',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${partBSeconds.toStringAsFixed(1)}s',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getSpeedFeedback(partBSeconds),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.accentTeal,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Comparison
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Part A',
                  '${partASeconds.toStringAsFixed(1)}s',
                  'Numbers only',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'B - A',
                  '${bMinusA.toStringAsFixed(1)}s',
                  'Switching cost',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Part A Errors',
                  '$_partAErrors',
                  '',
                  color: _partAErrors > 2 ? AppTheme.error : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Part B Errors',
                  '$_partBErrors',
                  '',
                  color: _partBErrors > 2 ? AppTheme.error : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Explanation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.accentTeal,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What This Measures',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.accentTeal,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Part B requires switching between numbers and letters, measuring cognitive flexibility. The B-A difference reflects your "switching cost."',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Brain visualization
          const BrainActivationCard(
            testType: CognitiveTestType.trailMaking,
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
            onPressed: () {
              setState(() {
                _currentPart = TrailMakingPart.partA;
                _state = TrailMakingState.instructions;
                _partATime = null;
                _partBTime = null;
                _partAErrors = 0;
                _partBErrors = 0;
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String subtitle,
      {Color? color}) {
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
          if (subtitle.isNotEmpty)
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

  String _getSpeedFeedback(double seconds) {
    if (seconds < 20) return 'Excellent!';
    if (seconds < 30) return 'Very Good';
    if (seconds < 45) return 'Good';
    if (seconds < 60) return 'Average';
    return 'Keep practicing';
  }
}

class _TrailNode {
  final String label;
  final Offset position;
  final int index;
  final bool isCompleted;
  final bool isError;

  _TrailNode({
    required this.label,
    required this.position,
    required this.index,
    this.isCompleted = false,
    this.isError = false,
  });

  _TrailNode copyWith({
    bool? isCompleted,
    bool? isError,
  }) {
    return _TrailNode(
      label: label,
      position: position,
      index: index,
      isCompleted: isCompleted ?? this.isCompleted,
      isError: isError ?? this.isError,
    );
  }
}

class _PathPainter extends CustomPainter {
  final List<Offset> points;

  _PathPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = AppTheme.success
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
