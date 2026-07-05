class AuthSession {
  const AuthSession({
    required this.userId,
    required this.token,
    required this.createdAt,
  });

  final String userId;
  final String token;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'token': token,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: json['userId'] as String,
      token: json['token'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
