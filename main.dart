import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_controller.dart';
import 'shared/backend/firebase_production_bootstrap.dart';
import 'shared/services/runtime_diagnostics_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseProductionBootstrap.initialize();
  AppController? controller;

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    RuntimeDiagnosticsService.instance.recordError(
      details.exception,
      details.stack,
      source: details.library ?? 'flutter',
    );
    unawaited(
      controller?.recordRuntimeError(
            details.exception,
            details.stack,
            source: details.library ?? 'flutter',
          ) ??
          Future<void>.value(),
    );
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    RuntimeDiagnosticsService.instance.recordError(error, stackTrace, source: 'platform_dispatcher');
    unawaited(
      controller?.recordRuntimeError(error, stackTrace, source: 'platform_dispatcher') ??
          Future<void>.value(),
    );
    return true;
  };

  await (runZonedGuarded<Future<void>>(
        () async {
          controller = await RuntimeDiagnosticsService.instance.trackAsync(
            'app_bootstrap',
            AppController.bootstrap,
          );
          runApp(
            AppScope(
              controller: controller!,
              child: MakaanApp(controller: controller!),
            ),
          );
        },
        (Object error, StackTrace stackTrace) {
          RuntimeDiagnosticsService.instance.recordError(error, stackTrace, source: 'zone');
          unawaited(
            controller?.recordRuntimeError(error, stackTrace, source: 'zone') ??
                Future<void>.value(),
          );
        },
      ) ??
      Future<void>.value());
}
