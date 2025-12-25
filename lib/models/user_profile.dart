class UserProfile {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? dateOfBirth;
  final String? occupation;
  final bool onboardingCompleted;
  final Map<String, dynamic> preferences;

  UserProfile({
    required this.id,
    required this.name,
    required this.createdAt,
    this.dateOfBirth,
    this.occupation,
    this.onboardingCompleted = false,
    Map<String, dynamic>? preferences,
  }) : preferences = preferences ?? {};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'occupation': occupation,
      'onboarding_completed': onboardingCompleted ? 1 : 0,
      'preferences': preferences.toString(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.parse(map['date_of_birth'] as String)
          : null,
      occupation: map['occupation'] as String?,
      onboardingCompleted: (map['onboarding_completed'] as int) == 1,
    );
  }

  UserProfile copyWith({
    String? name,
    DateTime? dateOfBirth,
    String? occupation,
    bool? onboardingCompleted,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      occupation: occupation ?? this.occupation,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      preferences: preferences ?? this.preferences,
    );
  }
}
