/// Severity levels for Foundry runtime logs.
enum LogLevel { debug, info, warning, error }

/// Structured log payload emitted by Foundry runtime packages.
class LogEvent {
  const LogEvent({
    required this.level,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
  });

  final LogLevel level;
  final String message;
  final String? tag;
  final Object? error;
  final StackTrace? stackTrace;
}

/// Logger contract that applications can implement and register with Foundry.
abstract class FoundryLogger {
  void log(LogEvent event);
}
