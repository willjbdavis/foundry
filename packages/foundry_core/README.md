# foundry_core

Core runtime primitives for the [Foundry MVVM framework](../foundry_flutter). This package provides the state contracts, ViewModel and model base classes, and the scoped dependency injection runtime that the rest of the stack builds on.

`foundry_core` is the package that defines how Foundry behaves at runtime. `foundry_annotations` describes your architecture at compile time, `foundry_generator` removes boilerplate, and `foundry_flutter` adds the higher-level Flutter widget integration most apps use.

## Table of Contents

- [Concepts](#concepts)
- [Setup](#setup)
- [State and ViewModels](#state-and-viewmodels)
- [Stateful Services](#stateful-services)
- [Scoped Dependency Injection](#scoped-dependency-injection)
- [`Container`](#container)
- [Relationship To Other Packages](#relationship-to-other-packages)

---

## Concepts

| Concept | Class | Role |
|---|---|---|
| Reactive state contract | `StateEmitter<S>` | Exposes the current `state` and a `states` stream of future emissions. |
| ViewModel base | `FoundryViewModel<S>` | Owns UI state and lifecycle hooks like `onInit`, `onPaused`, and `onDispose`. |
| Stateful domain service | `StatefulService<S>` | Emits domain state and lets other services subscribe directly. |
| View base | `FoundryView<TViewModel, TState>` | Low-level widget base with `buildWithState(...)`. Most Flutter apps use the higher-level wrapper from `foundry_flutter`. |
| Root DI scope | `GlobalScope` | Application-wide registrations and singleton lifetime boundary. |
| Child DI scope | `ChildScope` | Feature or subtree-local registrations with parent fallback and shadowing. |
| Convenience container | `Container` | Thin wrapper around `GlobalScope` for simple bootstrapping. |

---

## Setup

```yaml
dependencies:
  foundry_core: ^0.0.1
```

If you are building a Flutter UI with Foundry, you will usually also depend on `foundry_flutter`, which re-exports `foundry_core` and adds widget-tree integration.

---

## State and ViewModels

`FoundryViewModel<S>` is the base class for state-owning presentation logic. It exposes a synchronous `state` getter, a `states` stream, and protected lifecycle hooks that the framework calls for you.

```dart
import 'package:foundry_core/foundry_core.dart';

class HomeState {
  final bool isLoading;
  final List<String> items;

  const HomeState({
    this.isLoading = false,
    this.items = const [],
  });

  HomeState copyWith({bool? isLoading, List<String>? items}) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
    );
  }
}

class HomeViewModel extends FoundryViewModel<HomeState> {
  final ItemRepository _repo;

  HomeViewModel(this._repo) {
    emitNewState(const HomeState(isLoading: true));
  }

  @override
  Future<void> onInit() async {
    final items = await _repo.fetchAll();
    emitNewState(HomeState(isLoading: false, items: items));
  }

  Future<void> refresh() async {
    emitNewState(state.copyWith(isLoading: true));
    final items = await _repo.fetchAll();
    emitNewState(state.copyWith(isLoading: false, items: items));
  }
}
```

### ViewModel lifecycle

`FoundryViewModel<S>` exposes these hooks:

| Event | Hook |
|---|---|
| Initial binding | `onInit()` |
| Foreground / resume | `onResumed()` |
| Background / pause | `onPaused()` |
| ViewModel disposal | `onDispose()` |
| Back navigation interception | `onBackPressed()` |
| Unhandled async error forwarding | `onError(error, stackTrace)` |

You call `emitNewState(...)` from the subclass; the framework is responsible for invoking the lifecycle entrypoints.

If the ViewModel will be bound by `foundry_flutter`, give it an initial state before `onInit()` runs because the Flutter binding reads `state` immediately after resolution.

---

## Stateful Services

`StatefulService<S>` is the domain/runtime sibling to `FoundryViewModel<S>`. Use it for long-lived domain objects that emit state and may be shared by multiple consumers.

```dart
import 'package:foundry_core/foundry_core.dart';

class CartState {
  final List<String> itemIds;

  const CartState({this.itemIds = const []});

  CartState copyWith({List<String>? itemIds}) {
    return CartState(itemIds: itemIds ?? this.itemIds);
  }
}

class CartModel extends StatefulService<CartState> {
  CartModel() {
    emitNewState(const CartState());
  }

  void addItem(String id) {
    emitNewState(state.copyWith(itemIds: [...state.itemIds, id]));
  }
}

class CheckoutModel {
  final CartModel _cartModel;
  void Function(CartState)? _subscription;

  CheckoutModel(this._cartModel);

  Future<void> onInit() async {
    _subscription = (state) {
      // react to cart updates
    };
    _cartModel.subscribe(_subscription!);
  }

  Future<void> onDispose() async {
    _cartModel.unsubscribe(_subscription);
  }
}
```

`StatefulService` uses the same `state` + `states` pattern as `FoundryViewModel`, but also exposes `subscribe` / `unsubscribe` for direct service-to-service coordination.

---

## Scoped Dependency Injection

Foundry's DI runtime is deliberately small. A `Scope` can register factories, resolve instances, create child scopes, and dispose the subtree.

```dart
import 'package:foundry_core/foundry_core.dart';

final GlobalScope globalScope = GlobalScope.create();

globalScope.register<ApiClient>((_) => ApiClient());
globalScope.register<ItemRepository>((scope) {
  return ItemRepository(scope.resolve<ApiClient>());
});
globalScope.register<CartViewModel>(
  (scope) => CartViewModel(scope.resolve<ItemRepository>()),
  lifetime: Lifetime.scoped,
);

final Scope featureScope = globalScope.createChild();
featureScope.register<String>((_) => 'checkout', named: 'featureName');

final ItemRepository repo = featureScope.resolve<ItemRepository>();
final String featureName = featureScope.resolve<String>(named: 'featureName');
```

### Scope rules

| Rule | Behavior |
|---|---|
| Resolution order | Resolve checks the current scope first, then walks up to parent scopes. |
| Lifetime | Registrations support `singleton`, `scoped`, and `transient` lifetimes. |
| Shadowing | A child scope can override the same type/name registration from its parent. |
| Disposal | Disposing a scope disposes its children first, then clears its own registrations. |

This makes child scopes a good fit for feature subtrees, tests, and environment-specific overrides.

### Lifetime strategies

```dart
final root = GlobalScope.create();

// App-wide shared instance.
root.register<ApiClient>((_) => ApiClient());

// One instance per requesting scope (recommended for ViewModels).
root.register<HomeViewModel>(
  (s) => HomeViewModel(s.resolve<ApiClient>()),
  lifetime: Lifetime.scoped,
);

// New instance every resolve call.
root.register<RequestIdGenerator>(
  (_) => RequestIdGenerator(),
  lifetime: Lifetime.transient,
);
```

Recommended policy:
- ViewModels: `Lifetime.scoped`
- Repositories/services/models: `Lifetime.singleton`
- Stateless helpers: `Lifetime.transient` when needed

### Startup initialization

For singleton services/models that need async startup work, implement
`AsyncInitializable`:

```dart
class HiveDatabaseService implements AsyncInitializable {
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    // open boxes, warm caches, etc.
    _initialized = true;
  }
}
```

Generated app containers can call this automatically through
`initializeGeneratedGraph(scope)` after registration.

Lifecycle boundary guidance:
- Use `initialize()` for app-startup resource work (database open, cache warmup,
  migrations).
- Use ViewModel `onInit()` for per-view presentation initialization.
- Do not move view-argument setup into `AsyncInitializable`; it runs at app
  startup, not when a specific screen binds.

| Hook | Trigger | Called By | Best For |
|---|---|---|---|
| `initialize()` | App startup | Generated startup helper | Async singleton setup |
| `FoundryViewModel.onInit()` | View binds to ViewModel | Flutter MVVM binding | Initial screen load |
| `FoundryViewModel.onDispose()` | ViewModel disposal | Flutter MVVM binding | Cleanup tied to view scope |

---

## `Container`

If you want a simple wrapper around the root scope, `Container` exposes a `globalScope` plus convenience `register`, `resolve`, and `createChild` methods.

```dart
final container = Container();
container.register<ApiClient>((_) => ApiClient());
container.register<HomeViewModel>(
  (scope) => HomeViewModel(scope.resolve<ApiClient>()),
  lifetime: Lifetime.scoped,
);

final apiClient = container.resolve<ApiClient>();
final childScope = container.createChild();
```

For larger apps, working directly with `GlobalScope` and generated registration helpers is usually clearer.

---

## Relationship To Other Packages

- `foundry_annotations`: marker annotations such as `@FoundryViewModel()` and `@FoundryService()`.
- `foundry_generator`: build-time generation of DI graph wiring, route helpers, and helper mixins.
- `foundry_flutter`: `FoundryScope`, `FoundryView`, and state-aware widgets for Flutter UI trees.
- `foundry_navigation_flutter`: typed navigation runtime used by generated `@FoundryView` routes.
