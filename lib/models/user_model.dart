class User {
  final int? id;
  final String passwordHash; // In real secure app with SQLCipher, this might be redundant if DB itself key is the password, but good for verification
  final bool biometricEnabled;
  final DateTime createdAt;

  User({
    this.id,
    required this.passwordHash,
    required this.biometricEnabled,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'password_hash': passwordHash,
        'biometric_enabled': biometricEnabled ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  static User fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int?,
        passwordHash: json['password_hash'] as String,
        biometricEnabled: (json['biometric_enabled'] as int) == 1,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
