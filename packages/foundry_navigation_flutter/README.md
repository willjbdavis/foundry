# foundry_navigation_flutter

Flutter navigation runtime for the Foundry MVVM framework. This package provides the typed route contracts and adapter layer that generated `@FoundryView` navigation helpers target.

If `foundry_generator` gives you `HomeViewRoute` and `context.pushHomeView()`, `foundry_navigation_flutter` is the package that makes those generated helpers work at runtime.

This runtime now enforces a typed result contract at both compile time and runtime:

- route declares output type via `RouteConfig<T>`
- push returns `Future<T>` inferred from the route
- pop accepts `Object?` but validates against the active route contract
- mismatched pop values throw `StateError`

---

## Table of Contents

- [Concepts](#concepts)
- [Typed Results Mechanisms](#typed-results-mechanisms)
- [Setup](#setup)
- [Configure Navigation Once](#configure-navigation-once)
- [Define A Typed Route](#define-a-typed-route)
- [Context-Based Navigation](#context-based-navigation)
- [`RouteArgs`](#routeargs)
- [Working With Generated `@FoundryView` Routes](#working-with-generated-foundryview-routes)
- [Deep-Link Args Resolution](#deep-link-args-resolution)
- [When To Use What](#when-to-use-what)
- [`FoundryNavigation` — Explicit-Target Navigation](#foundrynavigation--explicit-target-navigation)
- [Result Semantics Reference](#result-semantics-reference)
- [Using Navigation Without ViewModel, Service, Or DI](#using-navigation-without-viewmodel-service-or-di)

---

## Concepts

| Concept | Class | Role |
|---|---|---|
| Navigation abstraction | `NavigatorAdapter` | Small interface for `push`, `pop`, `maybePop`, `canPop`, and `popToRoot`. |
| Flutter adapter | `FlutterNavigatorAdapter` | Bridges the abstraction to Flutter's `Navigator`. |
| Typed route base | `RouteConfig<T>` | Describes route construction and the result contract (`void`, nullable, or non-nullable value). |
| Typed args marker | `RouteArgs` | Base class for strongly typed route argument objects. |
| Static entry point | `FoundryNavigator` | Global or context-based API used by generated and hand-written routes. |
| Explicit-target service | `FoundryNavigation` | Instance-based navigation with five explicit target types. |

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
}

Future<void> maybeDelete() async {
  final bool? confirmed = await FoundryNavigator.push(const ConfirmDeleteRoute());
  if (confirmed == true) {
    // perform deletion
  }
}
```

---

## Context-Based Navigation

If you do not want to configure a global adapter, `FoundryNavigator` can resolve a `FlutterNavigatorAdapter` from a `BuildContext` on a per-call basis.

```dart
await FoundryNavigator.push(
  const DetailRoute(42),
  context: context,
);

FoundryNavigator.pop('saved', context);
```

This is useful in smaller apps, tests, or places where global configuration is undesirable.

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
- `context.pushHomeView()`
- optional deep-link matching helpers

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
// Future<User?> BuildContext.pushPickUserView(PickUserArgs args)
```

That keeps your view declarations close to navigation metadata while leaving the runtime navigation implementation here.

---

## Deep-Link Args Resolution

Generated deep-link helpers follow a deterministic match-and-build flow.

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
| Trigger navigation locally without global setup | `FoundryNavigator.push(..., context: context)` |

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
