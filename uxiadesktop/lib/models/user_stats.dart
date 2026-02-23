/// Modelo de usuario
class User {
  final String id;
  final String email;
  final String nickname;
  final int? telephone;
  final String role;

  User({
    required this.id,
    required this.email,
    required this.nickname,
    this.telephone,
    required this.role,
  });

  /// Convierte JSON a User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      telephone: json['telephone'] as int?,
      role: json['role'] as String? ?? 'user',
    );
  }

  /// Convierte User a JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'nickname': nickname,
    'telephone': telephone,
    'role': role,
  };

  /// Copia con cambios
  User copyWith({
    String? id,
    String? email,
    String? nickname,
    int? telephone,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      telephone: telephone ?? this.telephone,
      role: role ?? this.role,
    );
  }

  @override
  String toString() => 'User(id: $id, email: $email, nickname: $nickname)';
}
