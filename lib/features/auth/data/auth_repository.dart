import 'dart:math';

import '../../../shared/models/app_user.dart';
import '../../../shared/models/auth_session.dart';
import '../../../shared/models/otp_challenge.dart';
import '../../../shared/services/app_storage_service.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OtpRequestResult {
  const OtpRequestResult({required this.challenge, required this.isResend});

  final OtpChallenge challenge;
  final bool isResend;
}

class OtpVerificationResult {
  const OtpVerificationResult({required this.user, required this.isNewUser});

  final AppUser user;
  final bool isNewUser;
}

class AuthRepository {
  AuthRepository(this._storage);

  final AppStorageService _storage;
  final Random _random = Random.secure();

  bool get onboardingCompleted => _storage.onboardingCompleted;
  bool get isRemoteBackendEnabled => _storage.isRemoteBackendEnabled;
  String? get lastBackendError => _storage.lastBackendError;

  Future<void> refreshRemoteCache() => _storage.syncFromBackend();

  Future<void> setOnboardingCompleted(bool value) {
    return _storage.setOnboardingCompleted(value);
  }

  OtpChallenge? loadActiveChallenge() {
    final OtpChallenge? challenge = _storage.loadActiveOtpChallenge();
    if (challenge == null) {
      return null;
    }
    if (challenge.isExpired) {
      _storage.clearActiveOtpChallenge();
      return null;
    }
    return challenge;
  }

  Future<OtpRequestResult> requestOtp({
    required String phoneNumber,
    bool forceResend = false,
  }) async {
    final OtpChallenge? existing = loadActiveChallenge();
    if (existing != null && existing.phoneNumber == phoneNumber) {
      if (!forceResend) {
        return OtpRequestResult(challenge: existing, isResend: false);
      }
      if (!existing.canResend) {
        throw AuthException(
          'يمكن إعادة إرسال الرمز بعد ${existing.resendAvailableAt.difference(DateTime.now()).inSeconds.clamp(1, 60)} ثانية.',
        );
      }
    }

    final DateTime now = DateTime.now();
    if (_storage.isRemoteBackendEnabled) {
      await _storage.requestRemoteOtp(phoneNumber);
    }
    final OtpChallenge challenge = OtpChallenge(
      phoneNumber: phoneNumber,
      code: _storage.isRemoteBackendEnabled ? '' : _generateOtpCode(),
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 5)),
      resendAvailableAt: now.add(const Duration(seconds: 60)),
      attemptsUsed: 0,
      maxAttempts: 5,
    );
    await _storage.saveActiveOtpChallenge(challenge);
    return OtpRequestResult(challenge: challenge, isResend: forceResend);
  }

  Future<OtpVerificationResult> verifyOtp({
    required String phoneNumber,
    required String code,
  }) async {
    final OtpChallenge? challenge = loadActiveChallenge();
    if (challenge == null || challenge.phoneNumber != phoneNumber) {
      throw const AuthException('انتهت جلسة التحقق. أعد طلب رمز جديد.');
    }
    if (challenge.isExpired) {
      await _storage.clearActiveOtpChallenge();
      throw const AuthException('انتهت صلاحية رمز التحقق. أعد المحاولة.');
    }
    if (challenge.attemptsUsed >= challenge.maxAttempts) {
      await _storage.clearActiveOtpChallenge();
      throw const AuthException('تم تجاوز الحد الأقصى للمحاولات. اطلب رمزاً جديداً.');
    }

    if (_storage.isRemoteBackendEnabled) {
      try {
        final remote = await _storage.verifyRemoteOtp(phoneNumber: phoneNumber, code: code);
        await _storage.clearActiveOtpChallenge();
        final List<AppUser> users = _storage.loadUsers();
        AppUser? user = _findUserByPhone(users, remote.phoneNumber);
        user ??= users.where((AppUser item) => item.userId == remote.userId).firstOrNull;
        bool isNewUser = false;
        if (user == null) {
          isNewUser = true;
          user = AppUser(
            userId: remote.userId,
            phoneNumber: remote.phoneNumber,
            createdAt: DateTime.now(),
            userType: null,
            isVerified: true,
            isBlocked: false,
          );
          users.add(user);
        } else {
          final String existingUserId = user.userId;
          final int index = users.indexWhere((AppUser item) => item.userId == existingUserId);
          users[index] = user.copyWith(phoneNumber: remote.phoneNumber, isVerified: true);
          user = users[index];
        }
        if (user.isBlocked) {
          await _storage.clearSession();
          throw const AuthException('هذا الحساب موقوف حالياً.');
        }
        await _storage.saveSession(
          AuthSession(
            userId: user.userId,
            token: remote.accessToken,
            createdAt: DateTime.now(),
          ),
        );
        await _storage.saveUsers(users);
        return OtpVerificationResult(user: user, isNewUser: isNewUser);
      } catch (error) {
        final int nextAttempts = challenge.attemptsUsed + 1;
        if (nextAttempts >= challenge.maxAttempts) {
          await _storage.clearActiveOtpChallenge();
        } else {
          await _storage.saveActiveOtpChallenge(challenge.copyWith(attemptsUsed: nextAttempts));
        }
        throw AuthException(error.toString());
      }
    }

    if (challenge.code != code) {
      final int nextAttempts = challenge.attemptsUsed + 1;
      if (nextAttempts >= challenge.maxAttempts) {
        await _storage.clearActiveOtpChallenge();
        throw const AuthException('تم استهلاك كل المحاولات. اطلب رمزاً جديداً.');
      }
      await _storage.saveActiveOtpChallenge(
        challenge.copyWith(attemptsUsed: nextAttempts),
      );
      throw AuthException(
        'الرمز غير صحيح. تبقّى ${challenge.maxAttempts - nextAttempts} محاولات.',
      );
    }

    await _storage.clearActiveOtpChallenge();
    final List<AppUser> users = _storage.loadUsers();
    AppUser? user = _findUserByPhone(users, phoneNumber);
    bool isNewUser = false;

    if (user == null) {
      isNewUser = true;
      user = AppUser(
        userId: _generateUserId(),
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        userType: null,
        isVerified: true,
        isBlocked: false,
      );
      users.add(user);
      await _storage.saveUsers(users);
    }

    if (user.isBlocked) {
      await _storage.clearSession();
      throw const AuthException('هذا الحساب موقوف حالياً.');
    }

    final AuthSession session = AuthSession(
      userId: user.userId,
      token: _generateToken(),
      createdAt: DateTime.now(),
    );
    await _storage.saveSession(session);
    return OtpVerificationResult(user: user, isNewUser: isNewUser);
  }

  Future<AppUser?> restoreSession() async {
    final AuthSession? session = await _storage.loadSession();
    if (session == null) {
      return null;
    }
    final List<AppUser> users = _storage.loadUsers();
    final AppUser? user = users.where((AppUser item) => item.userId == session.userId).firstOrNull;
    if (user == null || user.isBlocked) {
      await _storage.clearSession();
      return null;
    }
    return user;
  }

  Future<AppUser> saveUser(AppUser user) async {
    final List<AppUser> users = _storage.loadUsers();
    final int index = users.indexWhere((AppUser item) => item.userId == user.userId);
    if (index == -1) {
      final AppUser? phoneOwner = _findUserByPhone(users, user.phoneNumber);
      if (phoneOwner != null) {
        throw const AuthException('يوجد حساب مسجل بهذا الرقم بالفعل.');
      }
      users.add(user);
    } else {
      final AppUser? duplicate = users
          .where((AppUser item) => item.userId != user.userId)
          .where((AppUser item) => item.phoneNumber == user.phoneNumber)
          .firstOrNull;
      if (duplicate != null) {
        throw const AuthException('يوجد حساب آخر مسجل بنفس الرقم.');
      }
      users[index] = user;
    }
    await _storage.saveUsers(users);
    return user;
  }

  Future<void> logout() {
    return _storage.clearSession();
  }

  AppUser? _findUserByPhone(List<AppUser> users, String phoneNumber) {
    for (final AppUser user in users) {
      if (user.phoneNumber == phoneNumber) {
        return user;
      }
    }
    return null;
  }

  String _generateOtpCode() {
    return List<String>.generate(6, (_) => _random.nextInt(10).toString()).join();
  }

  String _generateUserId() {
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final int suffix = 1000 + _random.nextInt(9000);
    return 'makaan_$timestamp$suffix';
  }

  String _generateToken() {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List<String>.generate(
      48,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
