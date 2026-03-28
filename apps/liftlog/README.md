# Lift Log

Foundry MVVM demo app for logging weightlifting workouts. Built with Flutter, Material 3, and the Foundry framework packages from this workspace.

## Table of Contents

- [What Lift Log Is](#what-lift-log-is)
- [What It Demonstrates](#what-it-demonstrates)
- [Value It Adds](#value-it-adds)
- [How It Is Intended To Be Used](#how-it-is-intended-to-be-used)
- [Architecture](#architecture)
- [Navigation Model](#navigation-model)
- [Local Development](#local-development)

## What Lift Log Is

Lift Log is the reference application for this workspace. It demonstrates how
the Foundry packages are used together in a realistic Flutter app with state,
DI, navigation, and persistence.

## What It Demonstrates

- Generated immutable state helpers from `@FoundryViewState`.
- ViewModel lifecycle binding through `FoundryView<TViewModel, TState>`.
- Generated DI graph registration and startup initialization.
- Typed navigation with `FoundryNavigation` and generated `*Route` classes.
- Scoped dependencies for screen-level isolation.
- Hive-backed local persistence.

## Value It Adds

- Gives a concrete, end-to-end implementation of Foundry conventions.
- Provides working examples you can copy into new features.
- Serves as a safety net when refactoring framework APIs and generators.
- Demonstrates how generated code, runtime APIs, and app architecture align.

## How It Is Intended To Be Used

- As a runnable demo to verify framework behavior after changes.
- As a blueprint for project structure and feature organization.
- As a source of canonical usage patterns for annotations and navigation.
- As an integration target for generator and runtime refactors.

## Architecture

- **MVVM** — Views, ViewModels, and ViewState classes generated via `foundry_generator`.
- **Navigation** — `FoundryNavigation` explicit-target service for page pushes/pops. Dialog dismissals use Flutter's `Navigator.of(context).pop()` directly.
- **Persistence** — Hive for local workout and exercise storage.
- **DI** — Foundry `Scope` container with generated graph registration.

## Navigation Model

All page-level navigation uses `FoundryNavigation.instance`:

```dart
// Push a route onto the default (root) navigator:
await FoundryNavigation.instance.pushDefault(const HomeViewRoute());

// Pop back:
FoundryNavigation.instance.popDefault();

// Pop to root (e.g. after completing a workout):
FoundryNavigation.instance.popToRootDefault();
```

See the [foundry_navigation_flutter README](../../packages/foundry_navigation_flutter/README.md) for the full API matrix.

## Local Development

### 1. Install dependencies

From repository root:

```bash
flutter pub get
```

### 2. Generate code

From `apps/liftlog`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Run the app

From `apps/liftlog`:

```bash
flutter run
```

### Example: resolve scope dependencies in a view

```dart
import 'package:flutter/material.dart';
import 'package:foundry_annotations/foundry_annotations.dart' as foundry;
import 'package:foundry_flutter/foundry_flutter.dart';

@foundry.FoundryView(route: '/home', deepLink: '/home')
class HomeView extends FoundryView<HomeViewModel, HomeState> {
  const HomeView({super.key});

  @override
  Widget buildWithState(
    BuildContext context,
    HomeState? oldState,
    HomeState state,
  ) {
    final HomeViewModel viewModel = FoundryScope.of(
      context,
    ).resolve<HomeViewModel>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: viewModel.refreshRecentWorkouts,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
```

For a deeper walkthrough of framework packages and generated outputs, start at
the workspace [README](../../README.md).
