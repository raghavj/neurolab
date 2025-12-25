import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'neurolab.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        date_of_birth TEXT,
        occupation TEXT,
        onboarding_completed INTEGER DEFAULT 0,
        preferences TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE test_results (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        test_type INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        primary_score REAL NOT NULL,
        primary_score_unit TEXT NOT NULL,
        detailed_metrics TEXT,
        trial_count INTEGER NOT NULL,
        correct_trials INTEGER NOT NULL,
        experiment_id TEXT,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (experiment_id) REFERENCES experiments (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE lifestyle_logs (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        logged_at TEXT NOT NULL,
        sleep_hours REAL,
        sleep_quality INTEGER,
        caffeine_intake INTEGER,
        last_caffeine_time TEXT,
        exercise_minutes INTEGER,
        exercise_type TEXT,
        exercise_intensity INTEGER,
        stress_level INTEGER,
        mood_level INTEGER,
        energy_level INTEGER,
        focus_level INTEGER,
        meditation_done INTEGER,
        meditation_minutes INTEGER,
        screen_time_hours INTEGER,
        notes TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE experiments (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        hypothesis TEXT NOT NULL,
        intervention TEXT NOT NULL,
        target_test INTEGER NOT NULL,
        status INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        started_at TEXT,
        completed_at TEXT,
        baseline_days INTEGER NOT NULL,
        intervention_days INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE experiment_notes (
        id TEXT PRIMARY KEY,
        experiment_id TEXT NOT NULL,
        note TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (experiment_id) REFERENCES experiments (id)
      )
    ''');

    // Create indexes for common queries
    await db.execute(
        'CREATE INDEX idx_test_results_user ON test_results (user_id)');
    await db.execute(
        'CREATE INDEX idx_test_results_timestamp ON test_results (timestamp)');
    await db.execute(
        'CREATE INDEX idx_lifestyle_logs_user_date ON lifestyle_logs (user_id, date)');
    await db.execute(
        'CREATE INDEX idx_experiments_user ON experiments (user_id)');
  }

  // User operations
  Future<void> insertUser(UserProfile user) async {
    final db = await database;
    await db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserProfile?> getUser(String id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return UserProfile.fromMap(maps.first);
  }

  Future<void> updateUser(UserProfile user) async {
    final db = await database;
    await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  // Test result operations
  Future<void> insertTestResult(TestResult result) async {
    final db = await database;
    await db.insert('test_results', result.toMap());
  }

  Future<List<TestResult>> getTestResults(
    String userId, {
    CognitiveTestType? testType,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final db = await database;

    String where = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (testType != null) {
      where += ' AND test_type = ?';
      whereArgs.add(testType.index);
    }

    if (startDate != null) {
      where += ' AND timestamp >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where += ' AND timestamp <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final maps = await db.query(
      'test_results',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((m) => TestResult.fromMap(m)).toList();
  }

  Future<TestResult?> getLatestTestResult(
      String userId, CognitiveTestType testType) async {
    final results =
        await getTestResults(userId, testType: testType, limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<TestResult>> getAllTestResults(String userId) async {
    return getTestResults(userId);
  }

  // Lifestyle log operations
  Future<void> insertLifestyleLog(LifestyleLog log) async {
    final db = await database;
    await db.insert('lifestyle_logs', log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<LifestyleLog?> getLifestyleLogForDate(
      String userId, DateTime date) async {
    final db = await database;
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String();

    final maps = await db.query(
      'lifestyle_logs',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, dateStr],
    );

    if (maps.isEmpty) return null;
    return LifestyleLog.fromMap(maps.first);
  }

  Future<List<LifestyleLog>> getLifestyleLogs(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int? days,
  }) async {
    final db = await database;

    String where = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    // If days is provided, calculate startDate from it
    final effectiveStartDate = days != null
        ? DateTime.now().subtract(Duration(days: days))
        : startDate;

    if (effectiveStartDate != null) {
      where += ' AND date >= ?';
      whereArgs.add(effectiveStartDate.toIso8601String());
    }

    if (endDate != null) {
      where += ' AND date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final maps = await db.query(
      'lifestyle_logs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );

    return maps.map((m) => LifestyleLog.fromMap(m)).toList();
  }

  // Experiment operations
  Future<void> insertExperiment(Experiment experiment) async {
    final db = await database;
    await db.insert('experiments', experiment.toMap());
  }

  Future<void> updateExperiment(Experiment experiment) async {
    final db = await database;
    await db.update('experiments', experiment.toMap(),
        where: 'id = ?', whereArgs: [experiment.id]);
  }

  Future<List<Experiment>> getExperiments(String userId,
      {ExperimentStatus? status}) async {
    final db = await database;

    String where = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (status != null) {
      where += ' AND status = ?';
      whereArgs.add(status.index);
    }

    final maps = await db.query(
      'experiments',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return maps.map((m) => Experiment.fromMap(m)).toList();
  }

  Future<Experiment?> getActiveExperiment(String userId) async {
    final db = await database;
    final maps = await db.query(
      'experiments',
      where: 'user_id = ? AND (status = ? OR status = ?)',
      whereArgs: [
        userId,
        ExperimentStatus.baseline.index,
        ExperimentStatus.intervention.index
      ],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Experiment.fromMap(maps.first);
  }

  // Statistics helpers
  Future<Map<String, dynamic>> getTestStatistics(
    String userId,
    CognitiveTestType testType, {
    int days = 30,
  }) async {
    final results = await getTestResults(
      userId,
      testType: testType,
      startDate: DateTime.now().subtract(Duration(days: days)),
    );

    if (results.isEmpty) {
      return {
        'count': 0,
        'average': null,
        'best': null,
        'trend': null,
      };
    }

    final scores = results.map((r) => r.primaryScore).toList();
    final average = scores.reduce((a, b) => a + b) / scores.length;

    // For reaction time, lower is better
    final best = testType == CognitiveTestType.reactionTime
        ? scores.reduce((a, b) => a < b ? a : b)
        : scores.reduce((a, b) => a > b ? a : b);

    // Calculate trend (comparing recent half to older half)
    double? trend;
    if (results.length >= 4) {
      final half = results.length ~/ 2;
      final recentAvg =
          scores.sublist(0, half).reduce((a, b) => a + b) / half;
      final olderAvg =
          scores.sublist(half).reduce((a, b) => a + b) / (results.length - half);
      trend = ((recentAvg - olderAvg) / olderAvg) * 100;
    }

    return {
      'count': results.length,
      'average': average,
      'best': best,
      'trend': trend,
    };
  }
}
