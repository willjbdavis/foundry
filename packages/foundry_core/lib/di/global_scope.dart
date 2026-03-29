import 'scope.dart';
import 'child_scope.dart';
import 'scope_key.dart';
import '../foundry.dart';
import '../logging.dart';

/// Global scope for the application.
///
/// This is the root scope that contains app-wide singletons and configuration.
class GlobalScope implements Scope {
  final Map<String, _Registration> _registrations = <String, _Registration>{};
  final List<ChildScope> _children = <ChildScope>[];
  bool _disposed = false;

  /// Creates a new global scope.
  GlobalScope._();

  /// Creates and returns a new global scope instance.
  static GlobalScope create() => GlobalScope._();

  @override
  T resolve<T>({String? named, Scope? requestScope}) {
    _throwIfDisposed();

    final Scope targetScope = requestScope ?? this;
    final String key = buildScopeKey<T>(named);
    final _Registration? registration = _registrations[key];
    if (registration == null) {
      Foundry.log(
        LogEvent(
          level: LogLevel.error,
          tag: 'di.global_scope',
          message: 'Resolve failed: missing registration for type $T.',
        ),
      );
      throw StateError(
        'No registration found in GlobalScope for type $T'
        '${named != null ? ' with name $named' : ''}.',
      );
    }

    Foundry.log(
      LogEvent(
        level: LogLevel.debug,
        tag: 'di.global_scope',
        message: 'Resolving type $T from GlobalScope.',
      ),
    );

    return registration.resolve(ownerScope: this, requestScope: targetScope)
        as T;
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
        tag: 'di.global_scope',
        message: 'Registered type $T with lifetime $lifetime.',
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
        tag: 'di.global_scope',
        message: 'Created child scope.',
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
        tag: 'di.global_scope',
        message: 'Disposing GlobalScope with ${_children.length} children.',
      ),
    );

    for (final ChildScope child in List<ChildScope>.from(_children.reversed)) {
      child.dispose();
    }
    _children.clear();
    _registrations.clear();
    _disposed = true;
  }

  void _onChildDisposed(final ChildScope child) {
    _children.remove(child);
    Foundry.log(
      const LogEvent(
        level: LogLevel.debug,
        tag: 'di.global_scope',
        message: 'Child scope disposed.',
      ),
    );
  }

  void _throwIfDisposed() {
    if (_disposed) {
      Foundry.log(
        const LogEvent(
          level: LogLevel.error,
          tag: 'di.global_scope',
          message: 'Operation attempted after GlobalScope disposal.',
        ),
      );
      throw StateError('GlobalScope has been disposed.');
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
