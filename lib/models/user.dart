class User {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final DateTime createdAt;
  final bool hasCompletedOnboarding;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
    this.hasCompletedOnboarding = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      role: UserRole.values.byName(json['role'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'hasCompletedOnboarding': hasCompletedOnboarding,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
    DateTime? createdAt,
    bool? hasCompletedOnboarding,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}

enum UserRole {
  patient,
  clinician;

  String get displayName => this == UserRole.patient ? 'Patient' : 'Clinician';
}
