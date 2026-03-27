# foundry_annotations

Compile-time annotations for the [Foundry MVVM framework](../foundry_core). This package contains the marker annotations that `foundry_generator` reads to validate your architecture and generate MVVM boilerplate.

`foundry_annotations` is intentionally small: it does not provide runtime behavior by itself. Instead, it gives you the metadata that powers code generation across `foundry_core`, `foundry_flutter`, and `foundry_navigation_flutter`.

---

## Concepts

| Annotation | Use it on | Purpose |
|---|---|---|
| `@FoundryViewState()` | Immutable UI state classes | Generates `copyWith`, value equality, and `toString` helpers. |
| `@FoundryModelState()` | Immutable model/domain state classes | Same as `@FoundryViewState`, with optional persistence metadata. |
| `@FoundryViewModel()` | Classes extending `FoundryViewModel<T>` | Enables validation and generates helper methods like `safeAsync`. |
| `@FoundryModel()` | Stateless services or `StatefulModel<T>` classes | Marks DI-managed domain models and validates dependencies. |
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

## `@FoundryModelState`

Use `@FoundryModelState()` for immutable state owned by a `@FoundryModel(stateful: true)` model. The optional `persistent` flag lets the generator expose whether the model state should be treated as persistent.

```dart
import 'package:foundry_annotations/foundry_annotations.dart';

part 'cart_state.g.dart';

@FoundryModelState(persistent: true)
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

One important architecture rule is enforced at build time: a `@FoundryViewModel` cannot depend directly on another `@FoundryViewModel`. Shared logic belongs in a `@FoundryModel` instead.

---

## `@FoundryModel`

Annotate services, repositories, and domain models that should participate in Foundry's generated dependency graph.

```dart
import 'package:foundry_annotations/foundry_annotations.dart';
import 'package:foundry_core/foundry_core.dart';

part 'cart_model.g.dart';

@FoundryModel(stateful: true)
class CartModel extends StatefulModel<CartState> {
  CartModel() {
    emitNewState(const CartState());
  }

  void addItem(String id) {
    emitNewState(state.copyWith(itemIds: [...state.itemIds, id]));
  }
}
```

Use `dependsOn: [...]` when a model has explicit dependencies on other models and you want the generator to validate those relationships.

---

## `@FoundryView`

Use `@FoundryView()` on Flutter widgets to opt into generated route metadata, typed navigation helpers, and optional deep-link handling.

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

The generated output is consumed by `foundry_navigation_flutter` and your app's generated container/deep-link files.

When the annotated view is used with `foundry_flutter`, make sure its ViewModel has an initial state before `onInit()` runs.

---

## Typical Workflow

In a Foundry app, these packages work together in sequence:

1. Add annotations from `foundry_annotations` to your state, model, ViewModel, and view classes.
2. Run `foundry_generator` with `build_runner`.
3. Use the generated helpers and registration graph with `foundry_core`, `foundry_flutter`, and `foundry_navigation_flutter`.

If you want the generated output itself explained in detail, see [`foundry_generator`](../foundry_generator).