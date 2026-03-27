/// Lifetime strategy for a registration.
enum Lifetime {
  /// Create once and reuse the same instance for all resolutions.
  singleton,

  /// Create once per requesting scope and reuse within that scope.
  scoped,

  /// Create a new instance for each resolution.
  transient,
}

/// Base interface for all scopes in the DI container.
abstract interface class Scope {
  /// Resolves an instance of type [T] from this scope or parent scopes.
  ///
  /// If [named] is provided, resolves a named registration.
  ///
  /// [requestScope] is used internally when a child scope falls back to a
  /// parent registration and the registration has [Lifetime.scoped].
  T resolve<T>({String? named, Scope? requestScope});

  /// Registers an instance factory for type [T].
  ///
  /// If [named] is provided, registers a named instance.
  ///
  /// [lifetime] defaults to [Lifetime.singleton] for backward compatibility.
  void register<T>(
    T Function(Scope scope) factory, {
    String? named,
    Lifetime lifetime = Lifetime.singleton,
  });

  /// Creates a child scope with this scope as parent.
  Scope createChild();

  /// Disposes this scope and all its local registrations.
  void dispose();
}
