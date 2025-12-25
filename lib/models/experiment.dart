import 'test_result.dart';

enum ExperimentStatus {
  draft,
  baseline,
  intervention,
  completed,
  cancelled,
}

extension ExperimentStatusExtension on ExperimentStatus {
  String get displayName {
    switch (this) {
      case ExperimentStatus.draft:
        return 'Draft';
      case ExperimentStatus.baseline:
        return 'Baseline Phase';
      case ExperimentStatus.intervention:
        return 'Intervention Phase';
      case ExperimentStatus.completed:
        return 'Completed';
      case ExperimentStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class Experiment {
  final String id;
  final String userId;
  final String title;
  final String hypothesis;
  final String intervention;
  final CognitiveTestType targetTest;
  final ExperimentStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int baselineDays;
  final int interventionDays;
  final List<String> notes;

  Experiment({
    required this.id,
    required this.userId,
    required this.title,
    required this.hypothesis,
    required this.intervention,
    required this.targetTest,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.baselineDays = 7,
    this.interventionDays = 14,
    List<String>? notes,
  }) : notes = notes ?? [];

  int get totalDays => baselineDays + interventionDays;

  int? get currentDay {
    if (startedAt == null) return null;
    return DateTime.now().difference(startedAt!).inDays + 1;
  }

  bool get isInBaseline {
    final day = currentDay;
    return day != null && day <= baselineDays;
  }

  bool get isInIntervention {
    final day = currentDay;
    return day != null && day > baselineDays && day <= totalDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'hypothesis': hypothesis,
      'intervention': intervention,
      'target_test': targetTest.index,
      'status': status.index,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'baseline_days': baselineDays,
      'intervention_days': interventionDays,
    };
  }

  factory Experiment.fromMap(Map<String, dynamic> map) {
    return Experiment(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      hypothesis: map['hypothesis'] as String,
      intervention: map['intervention'] as String,
      targetTest: CognitiveTestType.values[map['target_test'] as int],
      status: ExperimentStatus.values[map['status'] as int],
      createdAt: DateTime.parse(map['created_at'] as String),
      startedAt: map['started_at'] != null
          ? DateTime.parse(map['started_at'] as String)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      baselineDays: map['baseline_days'] as int,
      interventionDays: map['intervention_days'] as int,
    );
  }

  Experiment copyWith({
    String? title,
    String? hypothesis,
    String? intervention,
    CognitiveTestType? targetTest,
    ExperimentStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    int? baselineDays,
    int? interventionDays,
    List<String>? notes,
  }) {
    return Experiment(
      id: id,
      userId: userId,
      title: title ?? this.title,
      hypothesis: hypothesis ?? this.hypothesis,
      intervention: intervention ?? this.intervention,
      targetTest: targetTest ?? this.targetTest,
      status: status ?? this.status,
      createdAt: createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      baselineDays: baselineDays ?? this.baselineDays,
      interventionDays: interventionDays ?? this.interventionDays,
      notes: notes ?? this.notes,
    );
  }
}

// Pre-defined experiment templates
class ExperimentTemplate {
  final String title;
  final String hypothesis;
  final String intervention;
  final CognitiveTestType targetTest;
  final int baselineDays;
  final int interventionDays;
  final String description;

  const ExperimentTemplate({
    required this.title,
    required this.hypothesis,
    required this.intervention,
    required this.targetTest,
    required this.baselineDays,
    required this.interventionDays,
    required this.description,
  });
}

const experimentTemplates = [
  ExperimentTemplate(
    title: 'Morning Meditation',
    hypothesis: 'Daily morning meditation will improve my focus and reaction time',
    intervention: '10 minutes of guided meditation each morning before testing',
    targetTest: CognitiveTestType.reactionTime,
    baselineDays: 7,
    interventionDays: 14,
    description: 'Explore how a consistent meditation practice affects your alertness and processing speed.',
  ),
  ExperimentTemplate(
    title: 'Caffeine Timing',
    hypothesis: 'Delaying caffeine intake by 90 minutes after waking will improve sustained attention',
    intervention: 'Wait 90 minutes after waking before consuming caffeine',
    targetTest: CognitiveTestType.reactionTime,
    baselineDays: 5,
    interventionDays: 10,
    description: 'Test the popular theory that delaying caffeine helps avoid the afternoon crash.',
  ),
  ExperimentTemplate(
    title: 'Sleep Optimization',
    hypothesis: 'Consistent 8-hour sleep will improve working memory performance',
    intervention: 'Maintain strict 8-hour sleep schedule with consistent bed/wake times',
    targetTest: CognitiveTestType.nBack,
    baselineDays: 7,
    interventionDays: 14,
    description: 'Discover how sleep consistency affects your cognitive performance.',
  ),
  ExperimentTemplate(
    title: 'Exercise Timing',
    hypothesis: 'Morning exercise will improve cognitive performance throughout the day',
    intervention: '20 minutes of cardio exercise within 1 hour of waking',
    targetTest: CognitiveTestType.flanker,
    baselineDays: 7,
    interventionDays: 14,
    description: 'Test whether morning exercise gives you a cognitive boost for the day.',
  ),
];
