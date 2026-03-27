import 'scope.dart';
import 'scope_key.dart';

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
      return registration.resolve(ownerScope: this, requestScope: targetScope)
          as T;
    }

    // Then fallback to parent scope if exists
    if (parent != null) {
      return parent!.resolve<T>(named: named, requestScope: targetScope);
    }

    // No registration found
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
  }

  @override
  Scope createChild() {
    _throwIfDisposed();
    final ChildScope child = ChildScope(this, onDispose: _onChildDisposed);
    _children.add(child);
    return child;
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

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
  }

  void _throwIfDisposed() {
    if (_disposed) {
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
