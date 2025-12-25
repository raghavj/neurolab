import 'dart:math';
import '../models/models.dart';
import 'database_service.dart';

enum InsightType {
  sleepDuration,
  sleepQuality,
  caffeine,
  exercise,
  stress,
  mood,
  energy,
  meditation,
  timeOfDay,
  dayOfWeek,
}

enum InsightDirection {
  positive, // Higher factor = better performance
  negative, // Higher factor = worse performance
  neutral,
}

class Insight {
  final InsightType type;
  final CognitiveTestType testType;
  final String title;
  final String description;
  final double effectSize; // Percentage difference
  final InsightDirection direction;
  final double confidence; // 0-1 statistical confidence
  final int sampleSize;
  final Map<String, dynamic> details;

  Insight({
    required this.type,
    required this.testType,
    required this.title,
    required this.description,
    required this.effectSize,
    required this.direction,
    required this.confidence,
    required this.sampleSize,
    this.details = const {},
  });

  bool get isSignificant => confidence >= 0.7 && effectSize.abs() >= 5;
}

class InsightsService {
  final DatabaseService _db = DatabaseService();

  Future<List<Insight>> generateInsights(String userId) async {
    final insights = <Insight>[];

    // Get all test results and lifestyle logs
    final testResults = await _db.getTestResults(userId);
    final lifestyleLogs = await _db.getLifestyleLogs(userId);

    if (testResults.length < 5 || lifestyleLogs.length < 3) {
      return insights; // Not enough data
    }

    // Create a map of date -> lifestyle log for quick lookup
    final logsByDate = <String, LifestyleLog>{};
    for (final log in lifestyleLogs) {
      final dateKey = _dateKey(log.date);
      logsByDate[dateKey] = log;
    }

    // Analyze each test type
    for (final testType in CognitiveTestType.values) {
      final testsOfType = testResults.where((t) => t.testType == testType).toList();
      if (testsOfType.length < 5) continue;

      // Pair tests with lifestyle data
      final pairedData = <_PairedDataPoint>[];
      for (final test in testsOfType) {
        final dateKey = _dateKey(test.timestamp);
        final log = logsByDate[dateKey];
        if (log != null) {
          pairedData.add(_PairedDataPoint(test: test, log: log));
        }
      }

      if (pairedData.length < 5) continue;

      // Analyze various factors
      insights.addAll(_analyzeSleepDuration(pairedData, testType));
      insights.addAll(_analyzeSleepQuality(pairedData, testType));
      insights.addAll(_analyzeCaffeine(pairedData, testType));
      insights.addAll(_analyzeExercise(pairedData, testType));
      insights.addAll(_analyzeStress(pairedData, testType));
      insights.addAll(_analyzeMood(pairedData, testType));
      insights.addAll(_analyzeEnergy(pairedData, testType));
      insights.addAll(_analyzeMeditation(pairedData, testType));
    }

    // Analyze time-of-day patterns (doesn't need lifestyle data)
    for (final testType in CognitiveTestType.values) {
      final testsOfType = testResults.where((t) => t.testType == testType).toList();
      if (testsOfType.length >= 10) {
        insights.addAll(_analyzeTimeOfDay(testsOfType, testType));
      }
    }

    // Sort by effect size (most impactful first)
    insights.sort((a, b) => b.effectSize.abs().compareTo(a.effectSize.abs()));

    // Return only significant insights
    return insights.where((i) => i.isSignificant).toList();
  }

  String _dateKey(DateTime dt) => '${dt.year}-${dt.month}-${dt.day}';

  bool _isLowerBetter(CognitiveTestType type) {
    // For reaction time, lower is better
    return type == CognitiveTestType.reactionTime;
  }

  List<Insight> _analyzeSleepDuration(
    List<_PairedDataPoint> data,
    CognitiveTestType testType,
  ) {
    final validData = data.where((d) => d.log.sleepHours != null).toList();
    if (validData.length < 5) return [];

    // Split into good sleep (7+) vs poor sleep (<7)
    final goodSleep = validData.where((d) => d.log.sleepHours! >= 7).toList();
    final poorSleep = validData.where((d) => d.log.sleepHours! < 7).toList();

    if (goodSleep.length < 2 || poorSleep.length < 2) return [];

    final goodAvg = _average(goodSleep.map((d) => d.test.primaryScore));
    final poorAvg = _average(poorSleep.map((d) => d.test.primaryScore));

    final lowerBetter = _isLowerBetter(testType);
    double effectSize;
    InsightDirection direction;

    if (lowerBetter) {
      effectSize = ((poorAvg - goodAvg) / poorAvg) * 100;
      direction = goodAvg < poorAvg ? InsightDirection.positive : InsightDirection.negative;
    } else {
      effectSize = ((goodAvg - poorAvg) / poorAvg) * 100;
      direction = goodAvg > poorAvg ? InsightDirection.positive : InsightDirection.negative;
    }

    final confidence = _calculateConfidence(
      goodSleep.map((d) => d.test.primaryScore).toList(),
      poorSleep.map((d) => d.test.primaryScore).toList(),
    );

    if (effectSize.abs() < 3) return [];

    final betterWord = lowerBetter ? 'faster' : 'better';
    final description = direction == InsightDirection.positive
        ? 'Your ${testType.displayName.toLowerCase()} is ${effectSize.abs().round()}% $betterWord on days you sleep 7+ hours.'
        : 'Surprisingly, your ${testType.displayName.toLowerCase()} is ${effectSize.abs().round()}% $betterWord on days with less sleep.';

    return [
      Insight(
        type: InsightType.sleepDuration,
        testType: testType,
        title: 'Sleep Duration',
        description: description,
        effectSize: effectSize,
        direction: direction,
        confidence: confidence,
        sampleSize: validData.length,
        details: {
          'good_sleep_avg': goodAvg,
          'poor_sleep_avg': poorAvg,
          'good_sleep_count': goodSleep.length,
          'poor_sleep_count': poorSleep.length,
        },
      ),
    ];
  }

  List<Insight> _analyzeSleepQuality(
    List<_PairedDataPoint> data,
    CognitiveTestType testType,
  ) {
    final validData = data.where((d) => d.log.sleepQuality != null).toList();
    if (validData.length < 5) return [];

    final highQuality = validData.where((d) => d.log.sleepQuality! >= 4).toList();
    final lowQuality = validData.where((d) => d.log.sleepQuality! <= 2).toList();

    if (highQuality.length < 2 || lowQuality.length < 2) return [];

    final highAvg = _average(highQuality.map((d) => d.test.primaryScore));
    final lowAvg = _average(lowQuality.map((d) => d.test.primaryScore));

    final lowerBetter = _isLowerBetter(testType);
    double effectSize;
    InsightDirection direction;

    if (lowerBetter) {
      effectSize = ((lowAvg - highAvg) / lowAvg) * 100;
      direction = highAvg < lowAvg ? InsightDirection.positive : InsightDirection.negative;
    } else {
      effectSize = ((highAvg - lowAvg) / lowAvg) * 100;
      direction = highAvg > lowAvg ? InsightDirection.positive : InsightDirection.negative;
    }

    final confidence = _calculateConfidence(
      highQuality.map((d) => d.test.primaryScore).toList(),
      lowQuality.map((d) => d.test.primaryScore).toList(),
    );

    if (effectSize.abs() < 3) return [];

    final betterWord = lowerBetter ? 'faster' : 'better';

    return [
      Insight(
        type: InsightType.sleepQuality,
        testType: testType,
        title: 'Sleep Quality',
        description:
            'High-quality sleep improves your ${testType.displayName.toLowerCase()} by ${effectSize.abs().round()}%.',
        effectSize: effectSize,
        direction: direction,
        confidence: confidence,
        sampleSize: validData.length,
      ),
    ];
  }

  List<Insight> _analyzeCaffeine(
    List<_PairedDataPoint> data,
    CognitiveTestType testType,
  ) {
    final validData = data.where((d) => d.log.caffeineIntake != null).toList();
    if (validData.length < 5) return [];

    final withCaffeine = validData.where((d) => d.log.caffeineIntake! > 0).toList();
    final noCaffeine = validData.where((d) => d.log.caffeineIntake == 0).toList();

    if (withCaffeine.length < 2 || noCaffeine.length < 2) return [];

    final caffeineAvg = _average(withCaffeine.map((d) => d.test.primaryScore));
    final noAvg = _average(noCaffeine.map((d) => d.test.primaryScore));

    final lowerBetter = _isLowerBetter(testType);
    double effectSize;
    InsightDirection direction;

    if (lowerBetter) {
      effectSize = ((noAvg - caffeineAvg) / noAvg) * 100;
      direction = caffeineAvg < noAvg ? InsightDirection.positive : InsightDirection.negative;
    } else {
      effectSize = ((caffeineAvg - noAvg) / noAvg) * 100;
      direction = caffeineAvg > noAvg ? InsightDirection.positive : InsightDirection.negative;
    }

    final confidence = _calculateConfidence(
      withCaffeine.map((d) => d.test.primaryScore).toList(),
      noCaffeine.map((d) => d.test.primaryScore).toList(),
    );

    if (effectSize.abs() < 3) return [];

    final betterWord = lowerBetter ? 'faster' : 'higher';
    final desc = direction == InsightDirection.positive
        ? 'Caffeine boosts your ${testType.displayName.toLowerCase()} by ${effectSize.abs().round()}%.'
        : 'Your ${testType.displayName.toLowerCase()} is ${effectSize.abs().round()}% $betterWord without caffeine.';

    return [
      Insight(
        type: InsightType.caffeine,
        testType: testType,
        title: 'Caffeine Effect',
        description: desc,
        effectSize: effectSize,
        direction: direction,
        confidence: confidence,
        sampleSize: validData.length,
      ),
    ];
  }

  List<Insight> _analyzeExercise(
    List<_PairedDataPoint> data,
    CognitiveTestType testType,
  ) {
    final validData = data.where((d) => d.log.exerciseMinutes != null).toList();
    if (validData.length < 5) return [];

    final withExercise = validData.where((d) => d.log.exerciseMinutes! >= 20).toList();
    final noExercise = validData.where((d) => d.log.exerciseMinutes! < 10).toList();

    if (withExercise.length < 2 || noExercise.length < 2) return [];

    final exerciseAvg = _average(withExercise.map((d) => d.test.primaryScore));
    final noAvg = _average(noExercise.map((d) => d.test.primaryScore));

    final lowerBetter = _isLowerBetter(testType);
    double effectSize;
    InsightDirection direction;

    if (lowerBetter) {
      effectSize = ((noAvg - exerciseAvg) / noAvg) * 100;
      direction = exerciseAvg < noAvg ? InsightDirection.positive : InsightDirection.negative;
    } else {
      effectSize = ((exerciseAvg - noAvg) / noAvg) * 100;
      direction = exerciseAvg > noAvg ? InsightDirection.positive : InsightDirection.negative;
    }

    final confidence = _calculateConfidence(
      withExercise.map((d) => d.test.primaryScore).toList(),
      noExercise.map((d) => d.test.primaryScore).toList(),
    );

    if (effectSize.abs() < 3) return [];

    return [
      Insight(
        type: InsightType.exercise,
        testType: testType,
        title: 'Exercise Impact',
        description:
            'Exercise (20+ min) improves your ${testType.displayName.toLowerCase()} by ${effectSize.abs().round()}%.',
        effectSize: effectSize,
        direction: direction,
        confidence: confidence,
        sampleSize: validData.length,
      ),
    ];
  }

  List<Insight> _analyzeStress(
    List<_PairedDataPoint> data,
    CognitiveTestType testType,
  ) {
    final validData = data.where((d) => d.log.stressLevel != null).toList();
    if (validData.length < 5) return [];

    final highStress = validData.where((d) => d.log.stressLevel! >= 4).toList();
    final lowStress = validData.where((d) => d.log.stressLevel! <= 2).toList();

    if (highStress.length < 2 || lowStress.length < 2) return [];

    final highAvg = _average(highStress.map((d) => d.test.primaryScore));
    final lowAvg = _average(lowStress.map((d) => d.test.primaryScore));

    final lowerBetter = _isLowerBetter(testType);
    double effectSize;
    InsightDirection direction;

    if (lowerBetter) {
      effectSize = ((highAvg - lowAvg) / highAvg) * 100;
      direction = lowAvg < highAvg ? InsightDirection.positive : InsightDirection.negative;
    } else {
      effectSize = ((lowAvg - highAvg) / highAvg) * 100;
      direction = lowAvg > highAvg ? InsightDirection.positive : InsightDirection.negative;
    }

    final confidence = _calculateConfidence(
      lowStress.map((d) => d.test.primaryScore).toList(),
      highStress.map((d) => d.test.primaryScore).toList(),
    );

    if (effectSize.abs() < 3) return [];

    return [
      Insight(
        type: InsightType.stress,
        testType: testType,
        title: 'Stress Effect',
        description:
            'High stress reduces your ${testType.displayName.toLowerCase()} by ${effectSize.abs().round()}%.',
        effectSize: effectSize,
        direction: InsightDirection.negative,
        confidence: confidence,
        sampleSize: validData.length,
      ),
    ];
  }

  List<Insight> _analyzeMood(
    List<_PairedDataPoint> data,
    CognitiveTestType testType,
  ) {
    final validData = data.where((d) => d.log.moodLevel != null).toList();
    if (validData.length < 5) return [];

    final goodMood = validData.where((d) => d.log.moodLevel! >= 4).toList();
    final badMood = validData.where((d) => d.log.moodLevel! <= 2).toList();

    if (goodMood.length < 2 || badMood.length < 2) return [];

    final goodAvg = _average(goodMood.map((d) => d.test.primaryScore));
    final badAvg = _average(badMood.map((d) => d.test.primaryScore));

    final lowerBetter = _isLowerBetter(testType);
    double effectSize;

    if (lowerBetter) {
      effectSize = ((badAvg - goodAvg) / badAvg) * 100;
    } else {
      effectSize = ((goodAvg - badAvg) / badAvg) * 100;
    }

    final confidence = _calculateConfidence(
      goodMood.map((d) => d.test.primaryScore).toList(),
      badMood.map((d) => d.test.primaryScore).toList(),
    );

    if (effectSize.abs() < 3) return [];

    return [
      Insight(
        type: InsightType.mood,
        testType: testType,
        title: 'Mood Connection',
        description:
            'Good mood correlates with ${effectSize.abs().round()}% better ${testType.displayName.toLowerCase()} scores.',
        effectSize: effectSize,
        direction: InsightDirection.positive,
        confidence: confidence,
        sampleSize: validData.length,
      ),
    ];
  }

  List<Insight> _analyzeEnergy(
    List<_PairedDataPoint> data,
    CognitiveTestType testType,
  ) {
    final validData = data.where((d) => d.log.energyLevel != null).toList();
    if (validData.length < 5) return [];

    final highEnergy = validData.where((d) => d.log.energyLevel! >= 4).toList();
    final lowEnergy = validData.where((d) => d.log.energyLevel! <= 2).toList();

    if (highEnergy.length < 2 || lowEnergy.length < 2) return [];

    final highAvg = _average(highEnergy.map((d) => d.test.primaryScore));
    final lowAvg = _average(lowEnergy.map((d) => d.test.primaryScore));

    final lowerBetter = _isLowerBetter(testType);
    double effectSize;

    if (lowerBetter) {
      effectSize = ((lowAvg - highAvg) / lowAvg) * 100;
    } else {
      effectSize = ((highAvg - lowAvg) / lowAvg) * 100;
    }

    final confidence = _calculateConfidence(
      highEnergy.map((d) => d.test.primaryScore).toList(),
      lowEnergy.map((d) => d.test.primaryScore).toList(),
    );

    if (effectSize.abs() < 3) return [];

    return [
      Insight(
        type: InsightType.energy,
        testType: testType,
        title: 'Energy Levels',
        description:
            'High energy days show ${effectSize.abs().round()}% better ${testType.displayName.toLowerCase()} performance.',
        effectSize: effectSize,
        direction: InsightDirection.positive,
        confidence: confidence,
        sampleSize: validData.length,
      ),
    ];
  }

  List<Insight> _analyzeMeditation(
    List<_PairedDataPoint> data,
    CognitiveTestType testType,
  ) {
    final validData = data.where((d) => d.log.meditationDone != null).toList();
    if (validData.length < 5) return [];

    final meditated = validData.where((d) => d.log.meditationDone == true).toList();
    final noMeditation = validData.where((d) => d.log.meditationDone == false).toList();

    if (meditated.length < 2 || noMeditation.length < 2) return [];

    final medAvg = _average(meditated.map((d) => d.test.primaryScore));
    final noAvg = _average(noMeditation.map((d) => d.test.primaryScore));

    final lowerBetter = _isLowerBetter(testType);
    double effectSize;
    InsightDirection direction;

    if (lowerBetter) {
      effectSize = ((noAvg - medAvg) / noAvg) * 100;
      direction = medAvg < noAvg ? InsightDirection.positive : InsightDirection.negative;
    } else {
      effectSize = ((medAvg - noAvg) / noAvg) * 100;
      direction = medAvg > noAvg ? InsightDirection.positive : InsightDirection.negative;
    }

    final confidence = _calculateConfidence(
      meditated.map((d) => d.test.primaryScore).toList(),
      noMeditation.map((d) => d.test.primaryScore).toList(),
    );

    if (effectSize.abs() < 3) return [];

    return [
      Insight(
        type: InsightType.meditation,
        testType: testType,
        title: 'Meditation Effect',
        description:
            'Meditation days show ${effectSize.abs().round()}% improvement in ${testType.displayName.toLowerCase()}.',
        effectSize: effectSize,
        direction: direction,
        confidence: confidence,
        sampleSize: validData.length,
      ),
    ];
  }

  List<Insight> _analyzeTimeOfDay(
    List<TestResult> tests,
    CognitiveTestType testType,
  ) {
    // Group by time of day
    final morning = tests.where((t) => t.timestamp.hour >= 6 && t.timestamp.hour < 12).toList();
    final afternoon = tests.where((t) => t.timestamp.hour >= 12 && t.timestamp.hour < 18).toList();
    final evening = tests.where((t) => t.timestamp.hour >= 18 || t.timestamp.hour < 6).toList();

    final insights = <Insight>[];
    final lowerBetter = _isLowerBetter(testType);

    if (morning.length >= 3 && afternoon.length >= 3) {
      final mornAvg = _average(morning.map((t) => t.primaryScore));
      final aftAvg = _average(afternoon.map((t) => t.primaryScore));

      double effectSize;
      String bestTime;

      if (lowerBetter) {
        if (mornAvg < aftAvg) {
          effectSize = ((aftAvg - mornAvg) / aftAvg) * 100;
          bestTime = 'morning';
        } else {
          effectSize = ((mornAvg - aftAvg) / mornAvg) * 100;
          bestTime = 'afternoon';
        }
      } else {
        if (mornAvg > aftAvg) {
          effectSize = ((mornAvg - aftAvg) / aftAvg) * 100;
          bestTime = 'morning';
        } else {
          effectSize = ((aftAvg - mornAvg) / mornAvg) * 100;
          bestTime = 'afternoon';
        }
      }

      if (effectSize.abs() >= 5) {
        insights.add(Insight(
          type: InsightType.timeOfDay,
          testType: testType,
          title: 'Peak Time',
          description:
              'Your ${testType.displayName.toLowerCase()} peaks in the $bestTime (${effectSize.round()}% better).',
          effectSize: effectSize,
          direction: InsightDirection.positive,
          confidence: 0.75,
          sampleSize: morning.length + afternoon.length,
          details: {
            'morning_avg': mornAvg,
            'afternoon_avg': aftAvg,
            'best_time': bestTime,
          },
        ));
      }
    }

    return insights;
  }

  double _average(Iterable<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _standardDeviation(List<double> values) {
    if (values.length < 2) return 0;
    final avg = _average(values);
    final squaredDiffs = values.map((v) => pow(v - avg, 2));
    return sqrt(squaredDiffs.reduce((a, b) => a + b) / (values.length - 1));
  }

  double _calculateConfidence(List<double> group1, List<double> group2) {
    // Simplified confidence calculation based on effect size and sample size
    if (group1.length < 2 || group2.length < 2) return 0;

    final avg1 = _average(group1);
    final avg2 = _average(group2);
    final std1 = _standardDeviation(group1);
    final std2 = _standardDeviation(group2);

    // Cohen's d effect size
    final pooledStd = sqrt((std1 * std1 + std2 * std2) / 2);
    if (pooledStd == 0) return 0.5;

    final cohensD = (avg1 - avg2).abs() / pooledStd;

    // Convert to a 0-1 confidence score
    // Large effect (d > 0.8) = high confidence
    // Medium effect (d > 0.5) = medium confidence
    // Small effect (d > 0.2) = low confidence
    double confidence = (cohensD / 1.5).clamp(0.0, 1.0);

    // Adjust for sample size
    final sampleFactor = min(1.0, (group1.length + group2.length) / 20);
    confidence *= (0.5 + 0.5 * sampleFactor);

    return confidence;
  }
}

class _PairedDataPoint {
  final TestResult test;
  final LifestyleLog log;

  _PairedDataPoint({required this.test, required this.log});
}
