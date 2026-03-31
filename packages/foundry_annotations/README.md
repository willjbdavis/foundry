# foundry_annotations

Compile-time annotations for the [Foundry MVVM framework](../foundry_core). This package contains the marker annotations that `foundry_generator` reads to validate your architecture and generate MVVM boilerplate.

`foundry_annotations` is intentionally small: it does not provide runtime behavior by itself. Instead, it gives you the metadata that powers code generation across `foundry_core`, `foundry_flutter`, and `foundry_navigation_flutter`.

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
- [`@FoundryViewState`](#foundryviewstate)
- [`@FoundryServiceState`](#foundryservicestate)
- [`@FoundryViewModel`](#foundryviewmodel)
- [`@FoundryService`](#foundryservice)
- [`@FoundryView`](#foundryview)
- [Typical Workflow](#typical-workflow)

---

## Concepts

| Annotation | Use it on | Purpose |
|---|---|---|
| `@FoundryViewState()` | Immutable UI state classes | Generates `copyWith`, value equality, and `toString` helpers. |
| `@FoundryServiceState()` | Immutable service/domain state classes | Same as `@FoundryViewState`, with optional persistence metadata. |
| `@FoundryViewModel()` | Classes extending `FoundryViewModel<T>` | Enables validation and generates helper methods like `safeAsync`. |
| `@FoundryService()` | Stateless services or `StatefulService<T>` classes | Marks DI-managed domain services and validates dependencies. |
| `@FoundryView()` | Flutter view widgets | Generates typed route helpers and deep-link wiring metadata. |

---

## Setup

Add the annotations package to your dependencies, then pair it with `foundry_generator` and `build_runner` so the annotations actually produce code:

```yaml
dependencies:
  foundry_annotations: ^1.0.0

dev_dependencies:
  foundry_generator: ^0.0.1
  build_runner: ^2.4.13
```

Every annotated file that generates code should declare its generated part file:

```dart
part 'home_state.g.dart';
```

---

## `@FoundryViewState`

Use `@FoundryViewState()` for immutable state consumed by a ViewModel and rendered by a view.

```dart
import 'package:foundry_annotations/foundry_annotations.dart';

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

The generated mixin supplies the tedious value-type behavior so your ViewModel can emit fresh immutable states without hand-writing `copyWith`, `==`, or `hashCode`.

---

## `@FoundryServiceState`

Use `@FoundryServiceState()` for immutable state owned by a `@FoundryService(stateful: true)` service. The optional `persistent` flag lets the generator expose whether the service state should be treated as persistent.

```dart
import 'package:foundry_annotations/foundry_annotations.dart';

part 'cart_state.g.dart';

@FoundryServiceState(persistent: true)
class CartState with _$CartStateMixin {
  final List<String> itemIds;

  const CartState({this.itemIds = const []});
}
```

---

## `@FoundryViewModel`

Annotate classes that extend `FoundryViewModel<TState>`. The generator validates the type hierarchy and emits helper methods for common state/error handling patterns.

```dart
import 'package:foundry_annotations/foundry_annotations.dart';
import 'package:foundry_core/foundry_core.dart';

part 'home_view_model.g.dart';

@FoundryViewModel()
class HomeViewModel extends FoundryViewModel<HomeState>
    with _$HomeViewModelHelpers {
  final ItemRepository _repo;

  HomeViewModel(this._repo) {
    emitNewState(const HomeState(isLoading: true));
  }

  @override
  Future<void> onInit() async {
    await safeAsync(() async {
      final items = await _repo.fetchAll();
      emitNewState(HomeState(items: items));
    });
  }
}
```

### Parameters

| Parameter | Type | Default | Purpose |
|---|---|---|---|
| `lifetime` | `String` | `'scoped'` | DI registration lifetime used by the generated graph. Accepts `'singleton'`, `'scoped'`, or `'transient'`. `'scoped'` is the recommended default because ViewModels are typically view-scoped. |
| `name` | `String?` | `null` | Override the identifier used in generated code. Useful when two ViewModels share a class name across different libraries. |

One important architecture rule is enforced at build time: a `@FoundryViewModel` cannot depend directly on another `@FoundryViewModel`. Shared logic belongs in a `@FoundryService` instead.

---

## `@FoundryService`

Annotate services, repositories, and domain services that should participate in Foundry's generated dependency graph.

**Stateful service** — extends `StatefulService<T>` and emits reactive state:

```dart
import 'package:foundry_annotations/foundry_annotations.dart';
import 'package:foundry_core/foundry_core.dart';

part 'cart_service.g.dart';

@FoundryService(stateful: true)
class CartService extends StatefulService<CartState> {
  CartService() {
    emitNewState(const CartState());
  }

  void addItem(String id) {
    emitNewState(state.copyWith(itemIds: [...state.itemIds, id]));
  }
}
```

**Stateless service** — a plain Dart class with no state stream (the default when `stateful` is omitted):

```dart
@FoundryService()
class AnalyticsService {
  void track(String event) { /* ... */ }
}
```

### Parameters

| Parameter | Type | Default | Purpose |
|---|---|---|---|
| `stateful` | `bool` | `false` | Set to `true` when the class extends `StatefulService<T>`. |
| `dependsOn` | `List<Type>?` | `null` | Declares explicit service-to-service dependencies. The generator validates these relationships and can wire them automatically in the generated DI graph. |
| `lifetime` | `String` | `'singleton'` | DI registration lifetime. Accepts `'singleton'`, `'scoped'`, or `'transient'`. Most services should remain `'singleton'`. |
| `name` | `String?` | `null` | Override the identifier used in generated code. |

---

## `@FoundryView`

Use `@FoundryView()` on Flutter widgets to opt into generated route metadata, typed navigation helpers, and optional deep-link handling.

**Simple route with deep-link:**

```dart
import 'package:flutter/widgets.dart';
import 'package:foundry_annotations/foundry_annotations.dart';
import 'package:foundry_flutter/foundry_flutter.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

part 'home_view.g.dart';

@FoundryView(route: '/home', deepLink: '/home')
class HomeView extends FoundryView<HomeViewModel, HomeState> {
  const HomeView({super.key});

  @override
  Widget buildWithState(BuildContext context, HomeState? oldState, HomeState state) {
    return Text('Items: ${state.items.length}');
  }
}
```

**Route with typed arguments and a return result:**

```dart
@FoundryView(route: '/product', args: ProductArgs, result: bool)
class ProductView extends FoundryView<ProductViewModel, ProductState> {
  const ProductView({super.key});
  // ...
}
```

Setting `args` causes the generator to emit a typed push helper that requires a `ProductArgs` value at the call site, replacing untyped `Object?` argument maps. Setting `result` types the return value received after the route is popped.

### Parameters

| Parameter | Type | Default | Purpose |
|---|---|---|---|
| `route` | `String?` | `null` | Internal route path (e.g. `'/home'`). Used for in-app navigation. |
| `args` | `Type?` | `null` | Type of arguments required to navigate to this view. Enables typed push helpers in generated code. |
| `result` | `Type?` | `null` | Type returned when this route is popped. Enables typed pop helpers. |
| `deepLink` | `String?` | `null` | External URI pattern for deep-link matching (e.g. `'/product/:id'`). Supports `:param` path segments and query parameters. |
| `deepLinkArgsFactory` | `Function(Uri)?` | `null` | Custom factory to parse an incoming `Uri` into route arguments. Use this when the generated URI parser for `deepLink` is insufficient for your argument type. |
| `name` | `String?` | `null` | Override the identifier used in generated code. |

The generated output is consumed by `foundry_navigation_flutter` and your app's generated container/deep-link files.

When the annotated view is used with `foundry_flutter`, make sure its ViewModel has an initial state before `onInit()` runs.

---

## Typical Workflow

In a Foundry app, these packages work together in sequence:

1. Add annotations from `foundry_annotations` to your state, service, ViewModel, and view classes.
2. Run `foundry_generator` with `build_runner`.
3. Use the generated helpers and registration graph with `foundry_core`, `foundry_flutter`, and `foundry_navigation_flutter`.

If you want the generated output itself explained in detail, see [`foundry_generator`](../foundry_generator).

## Where To Read Next

- Root README: https://github.com/willjbdavis/foundry/blob/main/README.md
- foundry_core README: https://github.com/willjbdavis/foundry/blob/main/packages/foundry_core/README.md
- foundry_flutter README: https://github.com/willjbdavis/foundry/blob/main/packages/foundry_flutter/README.md
- foundry_generator README: https://github.com/willjbdavis/foundry/blob/main/packages/foundry_generator/README.md
- foundry_navigation_flutter README: https://github.com/willjbdavis/foundry/blob/main/packages/foundry_navigation_flutter/README.md
