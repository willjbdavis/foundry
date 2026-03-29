import 'scope.dart';
import 'scope_key.dart';
import '../foundry.dart';
import '../logging.dart';

/// Child scope for feature or view-specific registrations.
///
/// Child scopes can resolve instances from their local registrations
/// and fallback to parent scopes. They support shadowing of parent
/// registrations for testing and environment-specific wiring.
class ChildScope implements Scope {
  ChildScope(this.parent, {this.onDispose});

  /// The parent scope, or null for global scope.
  final Scope? parent;

  final void Function(ChildScope child)? onDispose;

  /// Local registrations for this scope.
  final Map<String, _Registration> _registrations = <String, _Registration>{};
  final List<ChildScope> _children = <ChildScope>[];
  bool _disposed = false;

  @override
  T resolve<T>({String? named, Scope? requestScope}) {
    _throwIfDisposed();

    final Scope targetScope = requestScope ?? this;

    // First check local registrations
    final String key = buildScopeKey<T>(named);
    final _Registration? registration = _registrations[key];
    if (registration != null) {
      Foundry.log(
        LogEvent(
          level: LogLevel.debug,
          tag: 'di.child_scope',
          message: 'Resolving local type $T from ChildScope.',
        ),
      );

      return registration.resolve(ownerScope: this, requestScope: targetScope)
          as T;
    }

    // Then fallback to parent scope if exists
    if (parent != null) {
      Foundry.log(
        LogEvent(
          level: LogLevel.debug,
          tag: 'di.child_scope',
          message: 'Falling back to parent scope for type $T.',
        ),
      );

      return parent!.resolve<T>(named: named, requestScope: targetScope);
    }

    // No registration found
    Foundry.log(
      LogEvent(
        level: LogLevel.error,
        tag: 'di.child_scope',
        message: 'Resolve failed: missing registration for type $T.',
      ),
    );
    throw StateError(
      'No registration found in scope hierarchy for type $T'
      '${named != null ? ' with name $named' : ''}.',
    );
  }

  @override
  void register<T>(
    T Function(Scope scope) factory, {
    String? named,
    Lifetime lifetime = Lifetime.singleton,
  }) {
    _throwIfDisposed();
    final String key = buildScopeKey<T>(named);
    _registrations[key] = _Registration(factory, lifetime);
    Foundry.log(
      LogEvent(
        level: LogLevel.info,
        tag: 'di.child_scope',
        message: 'Registered local type $T with lifetime $lifetime.',
      ),
    );
  }

  @override
  Scope createChild() {
    _throwIfDisposed();
    final ChildScope child = ChildScope(this, onDispose: _onChildDisposed);
    _children.add(child);
    Foundry.log(
      const LogEvent(
        level: LogLevel.debug,
        tag: 'di.child_scope',
        message: 'Created nested child scope.',
      ),
    );

    return child;
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    Foundry.log(
      LogEvent(
        level: LogLevel.info,
        tag: 'di.child_scope',
        message: 'Disposing ChildScope with ${_children.length} children.',
      ),
    );

    for (final ChildScope child in List<ChildScope>.from(_children.reversed)) {
      child.dispose();
    }
    _children.clear();
    _registrations.clear();
    _disposed = true;
    onDispose?.call(this);
  }

  void _onChildDisposed(final ChildScope child) {
    _children.remove(child);
    Foundry.log(
      const LogEvent(
        level: LogLevel.debug,
        tag: 'di.child_scope',
        message: 'Nested child scope disposed.',
      ),
    );
  }

  void _throwIfDisposed() {
    if (_disposed) {
      Foundry.log(
        const LogEvent(
          level: LogLevel.error,
          tag: 'di.child_scope',
          message: 'Operation attempted after ChildScope disposal.',
        ),
      );
      throw StateError('ChildScope has been disposed.');
    }
  }
}

class _Registration {
  _Registration(this._factory, this._lifetime);

  final Function(Scope) _factory;
  final Lifetime _lifetime;
  Object? _singletonInstance;
  bool _singletonCreated = false;
  final Expando<Object> _scopedInstances = Expando<Object>('scopedInstance');

  Object resolve({required Scope ownerScope, required Scope requestScope}) {
    switch (_lifetime) {
      case Lifetime.singleton:
        if (_singletonCreated) {
          return _singletonInstance as Object;
        }
        _singletonInstance = _factory(ownerScope);
        _singletonCreated = true;
        return _singletonInstance as Object;
      case Lifetime.scoped:
        final Object? existing = _scopedInstances[requestScope];
        if (existing != null) {
          return existing;
        }
        final Object created = _factory(requestScope) as Object;
        _scopedInstances[requestScope] = created;
        return created;
      case Lifetime.transient:
        return _factory(requestScope) as Object;
    }
  }
}
