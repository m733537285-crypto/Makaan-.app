import 'dart:typed_data';

class RemoteCollectionSpec {
  const RemoteCollectionSpec({
    required this.localKey,
    required this.table,
    required this.idField,
    this.ownerField,
  });

  final String localKey;
  final String table;
  final String idField;
  final String? ownerField;
}

class RemoteOtpVerificationResult {
  const RemoteOtpVerificationResult({
    required this.userId,
    required this.phoneNumber,
    required this.accessToken,
    this.refreshToken,
  });

  final String userId;
  final String phoneNumber;
  final String accessToken;
  final String? refreshToken;
}

abstract class RemoteBackendClient {
  bool get isEnabled;

  void setAccessToken(String? token);

  Future<void> requestPhoneOtp(String phoneNumber);

  Future<RemoteOtpVerificationResult> verifyPhoneOtp({
    required String phoneNumber,
    required String token,
  });

  Future<List<Map<String, dynamic>>> listCollection(RemoteCollectionSpec spec);

  Future<void> replaceCollection({
    required RemoteCollectionSpec spec,
    required List<Map<String, dynamic>> items,
  });

  Future<void> deleteCollectionRow({
    required RemoteCollectionSpec spec,
    required String id,
  });

  Future<String> uploadBytes({
    required Uint8List bytes,
    required String path,
    required String contentType,
  });

  Future<void> registerPushToken({
    required String userId,
    required String token,
    required String platform,
  });

  Future<void> createPushNotificationIntent({
    required String userId,
    required String title,
    required String body,
    required String eventType,
    String? targetId,
  });
}
