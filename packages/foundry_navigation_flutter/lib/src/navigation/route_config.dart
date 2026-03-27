import 'package:flutter/widgets.dart';

/// Runtime contract used to validate navigation pop result values.
class RouteResultContract {
  const RouteResultContract({
    required this.debugType,
    required this.accepts,
    required this.isNullable,
  });

  final Type debugType;
  final bool Function(Object? value) accepts;
  final bool isNullable;

  /// Whether this route expects no value (`void`).
  bool get expectsVoid => debugType.toString() == 'void';
}

/// Base route contract for typed navigation.
///
/// `T` defines the full output contract of the route:
/// - `void`: no result is expected
/// - nullable value type (for example `bool?`): optional result
/// - non-nullable value type (for example `bool`): required result
///
/// Navigation APIs infer their return type from `RouteConfig<T>`, so callers
/// do not need to pass explicit generic arguments at call sites.
abstract class RouteConfig<T> {
  const RouteConfig();

  /// Optional route name for diagnostics.
  String? get name => null;

  /// Contract describing acceptable pop result values for this route.
  ///
  /// This default implementation uses runtime checks derived from [T] and is
  /// sufficient for most route implementations.
  RouteResultContract get resultContract => RouteResultContract(
    debugType: T,
    accepts: (Object? value) {
      final bool isVoid = T.toString() == 'void';
      if (isVoid) {
        return value == null;
      }
      if (value == null) {
        return null is T;
      }
      return value is T;
    },
    isNullable: null is T,
  );

  /// Builds the concrete Flutter [Route].
  Route<T> build(BuildContext context);
}
