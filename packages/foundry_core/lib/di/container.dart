import 'scope.dart';
import 'global_scope.dart';

/// Container for dependency injection.
///
/// The container manages registration and resolution of dependencies
/// within a hierarchical scope tree.
class Container {
  /// The global scope for the application.
  final GlobalScope globalScope;

  /// Creates a new container with a global scope.
  Container() : globalScope = GlobalScope.create();

  /// Registers a dependency factory with the global scope.
  void register<T>(
    T Function(Scope scope) factory, {
    String? named,
    Lifetime lifetime = Lifetime.singleton,
  }) {
    globalScope.register<T>(factory, named: named, lifetime: lifetime);
  }

  /// Resolves a dependency from the global scope.
  T resolve<T>({String? named, Scope? requestScope}) {
    return globalScope.resolve<T>(named: named, requestScope: requestScope);
  }

  /// Creates a child scope for feature/view-specific registrations.
  Scope createChild() {
    return globalScope.createChild();
  }
}
