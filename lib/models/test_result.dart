enum CognitiveTestType {
  reactionTime,
  nBack,
  stroop,
  trailMaking,
  flanker,
}

extension CognitiveTestTypeExtension on CognitiveTestType {
  String get displayName {
    switch (this) {
      case CognitiveTestType.reactionTime:
        return 'Reaction Time';
      case CognitiveTestType.nBack:
        return 'N-Back';
      case CognitiveTestType.stroop:
        return 'Stroop';
      case CognitiveTestType.trailMaking:
        return 'Trail Making';
      case CognitiveTestType.flanker:
        return 'Flanker';
    }
  }

  String get description {
    switch (this) {
      case CognitiveTestType.reactionTime:
        return 'Measures alertness and processing speed';
      case CognitiveTestType.nBack:
        return 'Tests working memory capacity';
      case CognitiveTestType.stroop:
        return 'Evaluates cognitive control and inhibition';
      case CognitiveTestType.trailMaking:
        return 'Assesses executive function and mental flexibility';
      case CognitiveTestType.flanker:
        return 'Measures selective attention and response inhibition';
    }
  }

  String get brainRegions {
    switch (this) {
      case CognitiveTestType.reactionTime:
        return 'Motor cortex, basal ganglia, reticular activating system';
      case CognitiveTestType.nBack:
        return 'Dorsolateral prefrontal cortex, parietal cortex';
      case CognitiveTestType.stroop:
        return 'Anterior cingulate cortex, dorsolateral prefrontal cortex';
      case CognitiveTestType.trailMaking:
        return 'Prefrontal cortex, parietal lobe';
      case CognitiveTestType.flanker:
        return 'Anterior cingulate cortex, lateral prefrontal cortex';
    }
  }
}

class TestResult {
  final String id;
  final String usernId;
  final CognitiveTestType testType;
  final DateTime timestamp;
  final double primaryScore;
  final String primaryScoreUnit;
  final Map<String, dynamic> detailedMetrics;
  final int trialCount;
  final int correctTrials;
  final String? experimentId;
  final String? notes;

  TestResult({
    required this.id,
    required this.usernId,
    required this.testType,
    required this.timestamp,
    required this.primaryScore,
    required this.primaryScoreUnit,
    required this.detailedMetrics,
    required this.trialCount,
    required this.correctTrials,
    this.experimentId,
    this.notes,
  });

  double get accuracy => trialCount > 0 ? correctTrials / trialCount : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': usernId,
      'test_type': testType.index,
      'timestamp': timestamp.toIso8601String(),
      'primary_score': primaryScore,
      'primary_score_unit': primaryScoreUnit,
      'detailed_metrics': detailedMetrics.toString(),
      'trial_count': trialCount,
      'correct_trials': correctTrials,
      'experiment_id': experimentId,
      'notes': notes,
    };
  }

  factory TestResult.fromMap(Map<String, dynamic> map) {
    return TestResult(
      id: map['id'] as String,
      usernId: map['user_id'] as String,
      testType: CognitiveTestType.values[map['test_type'] as int],
      timestamp: DateTime.parse(map['timestamp'] as String),
      primaryScore: (map['primary_score'] as num).toDouble(),
      primaryScoreUnit: map['primary_score_unit'] as String,
      detailedMetrics: {},
      trialCount: map['trial_count'] as int,
      correctTrials: map['correct_trials'] as int,
      experimentId: map['experiment_id'] as String?,
      notes: map['notes'] as String?,
    );
  }
}

class ReactionTimeResult extends TestResult {
  final List<int> reactionTimes;
  final int falseStarts;
  final int missedTrials;

  ReactionTimeResult({
    required super.id,
    required super.usernId,
    required super.timestamp,
    required this.reactionTimes,
    required this.falseStarts,
    required this.missedTrials,
    super.experimentId,
    super.notes,
  }) : super(
          testType: CognitiveTestType.reactionTime,
          primaryScore: _calculateMedian(reactionTimes),
          primaryScoreUnit: 'ms',
          detailedMetrics: {
            'reaction_times': reactionTimes,
            'false_starts': falseStarts,
            'missed_trials': missedTrials,
            'mean': _calculateMean(reactionTimes),
            'median': _calculateMedian(reactionTimes),
            'fastest': reactionTimes.isNotEmpty
                ? reactionTimes.reduce((a, b) => a < b ? a : b)
                : 0,
            'slowest': reactionTimes.isNotEmpty
                ? reactionTimes.reduce((a, b) => a > b ? a : b)
                : 0,
          },
          trialCount: reactionTimes.length + missedTrials,
          correctTrials: reactionTimes.length,
        );

  static double _calculateMean(List<int> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double _calculateMedian(List<int> values) {
    if (values.isEmpty) return 0;
    final sorted = List<int>.from(values)..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[middle].toDouble();
    }
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }

  double get meanReactionTime => detailedMetrics['mean'] as double;
  double get medianReactionTime => detailedMetrics['median'] as double;
  int get fastestReactionTime => detailedMetrics['fastest'] as int;
  int get slowestReactionTime => detailedMetrics['slowest'] as int;
}
