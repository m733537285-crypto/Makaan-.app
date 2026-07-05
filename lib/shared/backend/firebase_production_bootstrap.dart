import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../services/runtime_diagnostics_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

class FirebaseProductionBootstrap {
  const FirebaseProductionBootstrap._();

  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      RuntimeDiagnosticsService.instance.recordPerformance(
        'firebase_bootstrap',
        Duration.zero,
        extra: <String, String>{'status': 'initialized'},
      );
    } catch (error, stackTrace) {
      RuntimeDiagnosticsService.instance.recordError(error, stackTrace, source: 'firebase_bootstrap');
    }
  }
}
