import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import 'database_service.dart';

enum ExportFormat { csv, json }

class ExportService {
  final DatabaseService _db = DatabaseService();

  Future<String> exportTestResults(String userId, ExportFormat format) async {
    final results = await _db.getAllTestResults(userId);

    if (format == ExportFormat.csv) {
      return _testResultsToCsv(results);
    } else {
      return _testResultsToJson(results);
    }
  }

  Future<String> exportLifestyleLogs(String userId, ExportFormat format) async {
    final logs = await _db.getLifestyleLogs(userId, days: 365);

    if (format == ExportFormat.csv) {
      return _lifestyleLogsToCsv(logs);
    } else {
      return _lifestyleLogsToJson(logs);
    }
  }

  Future<String> exportAll(String userId, ExportFormat format) async {
    final results = await _db.getAllTestResults(userId);
    final logs = await _db.getLifestyleLogs(userId, days: 365);
    final experiments = await _db.getExperiments(userId);

    if (format == ExportFormat.json) {
      return _allDataToJson(results, logs, experiments);
    } else {
      // For CSV, we'll return test results by default since CSV doesn't handle nested data well
      return _testResultsToCsv(results);
    }
  }

  String _testResultsToCsv(List<TestResult> results) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('id,test_type,timestamp,primary_score,primary_score_unit,accuracy,trial_count,correct_trials,experiment_id,notes');

    // Data rows
    for (final result in results) {
      buffer.writeln([
        result.id,
        result.testType.name,
        result.timestamp.toIso8601String(),
        result.primaryScore,
        result.primaryScoreUnit,
        result.accuracy,
        result.trialCount,
        result.correctTrials,
        result.experimentId ?? '',
        '"${result.notes?.replaceAll('"', '""') ?? ''}"',
      ].join(','));
    }

    return buffer.toString();
  }

  String _testResultsToJson(List<TestResult> results) {
    final data = results.map((r) => {
      'id': r.id,
      'testType': r.testType.name,
      'timestamp': r.timestamp.toIso8601String(),
      'primaryScore': r.primaryScore,
      'primaryScoreUnit': r.primaryScoreUnit,
      'accuracy': r.accuracy,
      'trialCount': r.trialCount,
      'correctTrials': r.correctTrials,
      'experimentId': r.experimentId,
      'notes': r.notes,
      'detailedMetrics': r.detailedMetrics,
    }).toList();

    return const JsonEncoder.withIndent('  ').convert({
      'exportDate': DateTime.now().toIso8601String(),
      'dataType': 'test_results',
      'count': results.length,
      'results': data,
    });
  }

  String _lifestyleLogsToCsv(List<LifestyleLog> logs) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('id,date,sleep_hours,sleep_quality,caffeine_intake,exercise_minutes,exercise_intensity,stress_level,mood_level,energy_level,meditation_minutes,notes');

    // Data rows
    for (final log in logs) {
      buffer.writeln([
        log.id,
        log.date.toIso8601String().split('T')[0],
        log.sleepHours ?? '',
        log.sleepQuality ?? '',
        log.caffeineIntake ?? '',
        log.exerciseMinutes ?? '',
        log.exerciseIntensity ?? '',
        log.stressLevel ?? '',
        log.moodLevel ?? '',
        log.energyLevel ?? '',
        log.meditationMinutes ?? '',
        '"${log.notes?.replaceAll('"', '""') ?? ''}"',
      ].join(','));
    }

    return buffer.toString();
  }

  String _lifestyleLogsToJson(List<LifestyleLog> logs) {
    final data = logs.map((l) => {
      'id': l.id,
      'date': l.date.toIso8601String().split('T')[0],
      'sleepHours': l.sleepHours,
      'sleepQuality': l.sleepQuality,
      'caffeineIntake': l.caffeineIntake,
      'exerciseMinutes': l.exerciseMinutes,
      'exerciseIntensity': l.exerciseIntensity,
      'stressLevel': l.stressLevel,
      'moodLevel': l.moodLevel,
      'energyLevel': l.energyLevel,
      'meditationMinutes': l.meditationMinutes,
      'notes': l.notes,
    }).toList();

    return const JsonEncoder.withIndent('  ').convert({
      'exportDate': DateTime.now().toIso8601String(),
      'dataType': 'lifestyle_logs',
      'count': logs.length,
      'logs': data,
    });
  }

  String _allDataToJson(
    List<TestResult> results,
    List<LifestyleLog> logs,
    List<Experiment> experiments,
  ) {
    return const JsonEncoder.withIndent('  ').convert({
      'exportDate': DateTime.now().toIso8601String(),
      'appName': 'NeuroLab',
      'testResults': {
        'count': results.length,
        'data': results.map((r) => {
          'id': r.id,
          'testType': r.testType.name,
          'timestamp': r.timestamp.toIso8601String(),
          'primaryScore': r.primaryScore,
          'primaryScoreUnit': r.primaryScoreUnit,
          'accuracy': r.accuracy,
          'trialCount': r.trialCount,
          'correctTrials': r.correctTrials,
          'experimentId': r.experimentId,
          'notes': r.notes,
          'detailedMetrics': r.detailedMetrics,
        }).toList(),
      },
      'lifestyleLogs': {
        'count': logs.length,
        'data': logs.map((l) => {
          'id': l.id,
          'date': l.date.toIso8601String().split('T')[0],
          'sleepHours': l.sleepHours,
          'sleepQuality': l.sleepQuality,
          'caffeineIntake': l.caffeineIntake,
          'exerciseMinutes': l.exerciseMinutes,
          'exerciseIntensity': l.exerciseIntensity,
          'stressLevel': l.stressLevel,
          'moodLevel': l.moodLevel,
          'energyLevel': l.energyLevel,
          'meditationMinutes': l.meditationMinutes,
          'notes': l.notes,
        }).toList(),
      },
      'experiments': {
        'count': experiments.length,
        'data': experiments.map((e) => {
          'id': e.id,
          'title': e.title,
          'hypothesis': e.hypothesis,
          'intervention': e.intervention,
          'targetTest': e.targetTest.name,
          'status': e.status.name,
          'createdAt': e.createdAt.toIso8601String(),
          'startedAt': e.startedAt?.toIso8601String(),
          'completedAt': e.completedAt?.toIso8601String(),
          'baselineDays': e.baselineDays,
          'interventionDays': e.interventionDays,
          'currentDay': e.currentDay,
        }).toList(),
      },
    });
  }

  Future<void> shareExport(String content, String filename) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(content);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'NeuroLab Data Export',
    );
  }
}
