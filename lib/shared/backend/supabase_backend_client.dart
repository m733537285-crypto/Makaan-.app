import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'backend_config.dart';
import 'remote_backend_client.dart';
import '../services/runtime_diagnostics_service.dart';
import 'backend_exceptions.dart';

class SupabaseBackendClient implements RemoteBackendClient {
  SupabaseBackendClient(this.config, {http.Client? client}) : _client = client ?? http.Client();

  final BackendConfig config;
  final http.Client _client;
  String? _accessToken;

  bool get isEnabled => config.isConfigured;

  void setAccessToken(String? token) {
    final String cleaned = token?.trim() ?? '';
    _accessToken = cleaned.isEmpty ? null : cleaned;
  }

  String get _authorizationToken => _accessToken ?? config.supabaseAnonKey;

  Map<String, String> get _baseHeaders => <String, String>{
        'apikey': config.supabaseAnonKey,
        'Authorization': 'Bearer $_authorizationToken',
        'Content-Type': 'application/json',
      };

  Future<void> requestPhoneOtp(String phoneNumber) async {
    _ensureConfigured();
    final Map<String, dynamic> body = <String, dynamic>{
      'phone': phoneNumber,
      'create_user': true,
    };
    await _request(
      () => _client.post(
        config.authUri('otp'),
        headers: _baseHeaders,
        body: jsonEncode(body),
      ),
      acceptedStatusCodes: const <int>{200, 204},
    );
  }

  Future<RemoteOtpVerificationResult> verifyPhoneOtp({
    required String phoneNumber,
    required String token,
  }) async {
    _ensureConfigured();
    final Map<String, dynamic> body = <String, dynamic>{
      'phone': phoneNumber,
      'token': token,
      'type': 'sms',
    };
    final http.Response response = await _request(
      () => _client.post(
        config.authUri('token?grant_type=otp'),
        headers: _baseHeaders,
        body: jsonEncode(body),
      ),
      acceptedStatusCodes: const <int>{200},
    );
    final Map<String, dynamic> decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final Map<String, dynamic> user = (decoded['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final String? accessToken = decoded['access_token'] as String?;
    final String userId = (user['id'] as String?) ?? '';
    if (accessToken == null || accessToken.isEmpty || userId.isEmpty) {
      throw const BackendException('تعذر إنشاء جلسة تحقق صالحة من الخادم.');
    }
    return RemoteOtpVerificationResult(
      userId: userId,
      phoneNumber: (user['phone'] as String?) ?? phoneNumber,
      accessToken: accessToken,
      refreshToken: decoded['refresh_token'] as String?,
    );
  }

  Future<List<Map<String, dynamic>>> listCollection(RemoteCollectionSpec spec) async {
    _ensureConfigured();
    final List<Map<String, dynamic>> payloads = <Map<String, dynamic>>[];
    int offset = 0;
    while (true) {
      final Uri uri = config.restUri(spec.table).replace(
        queryParameters: <String, String>{
          'select': 'id,payload',
          'order': 'updated_at.desc',
          'limit': config.pageSize.toString(),
          'offset': offset.toString(),
        },
      );
      final http.Response response = await _request(
        () => _client.get(uri, headers: _baseHeaders),
        acceptedStatusCodes: const <int>{200},
      );
      final List<dynamic> decoded = jsonDecode(response.body) as List<dynamic>;
      for (final dynamic row in decoded) {
        final Map<String, dynamic> rowMap = row as Map<String, dynamic>;
        final Object? payload = rowMap['payload'];
        if (payload is Map<String, dynamic>) {
          payloads.add(payload);
        } else if (payload is Map) {
          payloads.add(Map<String, dynamic>.from(payload));
        }
      }
      if (decoded.length < config.pageSize) {
        break;
      }
      offset += config.pageSize;
    }
    return payloads;
  }

  Future<void> replaceCollection({
    required RemoteCollectionSpec spec,
    required List<Map<String, dynamic>> items,
  }) async {
    _ensureConfigured();
    if (items.isNotEmpty) {
      final List<Map<String, dynamic>> rows = items
          .map<Map<String, dynamic>>(
            (Map<String, dynamic> item) => <String, dynamic>{
              'id': (item[spec.idField] ?? '').toString(),
              'owner_user_id': spec.ownerField == null ? null : item[spec.ownerField!],
              'payload': item,
              'search_text': _buildSearchText(item),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
          )
          .where((Map<String, dynamic> row) => (row['id'] as String).isNotEmpty)
          .toList(growable: false);
      if (rows.isNotEmpty) {
        await _request(
          () => _client.post(
            config.restUri(spec.table),
            headers: <String, String>{
              ..._baseHeaders,
              'Prefer': 'resolution=merge-duplicates',
            },
            body: jsonEncode(rows),
          ),
          acceptedStatusCodes: const <int>{200, 201, 204},
        );
      }
    }
  }

  Future<void> deleteCollectionRow({
    required RemoteCollectionSpec spec,
    required String id,
  }) async {
    _ensureConfigured();
    if (id.trim().isEmpty) {
      return;
    }
    final Uri deleteUri = config.restUri(spec.table).replace(
      queryParameters: <String, String>{'id': 'eq.$id'},
    );
    await _request(
      () => _client.delete(deleteUri, headers: _baseHeaders),
      acceptedStatusCodes: const <int>{200, 204},
    );
  }

  Future<String> uploadBytes({
    required Uint8List bytes,
    required String path,
    required String contentType,
  }) async {
    _ensureConfigured();
    await _request(
      () => _client.put(
        config.storageUri(path),
        headers: <String, String>{
          'apikey': config.supabaseAnonKey,
          'Authorization': 'Bearer $_authorizationToken',
          'Content-Type': contentType,
          'x-upsert': 'true',
        },
        body: bytes,
      ),
      acceptedStatusCodes: const <int>{200, 201},
    );
    return config.publicStorageUri(path).toString();
  }

  Future<void> registerPushToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    _ensureConfigured();
    final Map<String, dynamic> payload = <String, dynamic>{
      'id': '${userId}_$platform',
      'owner_user_id': userId,
      'payload': <String, dynamic>{
        'userId': userId,
        'token': token,
        'platform': platform,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      'search_text': '$userId $platform',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await _request(
      () => _client.post(
        config.restUri('push_tokens'),
        headers: <String, String>{
          ..._baseHeaders,
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode(<Map<String, dynamic>>[payload]),
      ),
      acceptedStatusCodes: const <int>{200, 201, 204},
    );
  }

  Future<void> createPushNotificationIntent({
    required String userId,
    required String title,
    required String body,
    required String eventType,
    String? targetId,
  }) async {
    _ensureConfigured();
    final String id = 'push_${DateTime.now().microsecondsSinceEpoch}';
    final Map<String, dynamic> payload = <String, dynamic>{
      'id': id,
      'owner_user_id': userId,
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
      'search_text': '$title $body $eventType',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await _request(
      () => _client.post(
        config.restUri('push_notification_queue'),
        headers: <String, String>{..._baseHeaders},
        body: jsonEncode(<Map<String, dynamic>>[payload]),
      ),
      acceptedStatusCodes: const <int>{200, 201, 204},
    );
  }

  Future<http.Response> _request(
    Future<http.Response> Function() operation, {
    required Set<int> acceptedStatusCodes,
  }) async {
    final RuntimeDiagnosticsService diagnostics = RuntimeDiagnosticsService.instance;
    final Stopwatch stopwatch = Stopwatch()..start();
    Object? lastError;
    for (int attempt = 0; attempt <= config.retryCount; attempt++) {
      try {
        final http.Response response = await operation().timeout(
          Duration(seconds: config.requestTimeoutSeconds),
        );
        diagnostics.recordNetworkTransfer(
          receivedBytes: response.bodyBytes.length,
          sentBytes: response.request?.contentLength ?? 0,
        );
        if (acceptedStatusCodes.contains(response.statusCode)) {
          stopwatch.stop();
          diagnostics.recordPerformance(
            'backend_request',
            stopwatch.elapsed,
            extra: <String, String>{'status': response.statusCode.toString(), 'attempt': attempt.toString()},
          );
          return response;
        }
        throw BackendException(
          'فشل طلب الخادم.',
          statusCode: response.statusCode,
          details: response.body,
        );
      } on TimeoutException catch (error, stackTrace) {
        lastError = const BackendTimeoutException();
        diagnostics.recordError(error, stackTrace, source: 'backend_timeout');
      } on BackendException catch (error, stackTrace) {
        if (error.statusCode != null && error.statusCode! < 500) {
          diagnostics.recordError(error, stackTrace, source: 'backend_rejected');
          rethrow;
        }
        lastError = error;
        diagnostics.recordError(error, stackTrace, source: 'backend_retryable');
      } catch (error, stackTrace) {
        lastError = const BackendNetworkException();
        diagnostics.recordError(error, stackTrace, source: 'backend_network');
      }
      if (attempt < config.retryCount) {
        await Future<void>.delayed(Duration(milliseconds: 350 * (attempt + 1)));
      }
    }
    stopwatch.stop();
    diagnostics.recordPerformance('backend_request_failed', stopwatch.elapsed);
    if (lastError is BackendException) {
      throw lastError;
    }
    throw const BackendNetworkException();
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

  void _ensureConfigured() {
    if (!isEnabled) {
      throw const BackendException(
        'إعدادات Supabase غير مفعّلة. أضف MAKAAN_SUPABASE_URL و MAKAAN_SUPABASE_ANON_KEY عند التشغيل.',
      );
    }
  }
}
