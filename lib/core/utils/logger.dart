import 'dart:developer' as developer;

class Logger {
  static const String _tag = 'TaskManager';

  // Log levels
  static const int _levelInfo = 0;
  static const int _levelWarning = 1;
  static const int _levelError = 2;
  static const int _levelDebug = 3;

  // Enable/disable logging
  static bool _isEnabled = true;

  static void enable() {
    _isEnabled = true;
  }

  static void disable() {
    _isEnabled = false;
  }

  // Info log
  static void info(String message, [String? tag]) {
    _log(message, _levelInfo, tag ?? _tag);
  }

  // Warning log
  static void warning(String message, [String? tag]) {
    _log(message, _levelWarning, tag ?? _tag);
  }

  // Error log
  static void error(
    String message, [
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _log(message, _levelError, tag ?? _tag, error, stackTrace);
  }

  // Debug log
  static void debug(String message, [String? tag]) {
    _log(message, _levelDebug, tag ?? _tag);
  }

  // Private log method
  static void _log(
    String message,
    int level,
    String tag, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!_isEnabled) return;

    final String levelString = _getLevelString(level);
    final String logMessage = '[$tag] $levelString: $message';

    switch (level) {
      case _levelInfo:
        developer.log(logMessage, name: tag, level: 800);
        break;
      case _levelWarning:
        developer.log(logMessage, name: tag, level: 900);
        break;
      case _levelError:
        developer.log(
          logMessage,
          name: tag,
          level: 1000,
          error: error,
          stackTrace: stackTrace,
        );
        break;
      case _levelDebug:
        developer.log(logMessage, name: tag, level: 700);
        break;
    }
  }

  // Get level string
  static String _getLevelString(int level) {
    switch (level) {
      case _levelInfo:
        return 'INFO';
      case _levelWarning:
        return 'WARNING';
      case _levelError:
        return 'ERROR';
      case _levelDebug:
        return 'DEBUG';
      default:
        return 'UNKNOWN';
    }
  }
}
