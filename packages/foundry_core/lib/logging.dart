/// Severity levels for Foundry runtime logs.
enum LogLevel { trace, debug, info, warning, error }

/// Structured log payload emitted by Foundry runtime packages.
class LogEvent {
  /// Creates a structured runtime log event.
  ///
  /// [level] and [message] are required for every event. Use [tag] to group
  /// related logs and include [error]/[stackTrace] for failure diagnostics.
  const LogEvent({
    required this.level,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
  });

  /// Severity level used for filtering and sink routing.
  final LogLevel level;

  /// Human-readable log message.
  final String message;

  /// Optional category identifier for grouping related events.
  final String? tag;

  /// Optional error payload associated with this log entry.
  final Object? error;

  /// Optional stack trace associated with [error].
  final StackTrace? stackTrace;
}

/// Logger contract that applications can implement and register with Foundry.
abstract class FoundryLogger {
  /// Records [event] in the destination logger implementation.
  void log(LogEvent event);
}
