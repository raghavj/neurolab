import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/database_service.dart';

class AppState extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = const Uuid();

  UserProfile? _currentUser;
  List<TestResult> _recentResults = [];
  LifestyleLog? _todayLog;
  Experiment? _activeExperiment;
  bool _isLoading = true;

  UserProfile? get currentUser => _currentUser;
  List<TestResult> get recentResults => _recentResults;
  LifestyleLog? get todayLog => _todayLog;
  Experiment? get activeExperiment => _activeExperiment;
  bool get isLoading => _isLoading;
  bool get isOnboarded => _currentUser?.onboardingCompleted ?? false;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('current_user_id');

    if (userId != null) {
      _currentUser = await _db.getUser(userId);
      if (_currentUser != null) {
        await _loadUserData();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) return;

    _recentResults = await _db.getTestResults(_currentUser!.id, limit: 10);
    _todayLog = await _db.getLifestyleLogForDate(_currentUser!.id, DateTime.now());
    _activeExperiment = await _db.getActiveExperiment(_currentUser!.id);

    notifyListeners();
  }

  Future<void> createUser(String name) async {
    final user = UserProfile(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
    );

    await _db.insertUser(user);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', user.id);

    _currentUser = user;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    if (_currentUser == null) return;

    final updated = _currentUser!.copyWith(onboardingCompleted: true);
    await _db.updateUser(updated);
    _currentUser = updated;
    notifyListeners();
  }

  Future<void> saveTestResult(TestResult result) async {
    await _db.insertTestResult(result);
    await _loadUserData();
  }

  Future<void> saveLifestyleLog(LifestyleLog log) async {
    await _db.insertLifestyleLog(log);
    _todayLog = log;
    notifyListeners();
  }

  Future<void> createExperiment(Experiment experiment) async {
    await _db.insertExperiment(experiment);
    _activeExperiment = experiment;
    notifyListeners();
  }

  Future<void> updateExperiment(Experiment experiment) async {
    await _db.updateExperiment(experiment);
    if (_activeExperiment?.id == experiment.id) {
      _activeExperiment = experiment;
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> getTestStatistics(
    CognitiveTestType testType, {
    int days = 30,
  }) async {
    if (_currentUser == null) return {};
    return _db.getTestStatistics(_currentUser!.id, testType, days: days);
  }

  Future<List<TestResult>> getTestHistory(
    CognitiveTestType testType, {
    int days = 30,
  }) async {
    if (_currentUser == null) return [];
    return _db.getTestResults(
      _currentUser!.id,
      testType: testType,
      startDate: DateTime.now().subtract(Duration(days: days)),
    );
  }

  String generateId() => _uuid.v4();
}
