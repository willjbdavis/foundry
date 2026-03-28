# Foundry

Foundry is a compile-time MVVM stack for Flutter. It combines immutable state, architecture validation, generated dependency wiring, Flutter view binding, and typed navigation into a small set of packages that work together.

## Project Docs

- Contribution guide: [CONTRIBUTING.md](CONTRIBUTING.md)
- License: [LICENSE](LICENSE)

This repository is a workspace containing the full stack:

| Package | Role |
|---|---|
| `foundry_annotations` | Marker annotations such as `@FoundryViewState`, `@FoundryViewModel`, `@FoundryService`, and `@FoundryView`. |
| `foundry_core` | Runtime primitives: `FoundryViewModel`, `StatefulService`, `Scope`, `GlobalScope`, and DI. |
| `foundry_flutter` | Flutter integration: `FoundryScope`, `FoundryView`, `FoundryBuilder`, `FoundryListener`, and `FoundrySelectorBuilder`. |
| `foundry_navigation_flutter` | Typed route contracts, runtime result validation, and `FoundryNavigator`/`FoundryNavigation` APIs. |
| `foundry_generator` | Code generation and architecture enforcement driven by your annotations. |

---

## What Foundry Gives You

- Compile-time validation for MVVM boundaries.
- Generated immutable-state helpers.
- Generated DI registration graph with constructor-first dependency ordering.
- Generated async startup initialization in dependency-safe order.
- Flutter-first ViewModel and widget lifecycle wiring.
- Scoped dependency injection with child-scope overrides.
- Explicit DI lifetimes (`singleton`, `scoped`, `transient`).
- Typed route generation from `@FoundryView` declarations.

---

## Exact New-App Walkthrough

The walkthrough below is written for this repository exactly as it exists today. It assumes you are creating a new Flutter app inside the workspace under `apps/` so you can depend on the local packages by path.

If you later publish these packages, you can replace the `path:` dependencies with hosted version constraints.

### 1. Create a new app

From the repository root:

```bash
flutter create apps/hello_foundry
```

That gives you a new app at `apps/hello_foundry`.

### 2. Configure dependencies

Replace the app's dependency section with the Foundry packages from this workspace:

```yaml
dependencies:
  flutter:
    sdk: flutter
  foundry_annotations:
    path: ../../packages/foundry_annotations
  foundry_flutter:
    path: ../../packages/foundry_flutter
  foundry_navigation_flutter:
    path: ../../packages/foundry_navigation_flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.4.13
  foundry_generator:
    path: ../../packages/foundry_generator
```

Why `foundry_navigation_flutter` is included even in a simple example: the code generated for `@FoundryView` references `RouteConfig` and `FoundryNavigator`, so the view library should import that package.

### 3. Create the feature files

Your app's `lib/` folder should end up looking like this:

```text
lib/
  app_module.dart
  app_container.g.dart        # generated
  main.dart
  features/
    home/
      greeting_repository.dart
      greeting_repository.g.dart   # generated
      home_state.dart
      home_state.g.dart            # generated
      home_view.dart
      home_view.g.dart             # generated
      home_view_model.dart
      home_view_model.g.dart       # generated
```

#### `lib/features/home/home_state.dart`

```dart
import 'package:foundry_annotations/foundry_annotations.dart';

part 'home_state.g.dart';

@FoundryViewState()
class HomeState with _$HomeStateMixin {
  final bool isLoading;
  final String message;
  final String? error;

  const HomeState({
    this.isLoading = false,
    this.message = '',
    this.error,
  });
}
```

#### `lib/features/home/greeting_repository.dart`

```dart
import 'package:foundry_annotations/foundry_annotations.dart';

part 'greeting_repository.g.dart';

@FoundryService()
class GreetingRepository {
  Future<String> loadGreeting() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return 'Hello from Foundry';
  }
}
```

The `@FoundryService()` annotation registers `GreetingRepository` in the generated graph. Because `HomeViewModel` takes it as a constructor parameter, the generator infers the dependency edge and emits `GreetingRepository` **before** `HomeViewModel` in the registration output — no manual ordering needed.

If you need to declare an ordering constraint that is not expressible through constructor injection (for example, two models that communicate via subscriptions), use `dependsOn`:

```dart
@FoundryService(stateful: true, dependsOn: [GreetingRepository])
class SomeOtherModel extends StatefulService<SomeState> {
  final GreetingRepository _repo;
  SomeOtherModel(this._repo) { ... }
}
```

`dependsOn` is additive — constructor dependencies are always inferred first.

#### `lib/features/home/home_view_model.dart`

```dart
import 'package:foundry_annotations/foundry_annotations.dart';
import 'package:foundry_core/foundry_core.dart';

import 'greeting_repository.dart';
import 'home_state.dart';

part 'home_view_model.g.dart';

@FoundryViewModel()
class HomeViewModel extends FoundryViewModel<HomeState>
    with _$HomeViewModelHelpers {
  final GreetingRepository _repository;

  HomeViewModel(this._repository) {
    // FoundryView reads the current state before onInit() is invoked.
    emitNewState(const HomeState(isLoading: true));
  }

  @override
  Future<void> onInit() async {
    await loadGreeting();
  }

  Future<void> loadGreeting() async {
    emitNewState(state.copyWith(isLoading: true, error: null));

    try {
      final message = await _repository.loadGreeting();
      emitNewState(
        state.copyWith(
          isLoading: false,
          message: message,
          error: null,
        ),
      );
    } catch (error, stackTrace) {
      await invokeOnError(error, stackTrace);
      emitNewState(
        state.copyWith(
          isLoading: false,
          error: error.toString(),
        ),
      );
    }
  }
}
```

#### `lib/features/home/home_view.dart`

```dart
import 'package:flutter/material.dart';
import 'package:foundry_annotations/foundry_annotations.dart';
import 'package:foundry_flutter/foundry_flutter.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

import 'home_state.dart';
import 'home_view_model.dart';

part 'home_view.g.dart';

@FoundryView(route: '/home')
class HomeView extends FoundryView<HomeViewModel, HomeState> {
  const HomeView({super.key});

  @override
  Widget buildWithState(
    BuildContext context,
    HomeState? oldState,
    HomeState state,
  ) {
    return Scaffold(
      appBar: AppBar(title: const Text('Foundry Demo')),
      body: Center(
        child: switch ((state.isLoading, state.error)) {
          (true, _) => const CircularProgressIndicator(),
          (false, final String error?) => Text('Error: $error'),
          _ => Text(
              state.message,
              textAlign: TextAlign.center,
            ),
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: viewModel.loadGreeting,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
```

#### `lib/app_module.dart`

This file is mandatory for the aggregated generator outputs.

```dart
library app_module;

export 'features/home/greeting_repository.dart';
export 'features/home/home_view.dart';
export 'features/home/home_view_model.dart';
```

#### `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:foundry_core/foundry_core.dart';
import 'package:foundry_flutter/foundry_flutter.dart';

import 'app_container.g.dart';
import 'features/home/home_view.dart';

void main() async {
  // Ensure Flutter bindings are ready before any async work.
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Create the root scope.
  final scope = GlobalScope.create();

  // 2. Register all generated factories (nothing is instantiated yet).
  registerGeneratedGraph(scope);

  // 3. Resolve and initialize singleton services in dependency order.
  //    Any @FoundryService class that implements AsyncInitializable will have
  //    initialize() called here before the UI mounts.
  await initializeGeneratedGraph(scope);

  runApp(MyApp(scope: scope));
}

class MyApp extends StatelessWidget {
  const MyApp({required this.scope, super.key});

  final Scope scope;

  @override
  Widget build(BuildContext context) {
    return FoundryScope(
      scope: scope,
      child: MaterialApp(
        title: 'Foundry Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        ),
        home: const HomeView(),
      ),
    );
  }
}
```

`registerGeneratedGraph` only registers factories — nothing is instantiated until first use. `initializeGeneratedGraph` resolves each singleton model and calls `initialize()` if it implements `AsyncInitializable`, in topological dependency order. Both functions are generated into `app_container.g.dart`.

### 4. Fetch packages and run generation

From `apps/hello_foundry`:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

You should now have generated files for:

- `home_state.g.dart`
- `greeting_repository.g.dart`
- `home_view_model.g.dart`
- `home_view.g.dart`
- `app_container.g.dart`

### 5. Run the app

```bash
flutter run
```

On launch, Foundry resolves `HomeViewModel` from the root scope, reads its current `HomeState`, calls `onInit()`, and rebuilds the view as new states are emitted.

---

## Important Runtime Detail

When a Flutter `FoundryView` binds to a ViewModel, the framework reads `viewModel.state` before calling `onInit()`.

That means your ViewModel must already have a valid initial state by the time it is resolved from the scope. The simplest pattern is to emit that initial state in the constructor:

```dart
HomeViewModel(this._repository) {
  emitNewState(const HomeState(isLoading: true));
}
```

The same rule applies to any `StateEmitter` you bind directly with `FoundryBuilder`, `FoundryListener`, or `FoundrySelectorBuilder`: it needs an initial state before the widget reads `emitter.state`.

---

## Dependency Declaration

Foundry uses constructor injection as the source of truth for the DI graph.

### Constructor injection (primary)

Declare your dependencies as constructor parameters. The generator reads the constructor signature and emits the correct factory automatically:

```dart
@FoundryViewModel()
class HomeViewModel extends FoundryViewModel<HomeState>
    with _$HomeViewModelHelpers {
  final GreetingRepository _repository; // injected

  HomeViewModel(this._repository) {
    emitNewState(const HomeState());
  }
}
```

The generator also uses constructor parameters to infer dependency ordering between `@FoundryService` registrations, so dependencies are always registered and initialized before their dependents.

### `dependsOn` (additive ordering hints)

When two models communicate via subscriptions rather than direct constructor references, you can declare an explicit ordering constraint:

```dart
@FoundryService(stateful: true, dependsOn: [UserRepository])
class NotificationModel extends StatefulService<NotificationState> {
  final UserRepository _users;

  NotificationModel(this._users) { ... }

  @override
  Future<void> onInit() async {
    _users.subscribe(_onUserChanged);
  }
}
```

`dependsOn` is additive — constructor edges are always inferred first and explicit edges are merged in only when they add new constraints. Circular dependency graphs fail at build time.

### DI lifetimes

| Annotation | Default lifetime | Meaning |
|---|---|---|
| `@FoundryService()` | `singleton` | One shared instance for the app lifetime |
| `@FoundryViewModel()` | `scoped` | One instance per view scope, disposed with the view — see below |

Override when needed:

```dart
@FoundryService(lifetime: 'transient')   // new instance every resolve
@FoundryViewModel(lifetime: 'singleton') // shared across all views
```

Supported values: `singleton`, `scoped`, `transient`.

> **ViewModel scope lifetime detail:** The ViewModel *factory* is registered in the root scope by `registerGeneratedGraph`, making it accessible anywhere in the tree. When a `FoundryView` mounts, the framework creates a per-view child scope, resolves the ViewModel instance into that child scope, and disposes the child scope when the view leaves the widget tree. This means each view gets its own isolated ViewModel instance — the root scope holds the recipe, the child scope holds the instance.

### Async startup initialization

Models that need async resource setup (database open, cache warmup, migrations) implement `AsyncInitializable`:

```dart
import 'package:foundry_core/foundry_core.dart';

@FoundryService()
class DatabaseService implements AsyncInitializable {
  bool _ready = false;

  @override
  Future<void> initialize() async {
    if (_ready) return;
    // open database, register adapters, etc.
    _ready = true;
  }
}
```

The generated `initializeGeneratedGraph(scope)` call in `main()` resolves every singleton model and calls `initialize()` for `AsyncInitializable` types, in topological dependency order. Models that do not implement `AsyncInitializable` are skipped.

---

## How The Pieces Fit Together

1. `@FoundryViewState`, `@FoundryService`, `@FoundryViewModel`, and `@FoundryView` describe your feature.
2. `foundry_generator` reads constructor signatures and annotations, validates architecture rules, and generates helper code.
3. `registerGeneratedGraph(scope)` registers lazy factories for every service and ViewModel in the correct dependency order.
4. `await initializeGeneratedGraph(scope)` resolves singleton services and runs async startup initialization in dependency order before any UI mounts.
5. `FoundryScope` exposes that scope to the widget tree.
6. When a `FoundryView` mounts, the framework creates a per-view child scope. The ViewModel factory (registered in the root scope) is resolved into this child scope, producing an isolated instance. The child scope and its ViewModel are disposed when the view leaves the widget tree. The view rebuilds whenever the ViewModel emits a new state.

---

## Where To Read Next

- [packages/foundry_annotations/README.md](packages/foundry_annotations/README.md)
- [packages/foundry_core/README.md](packages/foundry_core/README.md)
- [packages/foundry_flutter/README.md](packages/foundry_flutter/README.md)
- [packages/foundry_generator/README.md](packages/foundry_generator/README.md)
- [packages/foundry_navigation_flutter/README.md](packages/foundry_navigation_flutter/README.md)