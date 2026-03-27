# Lift Log

Foundry MVVM demo app for logging weightlifting workouts. Built with Flutter, Material 3, and the Foundry framework packages from this workspace.

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

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
