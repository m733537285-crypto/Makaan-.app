import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'backend_exceptions.dart';
import 'remote_backend_client.dart';
import '../services/runtime_diagnostics_service.dart';

class FirebaseBackendClient implements RemoteBackendClient {
  FirebaseBackendClient({
    firebase_auth.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Map<String, String> _verificationIdsByPhone = <String, String>{};

  @override
  bool get isEnabled => Firebase.apps.isNotEmpty;

  @override
  void setAccessToken(String? token) {
    // FirebaseAuth owns the native session. The token argument is kept to satisfy
    // the shared remote-backend contract used by earlier phases.
  }

  @override
  Future<void> requestPhoneOtp(String phoneNumber) async {
    _ensureConfigured();
    final Completer<void> completer = Completer<void>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (firebase_auth.PhoneAuthCredential credential) async {
        try {
          await _auth.signInWithCredential(credential);
          if (!completer.isCompleted) {
            completer.complete();
          }
        } catch (error, stackTrace) {
          RuntimeDiagnosticsService.instance.recordError(error, stackTrace, source: 'firebase_auto_verify');
          if (!completer.isCompleted) {
            completer.completeError(_mapFirebaseAuthError(error));
          }
        }
      },
      verificationFailed: (firebase_auth.FirebaseAuthException error) {
        if (!completer.isCompleted) {
          completer.completeError(_mapFirebaseAuthError(error));
        }
      },
      codeSent: (String verificationId, int? forceResendingToken) {
        _verificationIdsByPhone[phoneNumber] = verificationId;
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationIdsByPhone[phoneNumber] = verificationId;
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );
    return completer.future.timeout(
      const Duration(seconds: 75),
      onTimeout: () => throw const BackendTimeoutException(),
    );
  }

  @override
  Future<RemoteOtpVerificationResult> verifyPhoneOtp({
    required String phoneNumber,
    required String token,
  }) async {
    _ensureConfigured();
    firebase_auth.User? user = _auth.currentUser;
    if (user == null || user.phoneNumber != phoneNumber) {
      final String? verificationId = _verificationIdsByPhone[phoneNumber];
      if (verificationId == null || verificationId.isEmpty) {
        throw const BackendException('انتهت جلسة Firebase OTP. أعد طلب رمز جديد.');
      }
      final firebase_auth.PhoneAuthCredential phoneCredential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: token,
      );
      final firebase_auth.UserCredential credential = await _auth.signInWithCredential(phoneCredential);
      user = credential.user ?? _auth.currentUser;
    }
    if (user == null) {
      throw const BackendException('تعذر إنشاء جلسة Firebase صالحة.');
    }
    final String? idToken = await user.getIdToken(true);
    await _firestore.collection('auth_profiles').doc(user.uid).set(
      <String, dynamic>{
        'uid': user.uid,
        'phoneNumber': user.phoneNumber ?? phoneNumber,
        'lastSignInAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    return RemoteOtpVerificationResult(
      userId: user.uid,
      phoneNumber: user.phoneNumber ?? phoneNumber,
      accessToken: idToken ?? user.uid,
      refreshToken: user.refreshToken,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> listCollection(RemoteCollectionSpec spec) async {
    _ensureConfigured();
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection(spec.table)
        .orderBy('updatedAt', descending: true)
        .limit(500)
        .get();
    final List<Map<String, dynamic>> payloads = <Map<String, dynamic>>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
      final Map<String, dynamic> data = doc.data();
      final Object? payload = data['payload'];
      if (payload is Map<String, dynamic>) {
        payloads.add(_normalizeFirestoreMap(payload));
      } else if (payload is Map) {
        payloads.add(_normalizeFirestoreMap(Map<String, dynamic>.from(payload)));
      }
    }
    return payloads;
  }

  @override
  Future<void> replaceCollection({
    required RemoteCollectionSpec spec,
    required List<Map<String, dynamic>> items,
  }) async {
    _ensureConfigured();
    if (items.isEmpty) {
      return;
    }
    WriteBatch batch = _firestore.batch();
    int operationCount = 0;
    for (final Map<String, dynamic> item in items) {
      final String id = (item[spec.idField] ?? '').toString().trim();
      if (id.isEmpty) {
        continue;
      }
      final DocumentReference<Map<String, dynamic>> ref = _firestore.collection(spec.table).doc(_safeDocId(id));
      batch.set(
        ref,
        <String, dynamic>{
          'id': id,
          'ownerUserId': spec.ownerField == null ? null : item[spec.ownerField!],
          'payload': _convertForFirestore(item),
          'searchText': _buildSearchText(item),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      operationCount++;
      if (operationCount == 450) {
        await batch.commit();
        batch = _firestore.batch();
        operationCount = 0;
      }
    }
    if (operationCount > 0) {
      await batch.commit();
    }
  }

  @override
  Future<void> deleteCollectionRow({
    required RemoteCollectionSpec spec,
    required String id,
  }) async {
    _ensureConfigured();
    if (id.trim().isEmpty) {
      return;
    }
    await _firestore.collection(spec.table).doc(_safeDocId(id)).delete();
  }

  @override
  Future<String> uploadBytes({
    required Uint8List bytes,
    required String path,
    required String contentType,
  }) async {
    _ensureConfigured();
    final Reference ref = _storage.ref().child(_cleanPath(path));
    final UploadTask task = ref.putData(bytes, SettableMetadata(contentType: contentType));
    await task;
    return ref.getDownloadURL();
  }

  @override
  Future<void> registerPushToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    _ensureConfigured();
    final String id = _safeDocId('${userId}_$platform');
    await _firestore.collection('push_tokens').doc(id).set(
      <String, dynamic>{
        'id': id,
        'ownerUserId': userId,
        'payload': <String, dynamic>{
          'userId': userId,
          'token': token,
          'platform': platform,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
        'searchText': '$userId $platform',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> createPushNotificationIntent({
    required String userId,
    required String title,
    required String body,
    required String eventType,
    String? targetId,
  }) async {
    _ensureConfigured();
    final String id = 'push_${DateTime.now().microsecondsSinceEpoch}';
    await _firestore.collection('push_notification_queue').doc(id).set(
      <String, dynamic>{
        'id': id,
        'ownerUserId': userId,
        'payload': <String, dynamic>{
          'notificationId': id,
          'userId': userId,
          'title': title,
          'body': body,
          'eventType': eventType,
          'targetId': targetId,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'deliveryStatus': 'pending',
        },
        'searchText': '$title $body $eventType',
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  void _ensureConfigured() {
    if (!isEnabled) {
      throw const BackendException('Firebase غير مهيأ. تأكد من وجود google-services.json واستدعاء Firebase.initializeApp.');
    }
  }

  BackendException _mapFirebaseAuthError(Object error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-phone-number':
          return const BackendException('رقم الهاتف غير صحيح حسب Firebase.');
        case 'too-many-requests':
          return const BackendException('تم إرسال طلبات كثيرة. حاول لاحقاً.');
        case 'quota-exceeded':
          return const BackendException('تم تجاوز حد رسائل OTP في Firebase.');
        case 'invalid-verification-code':
          return const BackendException('رمز التحقق غير صحيح.');
        case 'session-expired':
          return const BackendException('انتهت جلسة رمز التحقق. أعد الطلب.');
      }
      return BackendException(error.message ?? 'حدث خطأ في Firebase Auth.', details: error.code);
    }
    return BackendException(error.toString());
  }

  String _safeDocId(String id) => id.replaceAll('/', '_');

  String _cleanPath(String path) => path.replaceAll(RegExp(r'^/+'), '').replaceAll('//', '/');

  Map<String, dynamic> _normalizeFirestoreMap(Map<String, dynamic> input) {
    return input.map<String, dynamic>((String key, Object? value) => MapEntry<String, dynamic>(key, _normalizeValue(value)));
  }

  Object? _normalizeValue(Object? value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is Map<String, dynamic>) {
      return _normalizeFirestoreMap(value);
    }
    if (value is Map) {
      return _normalizeFirestoreMap(Map<String, dynamic>.from(value));
    }
    if (value is Iterable) {
      return value.map<Object?>(_normalizeValue).toList(growable: false);
    }
    return value;
  }

  Map<String, dynamic> _convertForFirestore(Map<String, dynamic> input) {
    return input.map<String, dynamic>((String key, Object? value) => MapEntry<String, dynamic>(key, _convertValueForFirestore(value)));
  }

  Object? _convertValueForFirestore(Object? value) {
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    if (value is Map<String, dynamic>) {
      return _convertForFirestore(value);
    }
    if (value is Map) {
      return _convertForFirestore(Map<String, dynamic>.from(value));
    }
    if (value is Iterable) {
      return value.map<Object?>(_convertValueForFirestore).toList(growable: false);
    }
    return value;
  }

  String _buildSearchText(Map<String, dynamic> payload) {
    final StringBuffer buffer = StringBuffer();
    void visit(Object? value) {
      if (value == null) {
        return;
      }
      if (value is String || value is num || value is bool) {
        buffer.write(' $value');
      } else if (value is Iterable) {
        for (final Object? item in value) {
          visit(item);
        }
      } else if (value is Map) {
        for (final Object? item in value.values) {
          visit(item);
        }
      }
    }

    visit(payload);
    return buffer.toString().trim().toLowerCase();
  }
}
