import 'dart:developer' as developer;

/// Logger abstraction to keep TipTool free of direct `print` usage.
abstract class TTLogger {
  void debug(String message, {Map<String, Object?>? context});

  void info(String message, {Map<String, Object?>? context});

  void warn(
    String message, {
    Map<String, Object?>? context,
    Object? error,
    StackTrace? stackTrace,
  });

  void error(
    String message, {
    Map<String, Object?>? context,
    Object? error,
    StackTrace? stackTrace,
  });
}

/// Minimal logger that mirrors the current behaviour (developer log output).
class PrintLogger implements TTLogger {
  const PrintLogger({this.includeTimestamp = true});

  final bool includeTimestamp;

  String _prefix(String level) {
    if (!includeTimestamp) {
      return level;
    }
    final timestamp = DateTime.now().toUtc().toIso8601String();
    return '[$timestamp][$level]';
  }

  @override
  void debug(String message, {Map<String, Object?>? context}) {
    _log('DEBUG', message, context: context);
  }

  @override
  void info(String message, {Map<String, Object?>? context}) {
    _log('INFO', message, context: context);
  }

  @override
  void warn(
    String message, {
    Map<String, Object?>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      'WARN',
      message,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void error(
    String message, {
    Map<String, Object?>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      'ERROR',
      message,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _log(
    String level,
    String message, {
    Map<String, Object?>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final buffer = StringBuffer()
      ..write(_prefix(level))
      ..write(' ')
      ..write(message);

    if (context != null && context.isNotEmpty) {
      buffer
        ..write(' ')
        ..write(context);
    }

    if (error != null) {
      buffer
        ..write(' error=')
        ..write(error);
    }

    if (stackTrace != null) {
      buffer
        ..write('\n')
        ..write(stackTrace);
    }

    developer.log(buffer.toString(), name: 'tisane', level: _levelFor(level));
  }

  int _levelFor(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'WARN':
        return 900;
      case 'ERROR':
        return 1000;
      default:
        return 0;
    }
  }
}

/// Factory helper to mirror existing logging behaviour without new singletons.
TTLogger createDefaultLogger() => const PrintLogger();
