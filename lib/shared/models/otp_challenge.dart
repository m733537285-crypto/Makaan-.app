class OtpChallenge {
  const OtpChallenge({
    required this.phoneNumber,
    required this.code,
    required this.createdAt,
    required this.expiresAt,
    required this.resendAvailableAt,
    required this.attemptsUsed,
    required this.maxAttempts,
  });

  final String phoneNumber;
  final String code;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime resendAvailableAt;
  final int attemptsUsed;
  final int maxAttempts;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get canResend => !DateTime.now().isBefore(resendAvailableAt);
  int get attemptsRemaining => maxAttempts - attemptsUsed;

  OtpChallenge copyWith({
    String? phoneNumber,
    String? code,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? resendAvailableAt,
    int? attemptsUsed,
    int? maxAttempts,
  }) {
    return OtpChallenge(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      code: code ?? this.code,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      resendAvailableAt: resendAvailableAt ?? this.resendAvailableAt,
      attemptsUsed: attemptsUsed ?? this.attemptsUsed,
      maxAttempts: maxAttempts ?? this.maxAttempts,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'phoneNumber': phoneNumber,
      'code': code,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'resendAvailableAt': resendAvailableAt.toIso8601String(),
      'attemptsUsed': attemptsUsed,
      'maxAttempts': maxAttempts,
    };
  }

  factory OtpChallenge.fromJson(Map<String, dynamic> json) {
    return OtpChallenge(
      phoneNumber: json['phoneNumber'] as String,
      code: json['code'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      resendAvailableAt: DateTime.parse(json['resendAvailableAt'] as String),
      attemptsUsed: json['attemptsUsed'] as int? ?? 0,
      maxAttempts: json['maxAttempts'] as int? ?? 5,
    );
  }
}
