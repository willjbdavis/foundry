import 'logging.dart';

/// Global Foundry runtime configuration and logging entrypoint.
final class Foundry {
  Foundry._();

  static FoundryLogger? _logger;
  static String? _deepLinkFallbackPath;

  /// Sets the active logger instance used by all Foundry packages.
  static void configureLogger(FoundryLogger logger) {
    _logger = logger;
  }

  /// Sets the active logger from a simple callback.
  static void configureLoggerFn(void Function(LogEvent event) fn) {
    _logger = _FunctionLogger(fn);
  }

  /// Clears the active logger.
  ///
  /// Primarily useful in tests.
  static void clearLogger() {
    _logger = null;
  }

  /// Emits a structured log event when a logger is configured.
  static void log(LogEvent event) {
    _logger?.log(event);
  }

  /// Configures a fallback deep-link path used by generated resolvers on miss.
  ///
  /// Example: `/home`.
  static void configureDeepLinkFallbackPath(String path) {
    _deepLinkFallbackPath = path;
  }

  /// Clears the configured deep-link fallback path.
  static void clearDeepLinkFallbackPath() {
    _deepLinkFallbackPath = null;
  }

  /// Returns the configured deep-link fallback path if provided.
  static String? get deepLinkFallbackPath => _deepLinkFallbackPath;
}

class _FunctionLogger implements FoundryLogger {
  _FunctionLogger(this._fn);

  final void Function(LogEvent event) _fn;

  @override
  void log(LogEvent event) => _fn(event);
}
