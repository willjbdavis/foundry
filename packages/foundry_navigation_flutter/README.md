# foundry_navigation_flutter

Flutter navigation runtime for the Foundry MVVM framework. This package provides the typed route contracts and adapter layer that generated `@FoundryView` navigation helpers target.

If `foundry_generator` gives you `HomeViewRoute` and `GeneratedDeepLinkResolver`, `foundry_navigation_flutter` is the package that makes those generated contracts execute at runtime.

This runtime now enforces a typed result contract at both compile time and runtime:

- route declares output type via `RouteConfig<T>`
- push returns `Future<T>` inferred from the route
- pop accepts `Object?` but validates against the active route contract
- mismatched pop values throw `StateError`

---

## Table of Contents

- [Quick Start](#quick-start)
- [Concepts](#concepts)
- [GO, BEAMER, And Foundry Navigation](#go-beamer-and-foundry-navigation)
- [Typed Results Mechanisms](#typed-results-mechanisms)
- [Setup](#setup)
- [Configure Navigation Once](#configure-navigation-once)
- [Define A Typed Route](#define-a-typed-route)
- [`RouteArgs`](#routeargs)
- [Working With Generated `@FoundryView` Routes](#working-with-generated-foundryview-routes)
- [Deep-Link Resolution](#deep-link-resolution)
- [When To Use What](#when-to-use-what)
- [`FoundryNavigation` — Explicit-Target Navigation](#foundrynavigation--explicit-target-navigation)
- [Result Semantics Reference](#result-semantics-reference)
- [Using Navigation Without ViewModel, Service, Or DI](#using-navigation-without-viewmodel-service-or-di)

---

## Quick Start

### 1. Configure navigation

```dart
import 'package:flutter/material.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  FoundryNavigator.configure(
    FlutterNavigatorAdapter.fromKey(navigatorKey),
  );

  runApp(
    MaterialApp(
      navigatorKey: navigatorKey,
      home: const Placeholder(),
    ),
  );
}
```

### 2. Define a route

```dart
class HelloRoute extends RouteConfig<void> {
  const HelloRoute();

  @override
  Route<void> build(BuildContext context) {
    return MaterialPageRoute<void>(
      builder: (_) => const Text('Hello'),
    );
  }

  @override
  Route<void> buildDeepLink(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const Text('Hello'),
    );
  }
}
```

### 3. Navigate

```dart
await FoundryNavigator.push(const HelloRoute());
```

That's it. You now have typed navigation.

---

## Concepts

### TL;DR

- `RouteConfig<T>` defines the route and its result type.
- `FoundryNavigator` is the simple global entry point for most apps.
- `NavigatorAdapter` decouples navigation from Flutter APIs.
- Generated `@FoundryView` routes plug into this runtime automatically.

### Navigation APIs

- **`FoundryNavigator` (static)**: simple, global entry point for most apps.
- **`FoundryNavigation` (instance)**: advanced explicit-target API for channels, nested navigators, and multi-stack flows.

| Concept | Class | Role |
|---|---|---|
| Navigation abstraction | `NavigatorAdapter` | Small interface for `push`, `pop`, `maybePop`, `canPop`, and `popToRoot`. |
| Flutter adapter | `FlutterNavigatorAdapter` | Bridges the abstraction to Flutter's `Navigator`. |
| Typed route base | `RouteConfig<T>` | Describes route construction and the result contract (`void`, nullable, or non-nullable value). |
| Typed args marker | `RouteArgs` | Base class for strongly typed route argument objects. |
| Static entry point | `FoundryNavigator` | Global API used by generated and hand-written routes. |
| Explicit-target service | `FoundryNavigation` | Instance-based navigation with five explicit target types. |

---

## GO, BEAMER, And Foundry Navigation

Flutter navigation libraries differ less in *what they can do* and more in *what they make central in your app architecture*.

### TL;DR

* Use **GoRouter** when your app is fundamentally URL-driven.
* Use **Beamer** when your app is modeled as nested page stacks.
* Use **Foundry Navigation** when you want navigation to be **type-safe, contract-driven, and aligned with your view layer**.

---

## Comparison

| Package                | Core Model                                 | Strengths                                                                                                               | Limitations                                                                                                             |
| ---------------------- | ------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **GoRouter**           | Declarative route tree                     | Strong URL integration, redirects, web support                                                                          | Navigation becomes string-based and router-centric; weak typing for results; logic often moves into route configuration |
| **Beamer**             | Router-driven page stacks (`BeamLocation`) | Flexible nested flows, explicit page composition                                                                        | Adds router-specific abstraction layer; still largely runtime/string-driven; limited type safety                        |
| **Foundry Navigation** | Typed route contracts (`RouteConfig<T>`)   | Compile-time route contracts, inferred result types, runtime validation, generated helpers, explicit navigation targets | Requires adopting typed routes (and optionally codegen)                                                                 |

---

## What makes Foundry Navigation different

### 1. Navigation is a contract, not a string

```dart
final User user = await FoundryNavigator.push(PickUserRoute(teamId: 'eng'));
```

* No string route names
* No casting
* No guessing return types

The route itself defines:

* inputs
* outputs
* construction

---

### 2. Typed results are first-class

* `push` returns `Future<T>` inferred from the route
* `pop` is validated against the active route contract
* invalid values throw immediately

```dart
FoundryNavigator.pop('yes'); // throws StateError
```

This eliminates an entire class of runtime bugs common in imperative navigation.

---

### 3. Navigation stays out of your architecture

Unlike router-centric approaches:

* you don’t model your app around route trees
* you don’t move logic into router configuration
* you don’t depend on string paths in core logic

Foundry Navigation is a **runtime layer**, not the place where your app is structured.

---

### 4. Generated routes eliminate drift

When used with `@FoundryView`:

* routes are generated from view declarations
* args are strongly typed
* deep links stay in sync
* helpers are always correct

No more:

* mismatched route names
* broken parameter mappings
* stale navigation code

---

### 5. Explicit navigation targets

Foundry Navigation introduces **explicit-target navigation**:

* root navigator
* nearest context
* named channels (feature stacks)
* specific navigator adapters
* last-used target

This makes complex flows (tabs, auth stacks, nested navigators) predictable and explicit instead of implicit.

---

## When Foundry Navigation is the better choice

Choose Foundry Navigation when:

* you want **type safety across navigation**
* you prefer **contracts over strings**
* your app uses (or benefits from) **code generation**
* you need **multi-stack navigation (tabs, auth, flows)**
* you want navigation to integrate cleanly with your **view layer**

---

## Summary

GoRouter and Beamer are excellent when routing itself is the primary abstraction.

Foundry Navigation is designed for a different goal:

> **Make navigation feel like a natural extension of your Dart types and view definitions, not a separate system.**

---

## Typed Results Mechanisms

The typed result model has three layers that work together.

### 1. Compile-time contract on the route

Every route owns its output contract through `RouteConfig<T>`.

- `RouteConfig<void>`: fire-and-forget route
- `RouteConfig<bool?>`: optional decision result
- `RouteConfig<User>`: required value result

### 2. Inferred return types on push

Push methods infer type from the route instance.

```dart
final Future<void> noResult = FoundryNavigator.push(const HomeRoute());
final Future<bool?> confirmed = FoundryNavigator.push(const ConfirmRoute());
final Future<User> selected = FoundryNavigator.push(PickUserRoute(teamId: 'eng'));
```

No explicit generic arguments are required at call sites.

### 3. Runtime validation on pop

`FlutterNavigatorAdapter` tracks pushed route contracts and validates each
`pop(result)` / `maybePop(result)` value against the top-most contract.

Examples:

- route expects `bool?`, `pop(true)` is valid
- route expects `bool?`, `pop('yes')` throws `StateError`
- route expects `User`, `pop(null)` throws `StateError`
- route expects `void`, `pop(anyNonNull)` throws `StateError`

This protects against accidental type drift in large imperative flows.

### Example: runtime validation

```dart
// Route expects bool
final bool result = await FoundryNavigator.push(const ConfirmRoute());

// Somewhere else:
FoundryNavigator.pop('yes'); // throws StateError
```

This makes the result contract concrete at runtime, not just at the call site.

---

## Setup

```yaml
dependencies:
  foundry_navigation_flutter: ^0.0.1
```

This package is usually used alongside `foundry_flutter` and `foundry_generator`.

---

## Configure Navigation Once

The most common setup is to create a `GlobalKey<NavigatorState>`, build a `FlutterNavigatorAdapter` from it, and register that adapter with `FoundryNavigator` during app startup.

```dart
import 'package:flutter/material.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  FoundryNavigator.configure(
    FlutterNavigatorAdapter.fromKey(navigatorKey),
  );

  runApp(
    MaterialApp(
      navigatorKey: navigatorKey,
      home: const Placeholder(),
    ),
  );
}
```

After that, you can call `FoundryNavigator.push(...)` without passing a `BuildContext` every time.

---

## Define A Typed Route

You can write routes manually by extending `RouteConfig<T>`.

```dart
import 'package:flutter/material.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

class DetailRoute extends RouteConfig<void> {
  const DetailRoute(this.id);

  final int id;

  @override
  String get name => '/detail';

  @override
  Route<void> build(BuildContext context) {
    return MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Detail')),
        body: Center(child: Text('Detail: $id')),
      ),
    );
  }

  @override
  Route<void> buildDeepLink(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Detail')),
        body: Center(child: Text('Detail: $id')),
      ),
    );
  }
}

Future<void> openDetail() async {
  await FoundryNavigator.push(const DetailRoute(42));
}
```

Because `RouteConfig<T>` is generic, the route result type stays explicit all the way through push/pop operations.

### Example with a typed result

```dart
class ConfirmDeleteRoute extends RouteConfig<bool?> {
  const ConfirmDeleteRoute();

  @override
  Route<bool?> build(BuildContext context) {
    return MaterialPageRoute<bool?>(
      builder: (_) => const ConfirmDeleteDialog(),
    );
  }

  @override
  Route<bool?> buildDeepLink(RouteSettings settings) {
    return MaterialPageRoute<bool?>(
      settings: settings,
      builder: (_) => const ConfirmDeleteDialog(),
    );
  }
}

Future<void> maybeDelete() async {
  final bool? confirmed = await FoundryNavigator.push(const ConfirmDeleteRoute());
  if (confirmed == true) {
    // perform deletion
  }
}
```

---

## `RouteArgs`

`RouteArgs` is a marker base class for strongly typed argument objects, especially when pairing this package with generated `@FoundryView(args: ...)` route helpers.

```dart
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

class ProfileArgs extends RouteArgs {
  const ProfileArgs({required this.userId});

  final String userId;
}
```

Generated routes can then carry a single typed argument object instead of a loose map or positional list.

---

## Working With Generated `@FoundryView` Routes

This package is designed to be the runtime target for `foundry_generator`.

```dart
@FoundryView(route: '/home')
class HomeView extends FoundryView<HomeViewModel, HomeState> {
  const HomeView({super.key});

  @override
  Widget buildWithState(BuildContext context, HomeState? oldState, HomeState state) {
    return const SizedBox.shrink();
  }
}
```

With generation enabled, Foundry can emit code such as:

- `HomeViewRoute extends RouteConfig<void>`
- `HomeViewRoute.matchDeepLink(Uri)`
- app-level `GeneratedDeepLinkResolver` (in `lib/app_deep_links.g.dart`)

If you declare a result type in `@FoundryView`, generated routes and helpers become
typed automatically:

```dart
typedef PickUserResult = User?;

@FoundryView(
  route: '/users/pick',
  args: PickUserArgs,
  result: PickUserResult,
)
class PickUserView extends FoundryView<PickUserViewModel, PickUserState> {
  const PickUserView({required this.args, super.key});
  final PickUserArgs args;
}

// generated:
// class PickUserViewRoute extends RouteConfig<User?>
```

That keeps your view declarations close to navigation metadata while leaving the runtime navigation implementation here.

---

## Deep-Link Resolution

Deep-link handling is active only after you wire the generated resolver into your app router.

### TL;DR

- Deep links are compiled into a deterministic matcher tree.
- Matching is fast and predictable.
- Invalid matches return `null`.
- A fallback path can be configured once globally.

### Required app wiring

1. Generate `lib/app_deep_links.g.dart` by running build_runner.
2. Use `GeneratedDeepLinkResolver.resolve` as the router function in `MaterialApp.onGenerateRoute`.
3. Keep an `onUnknownRoute` handler for unresolved routes (recommended).

```dart
import 'package:flutter/material.dart';
import 'package:foundry_core/foundry_core.dart';
import 'app_deep_links.g.dart';

void main() {
  Foundry.configureDeepLinkFallbackPath('/home'); // optional

  runApp(
    MaterialApp(
      onGenerateRoute: GeneratedDeepLinkResolver.resolve,
      onUnknownRoute: (settings) => MaterialPageRoute<void>(
        builder: (_) => const NotFoundView(),
      ),
    ),
  );
}
```

Without this `onGenerateRoute` assignment, deep-link metadata is generated but never executed.

### End-to-end resolver flow

```mermaid
flowchart TD
  A[Incoming RouteSettings.name] --> B[GeneratedDeepLinkResolver.resolve]
  B --> C[Parse to Uri]
  C --> D[Tree traversal match]
  D -->|match| E[Run matched Route.matchDeepLink(uri)]
  E -->|route config| F[Build MaterialPageRoute]
  F --> G[Navigator push result]
  D -->|no match| H{Fallback configured?}
  H -->|yes| I[Retry once with fallback path]
  I --> D
  H -->|no| J[return null]
  J --> K[onUnknownRoute or Flutter fallback]
```

### How the tree works

- The generator inserts each deep-link pattern into a segment tree.
- Each node can have:
  - literal children (for static segments like `exercises`)
  - one variable child (for dynamic segments like `:exerciseId`)
  - an optional terminal matcher index
- Match order per segment is deterministic:
  - literal child first
  - variable child second
- A URI matches only when traversal consumes all path segments and lands on a terminal node.

This structure avoids linear scanning of all routes and makes behavior stable as route count grows.

### Conflict detection

During code generation, deep-link patterns are validated for canonical collisions. Ambiguous patterns with the same segment shape (for example, two routes that both normalize to `/users/:param`) fail generation with a hard error.

### Fallback policy

- Fallback is optional.
- Configure once using `Foundry.configureDeepLinkFallbackPath('/some/path')`.
- On miss, resolver logs an error and tries fallback once.
- If fallback is absent, empty, same-path, or also misses, resolver returns `null`.
- Returning `null` allows your `onUnknownRoute` policy to handle the request.

### Tree diagnostics

Use `GeneratedDeepLinkResolver.debugDescribeTree()` to print the generated matcher tree while debugging route shape issues.

### `buildDeepLink` contract

The resolver calls `buildDeepLink(RouteSettings)` instead of `build(BuildContext)` because no `BuildContext` is available during `MaterialApp.onGenerateRoute`.

> In most cases, `buildDeepLink` is identical to `build`, except that you must forward `settings` to `MaterialPageRoute`.

Every `RouteConfig` subclass must implement `buildDeepLink`. For `@FoundryView` routes, the generator emits this implementation automatically. For manually written routes, implement it by forwarding `settings` to `MaterialPageRoute`:

```dart
@override
Route<void> buildDeepLink(RouteSettings settings) {
  return MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => DetailScreen(id: id),
  );
}
```

The `settings` parameter must be forwarded so that `RouteSettings.name` is preserved through the navigation stack.

If a route is never entered via deep link, provide a throwing stub:

```dart
@override
Route<void> buildDeepLink(RouteSettings settings) =>
    throw UnsupportedError('${runtimeType} does not support deep-link entry.');
```

The resolver wraps every `buildDeepLink` call in a `try/catch` and logs errors, so a throw results in a graceful miss rather than a crash.

### Per-view args resolution

Per-view generated deep-link helpers still follow a deterministic match-and-build flow.

### Naming alignment example

For automatic args mapping, constructor parameter names should align with deep-link placeholder names and query parameter keys.

Lookup precedence rule: for every args constructor parameter, generated code checks a path parameter with the same name first, then checks a query parameter with the same name.

```dart
class ExerciseEditorArgs extends RouteArgs {
  const ExerciseEditorArgs({
    this.exerciseId,
    this.returnToWorkoutDraftId,
    this.selectAfterSave = false,
  });

  final String? exerciseId;
  final String? returnToWorkoutDraftId;
  final bool selectAfterSave;
}

@FoundryView(
  route: '/exercises/editor',
  args: ExerciseEditorArgs,
  deepLink: '/exercises/:exerciseId/edit',
)
class ExerciseEditorView
    extends FoundryView<ExerciseEditorViewModel, ExerciseEditorState> {
  const ExerciseEditorView({required this.args, super.key});
  final ExerciseEditorArgs args;
}
```

For this example:

- `exerciseId` resolves from the `:exerciseId` path segment first; query is only used if no path value exists for that name.
- `returnToWorkoutDraftId` has no path placeholder in this pattern, so it falls through to query parameters (for example `?returnToWorkoutDraftId=abc`).
- `selectAfterSave` also has no path placeholder, so it falls through to query parameters, is parsed as bool (`true`/`false`), and otherwise falls back to its constructor default (`false`).

If a required non-nullable parameter has no value, or parsing fails, `matchDeepLink(Uri)` returns `null`.

### Step 1: URI path matching

- Deep-link matching compares path segments from the declared pattern and the incoming URI.
- Segment count must be identical.
- Literal segments must match exactly.
- Parameter segments (`:name`) capture into a params map.

If any check fails, the generated `matchDeepLink(Uri)` returns `null`.

### Step 2: Args creation strategy

When a deep link matches, generated code determines route args in this order:

1. No args type declared:
  returns `const SomeRoute()`.
2. `deepLinkArgsFactory` declared:
  calls the factory with the full `Uri`; result must be of the declared args type, or matching fails.
3. No factory, args type declared:
  generated code auto-maps constructor parameters from captured params and query parameters.

### Step 3: Parameter value resolution

For each args constructor parameter:

- Value source order is always path params first, then query params.
- If missing:
  - use constructor default if present,
  - else use `null` for nullable parameters,
  - else fail match (`null`) for required parameters.

Supported auto-coercions:

- `String`: passthrough
- `int`: `int.tryParse`
- `double`: `double.tryParse`
- `bool`: only `"true"` and `"false"`
- `DateTime`: `DateTime.tryParse`

Unsupported types, invalid parses, or invalid bool text fail matching and return `null`.

### Step 4: Typed route return

If all parameters resolve, generated code constructs the args object and returns the typed route (`SomeViewRoute(args)`).

Practical implication: deep-link matching is strict and safe-by-default. Invalid values are treated as non-matches instead of partially-populated routes.

---

## When To Use What

| Need | Use |
|---|---|
| Decouple navigation from Flutter APIs in domain code | `NavigatorAdapter` |
| Hook Foundry navigation into a Flutter app | `FlutterNavigatorAdapter` |
| Hand-write a typed route | `RouteConfig<T>` |
| Trigger navigation from anywhere after startup configuration | `FoundryNavigator.configure(...)` + `FoundryNavigator.push(...)` |

For deep-link generation and route helper generation, see [`foundry_generator`](../foundry_generator). For view widgets and scope wiring, see [`foundry_flutter`](../foundry_flutter).

---

## `FoundryNavigation` — Explicit-Target Navigation

`FoundryNavigation` is an instance-based navigation service with five explicit target types. Every operation declares exactly where it targets — there is no implicit fallback between target types.

### Target Types

| Target | Push | Pop | canPop | popToRoot |
|---|---|---|---|---|
| **Default** (root navigator) | `pushDefault(route)` | `popDefault([result])` | `canPopDefault()` | `popToRootDefault()` |
| **Context** (nearest navigator) | `pushInContext(ctx, route)` | `popInContext(ctx, [result])` | `canPopInContext(ctx)` | `popToRootInContext(ctx)` |
| **Channel** (named navigator) | `pushInChannel(key, route)` | `popInChannel(key, [result])` | `canPopInChannel(key)` | `popToRootInChannel(key)` |
| **Navigator** (explicit adapter) | `pushInNavigator(adapter, route)` | `popInNavigator(adapter, [result])` | `canPopInNavigator(adapter)` | `popToRootInNavigator(adapter)` |
| **Last** (most recent target) | `pushInLast(route)` | `popInLast([result])` | `canPopInLast()` | `popToRootInLast()` |

### Setup

```dart
final navigatorKey = GlobalKey<NavigatorState>();
final adapter = FlutterNavigatorAdapter.fromKey(navigatorKey);

// Configure both the legacy static API and the new service:
FoundryNavigator.configure(adapter);
FoundryNavigation.configure(
  FoundryNavigation(defaultAdapter: adapter),
);
```

### Typed results with explicit targets

All push target variants preserve route typing:

```dart
final bool? accepted = await FoundryNavigation.instance.pushDefault(
  const ConfirmDeleteRoute(),
);

final User selected = await FoundryNavigation.instance.pushInChannel(
  'selection',
  PickUserRoute(teamId: 'eng'),
);
```

Pop variants are intentionally non-generic and runtime-validated:

```dart
FoundryNavigation.instance.popDefault(true);
FoundryNavigation.instance.popInChannel('selection', selectedUser);
```

If a popped value violates the active route contract, a `StateError` is thrown.

### When To Use Each Target

| Target | When |
|---|---|
| `pushDefault` | Standard page navigation through the root navigator. The most common case. |
| `pushInContext` | Pushing into a nested `Navigator` discovered via `BuildContext`. |
| `pushInChannel` | Routing to a named sub-navigator (tabs, auth/unauth stacks, onboarding flows). |
| `pushInNavigator` | You already have a specific `NavigatorAdapter` instance to target. |
| `pushInLast` | Ergonomic chained flows — push into whichever target was used most recently. |

### Channels

Channels let you register named sub-navigators and route to them by key.

```dart
final nav = FoundryNavigation.instance;

// Register a channel backed by a nested Navigator widget:
nav.registerChannel('auth', FlutterNavigatorAdapter.fromKey(authNavKey));

// Push into the channel:
await nav.pushInChannel('auth', const LoginRoute());
await nav.pushInChannel('auth', const VerifyRoute());

// Pop to root of the channel:
nav.popToRootInChannel('auth');

// Cleanup when the channel is no longer needed:
nav.unregisterChannel('auth');
```

Why channels are powerful:

- They isolate navigation stacks by feature boundary.
- They let one part of the app reset or advance its own flow without disturbing others.
- They avoid "global navigator soup" in apps with nested navigators.

#### Auth flow example

Use a dedicated `auth` channel for login/signup/recovery screens so auth can be reset independently after success or logout.

```dart
final nav = FoundryNavigation.instance;

// During app shell setup:
nav.registerChannel('auth', FlutterNavigatorAdapter.fromKey(authNavKey));

// Enter auth flow:
await nav.pushInChannel('auth', const LoginRoute());
await nav.pushInChannel('auth', const VerifyOtpRoute());

// If user taps "Forgot password", still inside auth stack:
await nav.pushInChannel('auth', const ResetPasswordRoute());

// On successful sign-in, clear auth stack without touching main app stack:
nav.popToRootInChannel('auth');
```

This is useful when your root navigator hosts the app shell, while auth is a nested navigator that can be fully rewound at once.

#### Tab flow example (independent stacks per tab)

Use one channel per tab so each tab preserves its own back stack.

```dart
final nav = FoundryNavigation.instance;

// Register channel adapters for nested Navigators in each tab.
nav.registerChannel('tab-home', FlutterNavigatorAdapter.fromKey(homeTabNavKey));
nav.registerChannel('tab-search', FlutterNavigatorAdapter.fromKey(searchTabNavKey));
nav.registerChannel('tab-profile', FlutterNavigatorAdapter.fromKey(profileTabNavKey));

// Push details inside Search tab only.
await nav.pushInChannel('tab-search', SearchResultsRoute(query: 'bench'));
await nav.pushInChannel('tab-search', ExerciseDetailRoute(id: 'bench-press'));

// User switches tabs: Search stack remains intact.
// Later, from Home tab, trigger profile settings in Profile tab:
await nav.pushInChannel('tab-profile', const ProfileSettingsRoute());
```

Each tab keeps history independently, so back navigation in one tab does not unwind another tab's routes.

### Last Target

Every push and pop operation records the target it used. `*InLast` methods replay into that same target without the caller needing to know which type it was.

- Throws `StateError` if no prior target exists (no implicit fallback).
- `canPopInLast()` returns `false` instead of throwing when there is no prior target.
- `hasLastTarget` and `clearLastTarget()` are available for introspection and test lifecycle.
- Unregistering a channel clears the last target if that channel was the last target.

`pushInLast(route)` preserves typed result inference from `route`:

```dart
final bool? done = await FoundryNavigation.instance.pushInLast(
  const ConfirmDeleteRoute(),
);
```

### When **Not** To Use `*InLast`

- When the destination is statically known — use the explicit variant instead.
- In code where predictability matters more than brevity (startup, deep-link handling).

---

## Result Semantics Reference

| Route type | Push returns | Allowed pop values |
|---|---|---|
| `RouteConfig<void>` | `Future<void>` | `null` only |
| `RouteConfig<T?>` | `Future<T?>` | `null` or `T` |
| `RouteConfig<T>` | `Future<T>` | `T` only |

### Practical guidance

- Use `void` for standard page transitions where caller does not need a value.
- Use nullable results (`T?`) for cancelable flows (pickers, confirm dialogs).
- Use non-nullable results (`T`) when the flow must produce a value.

When in doubt, model cancel explicitly with nullable result contracts and
handle `null` at the call site.

---

## Using Navigation Without ViewModel, Service, Or DI

You can use this package as a navigation-only layer in a plain Flutter app.
You do not need to adopt `FoundryViewModel`, `@FoundryService`, scopes, or
generated DI registration.

### Option A: Manual routes only (no annotations)

Define routes directly with `RouteConfig<T>` and push them through
`FoundryNavigator`.

```dart
import 'package:flutter/material.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

class SettingsRoute extends RouteConfig<void> {
  const SettingsRoute();

  @override
  String get name => '/settings';

  @override
  Route<void> build(BuildContext context) {
    return MaterialPageRoute<void>(
      builder: (_) => const SettingsScreen(),
    );
  }

  @override
  Route<void> buildDeepLink(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const SettingsScreen(),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Settings')));
  }
}
```

### Option B: Use `@FoundryView` generation only

If you want generated route helpers but still do not want the rest of Foundry,
use only:

- `foundry_annotations` (`@FoundryView`)
- `foundry_generator` + `build_runner` (for generated route helpers)
- `foundry_navigation_flutter` (runtime)

In this mode, simply do not use `@FoundryViewModel`, `@FoundryService`,
`@FoundryServiceState`, or generated DI wiring.

Example view:

```dart
import 'package:flutter/widgets.dart';
import 'package:foundry_annotations/foundry_annotations.dart';

part 'home_view.g.dart';

@FoundryView(route: '/home')
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
```

Then run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Minimal runtime setup

Configure a navigator adapter once, then push routes from anywhere.

```dart
import 'package:flutter/material.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  FoundryNavigator.configure(
    FlutterNavigatorAdapter.fromKey(navigatorKey),
  );

  runApp(MaterialApp(navigatorKey: navigatorKey, home: const Placeholder()));
}
```
