/// Marker interface for types that require asynchronous startup
/// initialization after DI registration.
abstract interface class AsyncInitializable {
  /// Performs one-time startup initialization.
  Future<void> initialize();
}
