class LifestyleLog {
  final String id;
  final String userId;
  final DateTime date;
  final DateTime loggedAt;

  // Sleep metrics (nullable for partial logging)
  final double? sleepHours;
  final int? sleepQuality; // 1-5 scale

  // Caffeine
  final int? caffeineIntake; // mg or servings
  final DateTime? lastCaffeineTime;

  // Exercise
  final int? exerciseMinutes;
  final String? exerciseType;
  final int? exerciseIntensity; // 1-5 scale

  // Mental state
  final int? stressLevel; // 1-5 scale
  final int? moodLevel; // 1-5 scale
  final int? energyLevel; // 1-5 scale
  final int? focusLevel; // 1-5 scale

  // Additional factors
  final bool? meditationDone;
  final int? meditationMinutes;
  final int? screenTimeHours;
  final String? notes;

  LifestyleLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.loggedAt,
    this.sleepHours,
    this.sleepQuality,
    this.caffeineIntake,
    this.lastCaffeineTime,
    this.exerciseMinutes,
    this.exerciseType,
    this.exerciseIntensity,
    this.stressLevel,
    this.moodLevel,
    this.energyLevel,
    this.focusLevel,
    this.meditationDone,
    this.meditationMinutes,
    this.screenTimeHours,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'logged_at': loggedAt.toIso8601String(),
      'sleep_hours': sleepHours,
      'sleep_quality': sleepQuality,
      'caffeine_intake': caffeineIntake,
      'last_caffeine_time': lastCaffeineTime?.toIso8601String(),
      'exercise_minutes': exerciseMinutes,
      'exercise_type': exerciseType,
      'exercise_intensity': exerciseIntensity,
      'stress_level': stressLevel,
      'mood_level': moodLevel,
      'energy_level': energyLevel,
      'focus_level': focusLevel,
      'meditation_done': meditationDone == true ? 1 : (meditationDone == false ? 0 : null),
      'meditation_minutes': meditationMinutes,
      'screen_time_hours': screenTimeHours,
      'notes': notes,
    };
  }

  factory LifestyleLog.fromMap(Map<String, dynamic> map) {
    return LifestyleLog(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      date: DateTime.parse(map['date'] as String),
      loggedAt: DateTime.parse(map['logged_at'] as String),
      sleepHours: map['sleep_hours'] as double?,
      sleepQuality: map['sleep_quality'] as int?,
      caffeineIntake: map['caffeine_intake'] as int?,
      lastCaffeineTime: map['last_caffeine_time'] != null
          ? DateTime.parse(map['last_caffeine_time'] as String)
          : null,
      exerciseMinutes: map['exercise_minutes'] as int?,
      exerciseType: map['exercise_type'] as String?,
      exerciseIntensity: map['exercise_intensity'] as int?,
      stressLevel: map['stress_level'] as int?,
      moodLevel: map['mood_level'] as int?,
      energyLevel: map['energy_level'] as int?,
      focusLevel: map['focus_level'] as int?,
      meditationDone: map['meditation_done'] != null
          ? (map['meditation_done'] as int) == 1
          : null,
      meditationMinutes: map['meditation_minutes'] as int?,
      screenTimeHours: map['screen_time_hours'] as int?,
      notes: map['notes'] as String?,
    );
  }

  LifestyleLog copyWith({
    double? sleepHours,
    int? sleepQuality,
    int? caffeineIntake,
    DateTime? lastCaffeineTime,
    int? exerciseMinutes,
    String? exerciseType,
    int? exerciseIntensity,
    int? stressLevel,
    int? moodLevel,
    int? energyLevel,
    int? focusLevel,
    bool? meditationDone,
    int? meditationMinutes,
    int? screenTimeHours,
    String? notes,
  }) {
    return LifestyleLog(
      id: id,
      userId: userId,
      date: date,
      loggedAt: DateTime.now(),
      sleepHours: sleepHours ?? this.sleepHours,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      caffeineIntake: caffeineIntake ?? this.caffeineIntake,
      lastCaffeineTime: lastCaffeineTime ?? this.lastCaffeineTime,
      exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
      exerciseType: exerciseType ?? this.exerciseType,
      exerciseIntensity: exerciseIntensity ?? this.exerciseIntensity,
      stressLevel: stressLevel ?? this.stressLevel,
      moodLevel: moodLevel ?? this.moodLevel,
      energyLevel: energyLevel ?? this.energyLevel,
      focusLevel: focusLevel ?? this.focusLevel,
      meditationDone: meditationDone ?? this.meditationDone,
      meditationMinutes: meditationMinutes ?? this.meditationMinutes,
      screenTimeHours: screenTimeHours ?? this.screenTimeHours,
      notes: notes ?? this.notes,
    );
  }
}
