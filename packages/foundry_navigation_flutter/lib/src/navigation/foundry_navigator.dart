import 'package:flutter/widgets.dart';

import 'adapter.dart';
import 'flutter_adapter.dart';
import 'route_config.dart';

/// Canonical static API for typed navigation.
abstract final class FoundryNavigator {
  static NavigatorAdapter? _adapter;

  /// Configures the default [NavigatorAdapter] used by static navigation calls.
  static void configure(final NavigatorAdapter adapter) {
    _adapter = adapter;
  }

  /// Clears configured global adapter state.
  ///
  /// Primarily useful in tests.
  static void reset() {
    _adapter = null;
  }

  /// Pushes [config] and completes with the route result type [T].
  ///
  /// [T] is inferred from [config]. The adapter resolution priority is:
  ///
  /// 1. explicit [adapter]
  /// 2. globally configured adapter via [configure]
  /// 3. adapter created from [context]
  static Future<T> push<T>(
    final RouteConfig<T> config, {
    final BuildContext? context,
    final NavigatorAdapter? adapter,
  }) {
    return _resolveAdapter(context: context, adapter: adapter).push<T>(config);
  }

  /// Pops the current route with an optional [result].
  ///
  /// Result validation is performed by the active [NavigatorAdapter].
  static void pop([
    final Object? result,
    BuildContext? context,
    NavigatorAdapter? adapter,
  ]) {
    _resolveAdapter(context: context, adapter: adapter).pop(result);
  }

  /// Attempts to pop the current route with an optional [result].
  ///
  /// Returns `true` when a route was popped.
  static Future<bool> maybePop([
    final Object? result,
    BuildContext? context,
    NavigatorAdapter? adapter,
  ]) {
    return _resolveAdapter(context: context, adapter: adapter).maybePop(result);
  }

  /// Whether the resolved navigator can pop at least one route.
  static bool canPop({
    final BuildContext? context,
    final NavigatorAdapter? adapter,
  }) {
    return _resolveAdapter(context: context, adapter: adapter).canPop();
  }

  static NavigatorAdapter _resolveAdapter({
    final BuildContext? context,
    final NavigatorAdapter? adapter,
  }) {
    if (adapter != null) {
      return adapter;
    }

    final NavigatorAdapter? configured = _adapter;
    if (configured != null) {
      return configured;
    }

    if (context != null) {
      return FlutterNavigatorAdapter.fromContext(context);
    }

    throw StateError(
      'No NavigatorAdapter configured. Call FoundryNavigator.configure(...) '
      'or pass a BuildContext/adapter per call.',
    );
  }
}
