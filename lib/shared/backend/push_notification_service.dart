import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'remote_backend_client.dart';

class PushNotificationService {
  const PushNotificationService(this._backend);

  final RemoteBackendClient? _backend;

  bool get isEnabled => _backend?.isEnabled ?? false;

  Future<void> registerCurrentDevice({required String userId}) async {
    if (!isEnabled || !Firebase.apps.isNotEmpty) {
      return;
    }
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await messaging.setAutoInitEnabled(true);
      final String? token = await messaging.getToken();
      if (token == null || token.trim().isEmpty) {
        return;
      }
      await registerDeviceToken(
        userId: userId,
        token: token,
        platform: defaultTargetPlatform.name,
      );
    } catch (_) {
      // Token registration must not block login or app startup.
    }
  }

  Future<void> registerDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    if (!isEnabled || token.trim().isEmpty) {
      return;
    }
    await _backend!.registerPushToken(userId: userId, token: token.trim(), platform: platform);
  }

  Future<void> enqueueNotification({
    required String userId,
    required String title,
    required String body,
    required String eventType,
    String? targetId,
  }) async {
    if (!isEnabled) {
      return;
    }
    await _backend!.createPushNotificationIntent(
      userId: userId,
      title: title,
      body: body,
      eventType: eventType,
      targetId: targetId,
    );
  }
}
