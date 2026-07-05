import 'dart:async';
import 'dart:developer' as developer;

class RuntimeErrorEntry {
  const RuntimeErrorEntry({
    required this.message,
    required this.source,
    required this.createdAt,
    this.stackTrace,
  });

  final String message;
  final String source;
  final DateTime createdAt;
  final String? stackTrace;
}

class PerformanceSample {
  const PerformanceSample({
    required this.name,
    required this.duration,
    required this.createdAt,
    this.extra = const <String, String>{},
  });

  final String name;
  final Duration duration;
  final DateTime createdAt;
  final Map<String, String> extra;

  String get summary => '${duration.inMilliseconds} ms';
}

class RuntimeDiagnosticsService {
  RuntimeDiagnosticsService._();

  static final RuntimeDiagnosticsService instance = RuntimeDiagnosticsService._();

  final List<RuntimeErrorEntry> _errors = <RuntimeErrorEntry>[];
  final List<PerformanceSample> _performanceSamples = <PerformanceSample>[];
  int _networkBytesReceived = 0;
  int _networkBytesSent = 0;

  List<RuntimeErrorEntry> get recentErrors => List<RuntimeErrorEntry>.unmodifiable(_errors.reversed.take(80));

  List<PerformanceSample> get recentPerformanceSamples =>
      List<PerformanceSample>.unmodifiable(_performanceSamples.reversed.take(80));

  int get networkBytesReceived => _networkBytesReceived;
  int get networkBytesSent => _networkBytesSent;

  Future<T> trackAsync<T>(String name, Future<T> Function() action, {Map<String, String> extra = const <String, String>{}}) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    try {
      return await action();
    } catch (error, stackTrace) {
      recordError(error, stackTrace, source: name);
      rethrow;
    } finally {
      stopwatch.stop();
      recordPerformance(name, stopwatch.elapsed, extra: extra);
    }
  }

  T trackSync<T>(String name, T Function() action, {Map<String, String> extra = const <String, String>{}}) {
    final Stopwatch stopwatch = Stopwatch()..start();
    try {
      return action();
    } catch (error, stackTrace) {
      recordError(error, stackTrace, source: name);
      rethrow;
    } finally {
      stopwatch.stop();
      recordPerformance(name, stopwatch.elapsed, extra: extra);
    }
  }

  void recordPerformance(String name, Duration duration, {Map<String, String> extra = const <String, String>{}}) {
    _performanceSamples.add(
      PerformanceSample(name: name, duration: duration, createdAt: DateTime.now(), extra: extra),
    );
    _trim(_performanceSamples, 120);
    developer.Timeline.instantSync('Makaan performance: $name', arguments: <String, Object>{
      'durationMs': duration.inMilliseconds,
      ...extra,
    });
  }

  void recordNetworkTransfer({int receivedBytes = 0, int sentBytes = 0}) {
    _networkBytesReceived += receivedBytes < 0 ? 0 : receivedBytes;
    _networkBytesSent += sentBytes < 0 ? 0 : sentBytes;
  }

  void recordError(Object error, StackTrace? stackTrace, {String source = 'runtime'}) {
    _errors.add(
      RuntimeErrorEntry(
        message: error.toString(),
        source: source,
        stackTrace: stackTrace?.toString(),
        createdAt: DateTime.now(),
      ),
    );
    _trim(_errors, 120);
    developer.log(error.toString(), name: 'Makaan.$source', stackTrace: stackTrace);
  }

  void _trim<T>(List<T> items, int maxLength) {
    if (items.length > maxLength) {
      items.removeRange(0, items.length - maxLength);
    }
  }
}
