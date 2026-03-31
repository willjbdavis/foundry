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

  /// Scoped instances cached back from parent-scope resolutions.
  ///
  /// When a [Lifetime.scoped] type is first resolved via a parent scope on
  /// behalf of this scope, the result is stored here so subsequent resolves
  /// are served locally without re-delegating to the parent.
  final Map<String, Object> _scopedCache = <String, Object>{};

  final List<ChildScope> _children = <ChildScope>[];
  bool _disposed = false;

  @override
  T resolve<T>({String? named, Scope? requestScope}) {
    _throwIfDisposed();

    final Scope targetScope = requestScope ?? this;
    final String key = buildScopeKey<T>(named);

    // 1. Explicit local registrations (test overrides, view-local shadowing).
    final _Registration? registration = _registrations[key];
    if (registration != null) {
      Foundry.log(
        LogEvent(
          level: LogLevel.debug,
          tag: 'di.child_scope',
          message:
              'Resolved $T from child scope '
              '(local registration, ${registration._lifetime.name}).',
        ),
      );
      return registration.resolve(ownerScope: this, requestScope: targetScope)
          as T;
    }

    // 2. Scoped-instance cache — populated by the parent scope on first
    //    resolution, so repeated resolves are served locally.
    final Object? cached = _scopedCache[key];
    if (cached != null) {
      Foundry.log(
        LogEvent(
          level: LogLevel.debug,
          tag: 'di.child_scope',
          message:
              'Resolved $T from child scope '
              '(scoped — scope-local cache hit, no parent delegation needed).',
        ),
      );
      return cached as T;
    }

    // 3. Delegate to parent scope (first resolution, or transient types).
    if (parent != null) {
      Foundry.log(
        LogEvent(
          level: LogLevel.debug,
          tag: 'di.child_scope',
          message: 'No local entry for $T — delegating to parent scope.',
        ),
      );
      return parent!.resolve<T>(named: named, requestScope: targetScope);
    }

    // 4. Not found anywhere in the hierarchy.
    Foundry.log(
      LogEvent(
        level: LogLevel.error,
        tag: 'di.child_scope',
        message: 'Resolve failed: no registration for $T in scope hierarchy.',
      ),
    );
    throw StateError(
      'No registration found in scope hierarchy for type $T'
      '${named != null ? ' with name $named' : ''}.',
    );
  }

  /// Caches a pre-resolved scoped instance so future resolves from this scope
  /// are served locally without re-delegating to the parent scope.
  ///
  /// Called by a parent scope after resolving a [Lifetime.scoped] type on
  /// behalf of this scope for the first time.
  void cacheResolvedScoped(final String key, final Object instance) {
    _throwIfDisposed();
    _scopedCache.putIfAbsent(key, () => instance);
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
        message: 'Registered $T in child scope (lifetime: ${lifetime.name}).',
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
    _scopedCache.clear();
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

/// Internal registration record used by [ChildScope].
///
/// Mirrors global registration behavior while keeping cache ownership local to
/// the current child scope hierarchy.
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
