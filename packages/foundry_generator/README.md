# foundry_generator

Compile-time generation and architecture validation for the [Foundry MVVM framework](../foundry_core). Annotate your classes, run `build_runner`, and this package generates the repetitive MVVM wiring while enforcing dependency rules at build time.

`foundry_generator` is the package that turns the lightweight annotations in `foundry_annotations` into real code: immutable-state helpers, ViewModel utility mixins, typed routes, and aggregated registration graphs.

Generated `registerGeneratedGraph()` registrations emit DI lifetimes:
- `@FoundryService` defaults to `Lifetime.singleton`
- `@FoundryViewModel` defaults to `Lifetime.scoped`

Generated `app_container.g.dart` also includes:
- `Future<void> initializeGeneratedGraph(Scope scope)`

`initializeGeneratedGraph` resolves generated singleton services and calls
`initialize()` for instances implementing `AsyncInitializable`.

Dependency ordering is constructor-first:
- constructor parameters that reference other generated `@FoundryService` types are
  treated as dependency edges automatically
- `@FoundryService(dependsOn: [...])` is additive for extra ordering constraints that
  constructor injection cannot express directly
- registration and singleton initialization are emitted in topological order so
  dependencies run before dependents

Part of the Foundry framework - a compile-time MVVM architecture for Flutter.

- [foundry_core](https://pub.dev/packages/foundry_core) - DI, scopes, lifecycles
- [foundry_flutter](https://pub.dev/packages/foundry_flutter) - View + ViewModel binding
- [foundry_navigation_flutter](https://pub.dev/packages/foundry_navigation_flutter) - Typed navigation runtime
- [foundry_annotations](https://pub.dev/packages/foundry_annotations) - Annotations for code generation
- [foundry_generator](https://pub.dev/packages/foundry_generator) - Code generation and validation

👉 See the full framework:
**START HERE**
https://github.com/willjbdavis/foundry
## Table of Contents

- [Concepts](#concepts)
- [Setup](#setup)
- [Required Discovery File: `lib/app_module.dart`](#required-discovery-file-libapp_moduledart)
- [`@FoundryViewState`](#foundryviewstate)
- [`@FoundryServiceState`](#foundryservicestate)
- [`@FoundryViewModel`](#foundryviewmodel)
- [`@FoundryService`](#foundryservice)
- [`@FoundryView`](#foundryview)
- [Aggregated Outputs](#aggregated-outputs)
- [Testing Support](#testing-support)
- [Architecture Enforcement Summary](#architecture-enforcement-summary)

---

## Concepts

| Input | Generated output | Purpose |
|---|---|---|
| `@FoundryViewState()` | `_$ClassMixin` | Adds `copyWith`, equality, `hashCode`, `toString`, and error-field metadata. |
| `@FoundryServiceState()` | `_$ClassMixin` + `$ClassIsPersistent` | Same as `@FoundryViewState`, with persistence metadata. |
| `@FoundryViewModel()` | `_$ClassHelpers` | Adds `safeAsync`, plus `setError` / `clearError` when the state exposes `error`. |
| `@FoundryService()` | Shared-part output used for validation | Validates service shape and emits a registration marker for the aggregate builder. |
| `@FoundryView()` | `ClassRoute`, `BuildContext` push extension, optional `matchDeepLink` | Produces typed navigation helpers. |
| `lib/app_module.dart` | `app_container.g.dart`, `app_deep_links.g.dart` | Aggregates reachable models, ViewModels, and deep-link-enabled views. |

---

## Setup

Add the annotations package to normal dependencies, and put the generator in `dev_dependencies`:

```yaml
dependencies:
  foundry_annotations: ^1.0.0

dev_dependencies:
  foundry_generator: ^0.0.1
  build_runner: ^2.4.13
```

Every annotated library that participates in shared-part generation also needs a `part` directive:

```dart
part 'home_view_model.g.dart';
```

Then run the generator:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Typical startup sequence:

```dart
final scope = GlobalScope.create();
registerGeneratedGraph(scope);
await initializeGeneratedGraph(scope);
```

`registerGeneratedGraph` only registers factories. It does not force singleton
instantiation.

`initializeGeneratedGraph` is the generated startup pass that resolves
singleton services and invokes `initialize()` for `AsyncInitializable`
implementations in dependency-safe order.

For active development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

---

## Required Discovery File: `lib/app_module.dart`

The aggregated outputs are driven from a single source file in your app package: `lib/app_module.dart`.

Create that file and export every library that contains a `@FoundryService`, `@FoundryViewModel`, or `@FoundryView` that should participate in the generated graph:

```dart
library app_module;

export 'features/auth/auth_service.dart';
export 'features/auth/auth_view_model.dart';
export 'features/home/home_view.dart';
export 'features/home/home_view_model.dart';
```

Discovery rules:

- `@FoundryViewState` and `@FoundryServiceState` are discovered file-by-file by the shared-part builders.
- `@FoundryService`, `@FoundryViewModel`, and deep-link-enabled `@FoundryView` classes must be reachable from `lib/app_module.dart`.
- Exports are traversed recursively from `app_module.dart`; barrel files are supported.
- If a file is not exported from `app_module.dart`, it will not appear in aggregated registration or deep-link outputs.

---

## `@FoundryViewState`

`@FoundryViewState()` generates the immutable helper mixin you use on UI state classes.

**Input**

```dart
part 'home_state.g.dart';

@FoundryViewState()
class HomeState with _$HomeStateMixin {
  final bool isLoading;
  final List<String> items;
  final String? error;

  const HomeState({
    this.isLoading = false,
    this.items = const [],
    this.error,
  });
}
```

**Generated shape**

```dart
const _$HomeStateSentinel = Object();
const bool $HomeStateHasErrorField = true;

mixin _$HomeStateMixin on HomeState {
  HomeState copyWith({
    Object? isLoading = _$HomeStateSentinel,
    Object? items = _$HomeStateSentinel,
    Object? error = _$HomeStateSentinel,
  }) {
    return HomeState(
      isLoading: identical(isLoading, _$HomeStateSentinel)
          ? this.isLoading
          : isLoading as bool,
      items: identical(items, _$HomeStateSentinel)
          ? this.items
          : items as List<String>,
      error: identical(error, _$HomeStateSentinel)
          ? this.error
          : error as String?,
    );
  }
}
```

The sentinel-based `copyWith` lets callers explicitly write `error: null` without losing the ability to omit the field entirely.

---

## `@FoundryServiceState`

`@FoundryServiceState()` behaves like `@FoundryViewState()`, but is intended for state owned by a `StatefulService<S>`.

```dart
part 'cart_state.g.dart';

@FoundryServiceState(persistent: true)
class CartState with _$CartStateMixin {
  final List<String> itemIds;

  const CartState({this.itemIds = const []});
}
```

The generator also emits:

```dart
const bool $CartStateIsPersistent = true;
```

---

## `@FoundryViewModel`

`@FoundryViewModel()` validates that the annotated class extends `FoundryViewModel<S>` and generates helper methods.

```dart
part 'home_view_model.g.dart';

@FoundryViewModel()
class HomeViewModel extends FoundryViewModel<HomeState>
    with _$HomeViewModelHelpers {
  final ItemRepository _repo;

  HomeViewModel(this._repo) {
    // Important for foundry_flutter: a current state must already exist
    // before onInit() is called.
    emitNewState(const HomeState());
  }

  @override
  Future<void> onInit() async {
    await safeAsync(() async {
      final items = await _repo.fetchItems();
      emitNewState(state.copyWith(items: items));
    });
  }
}
```

Optional lifetime override:

```dart
@FoundryViewModel(lifetime: 'singleton')
class SessionViewModel extends FoundryViewModel<SessionState> {
  // ...
}
```

Supported values: `singleton`, `scoped`, `transient`.

Generated helpers include:

```dart
mixin _$HomeViewModelHelpers on FoundryViewModel<HomeState> {
  Future<void> safeAsync(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      await invokeOnError(error, stackTrace);
    }
  }

  void setError(String error) {
    emitNewState(state.copyWith(error: error));
  }

  void clearError() {
    emitNewState(state.copyWith(error: null));
  }
}
```

### Build-time rules

- The class must extend `FoundryViewModel<S>`.
- A `@FoundryViewModel` constructor cannot depend on another `@FoundryViewModel`.

---

## `@FoundryService`

`@FoundryService()` validates your domain service and emits a marker that the aggregate container builder can discover.

```dart
part 'auth_model.g.dart';

@FoundryService(stateful: true)
class AuthModel extends StatefulService<AuthState> {
  AuthModel() {
    emitNewState(const AuthState());
  }
}

part 'checkout_model.g.dart';

@FoundryService(dependsOn: [AuthModel])
class CheckoutModel {
  final AuthModel _auth;

  CheckoutModel(this._auth);
}
```

### Build-time rules

- `@FoundryService(stateful: true)` must extend `StatefulService<S>`.
- Every type listed in `dependsOn` must itself be annotated with `@FoundryService()`.
- Constructor-inferred and explicit `dependsOn` edges are merged into one
  dependency graph for ordering and cycle detection.

---

## `@FoundryView`

`@FoundryView()` generates typed route helpers for Flutter views.

```dart
part 'home_view.g.dart';

@FoundryView(route: '/home')
class HomeView extends FoundryView<HomeViewModel, HomeState> {
  const HomeView({super.key});

  @override
  Widget buildWithState(BuildContext context, HomeState? oldState, HomeState state) {
    return Text('Items: ${state.items.length}');
  }
}
```

Generated output includes:

```dart
extension HomeViewGeneratedExt on HomeView {
  static const String generatedRoute = '/home';
  static const String? generatedDeepLink = null;
}

class HomeViewRoute extends RouteConfig<void> {
  const HomeViewRoute();

  @override
  String? get name => '/home';

  @override
  Route<void> build(BuildContext context) {
    return MaterialPageRoute<void>(builder: (_) => const HomeView());
  }
}

extension HomeViewNavigation on BuildContext {
  Future<void> pushHomeView() =>
      FoundryNavigator.push(const HomeViewRoute(), context: this);
}
```

### Deep links

Deep-link metadata is validated during generation:

```dart
@FoundryView(
  route: '/profile',
  deepLink: '/profile/:userId',
  args: ProfileArgs,
)
class ProfileView extends FoundryView<ProfileViewModel, ProfileState> {
  const ProfileView({super.key, required this.args});

  final ProfileArgs args;

  @override
  Widget buildWithState(BuildContext context, ProfileState? oldState, ProfileState state) {
    return const SizedBox.shrink();
  }
}
```

Current behavior:

- Deep-link path parameters are validated at build time.
- A no-args deep link generates a working `matchDeepLink(Uri)` route matcher.
- Args-based deep-link route construction is not fully wired yet in the generated matcher and should be treated as in-progress.

---

## Aggregated Outputs

When you run the builder against `lib/app_module.dart`, Foundry generates application-level helpers.

### `lib/app_container.g.dart`

This file contains `registerGeneratedGraph(Scope)` and `FoundryTestScope`.

```dart
void registerGeneratedGraph(Scope scope) {
  scope.register<AuthModel>((_) => AuthModel());
  scope.register<CheckoutModel>((s) => CheckoutModel(s.resolve<AuthModel>()));
  scope.register<HomeViewModel>((s) => HomeViewModel(s.resolve<ItemRepository>()));
}

abstract final class FoundryTestScope {
  static Scope create({
    Map<Type, Object Function(Scope)> overrides = const {},
  }) {
    // generated implementation
  }
}
```

### `lib/app_deep_links.g.dart`

If `app_module.dart` exposes views with `deepLink:` metadata, the deep-link builder generates `app_deep_links.g.dart` with `GeneratedDeepLinkResolver`, including matcher-tree traversal and overlap validation.

---

## Testing Support

Use `FoundryTestScope.create(...)` when you want a generated registration graph plus selective overrides:

```dart
final scope = FoundryTestScope.create(overrides: {
  AuthModel: (_) => FakeAuthModel(),
});

final viewModel = scope.resolve<HomeViewModel>();
```

If you want more explicit setup, you can also create a `GlobalScope` or child `Scope` manually and register only the dependencies you need.

---

## Architecture Enforcement Summary

| Rule | Result |
|---|---|
| `@FoundryViewModel` must extend `FoundryViewModel<S>` | Build error |
| `@FoundryViewModel` cannot depend on another `@FoundryViewModel` | Build error |
| `@FoundryService(stateful: true)` must extend `StatefulService<S>` | Build error |
| `dependsOn` entries must be `@FoundryService` types | Build error |
| Circular constructor/dependency graph (merged) | Build error |
| `@FoundryView(deepLink:)` with path params but no args/factory | Build error |
| Circular explicit-only `dependsOn` graph | Build error |

For the runtime pieces these generated files plug into, see [`foundry_core`](../foundry_core), [`foundry_flutter`](../foundry_flutter), and [`foundry_navigation_flutter`](../foundry_navigation_flutter).

## Where To Read Next

- Root README: https://github.com/willjbdavis/foundry/blob/main/README.md
- foundry_annotations README: https://github.com/willjbdavis/foundry/blob/main/packages/foundry_annotations/README.md
- foundry_core README: https://github.com/willjbdavis/foundry/blob/main/packages/foundry_core/README.md
- foundry_flutter README: https://github.com/willjbdavis/foundry/blob/main/packages/foundry_flutter/README.md
- foundry_navigation_flutter README: https://github.com/willjbdavis/foundry/blob/main/packages/foundry_navigation_flutter/README.md
