import 'route_config.dart';

/// Abstraction over navigation operations used by Foundry.
///
/// Implementations are expected to preserve the route result contract declared
/// by [RouteConfig.resultContract]. In particular, [pop] and [maybePop] should
/// validate the provided `result` against the top-most pushed route when such
/// metadata is available.
abstract class NavigatorAdapter {
  /// Pushes [config] and completes with the route's declared result type [T].
  ///
  /// The result type is inferred from [config]; callers should not need to
  /// pass generic arguments at call sites.
  Future<T> push<T>(RouteConfig<T> config);

  /// Pops the current route with an optional [result].
  ///
  /// Implementations should throw [StateError] when [result] violates the
  /// active route's expected result contract.
  void pop([Object? result]);

  /// Attempts to pop the current route with an optional [result].
  ///
  /// Returns `true` when a route was popped. Implementations should throw
  /// [StateError] when [result] violates the active route's expected result
  /// contract.
  Future<bool> maybePop([Object? result]);

  /// Whether the underlying navigator can pop at least one route.
  bool canPop();

  /// Pops all routes until only the root route remains.
  void popToRoot();
}
