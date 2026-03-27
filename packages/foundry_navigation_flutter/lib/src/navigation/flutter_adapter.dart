import 'package:flutter/widgets.dart';

import 'adapter.dart';
import 'route_config.dart';

/// Navigator adapter implementation for Flutter's Navigator API.
class FlutterNavigatorAdapter implements NavigatorAdapter {
  /// Creates an adapter backed by callbacks that resolve navigator/context.
  FlutterNavigatorAdapter({
    required NavigatorState Function() navigatorResolver,
    required BuildContext Function() contextResolver,
  }) : _navigatorResolver = navigatorResolver,
       _contextResolver = contextResolver;

  /// Creates an adapter that resolves a navigator from [context].
  factory FlutterNavigatorAdapter.fromContext(final BuildContext context) {
    return FlutterNavigatorAdapter(
      navigatorResolver: () => Navigator.of(context),
      contextResolver: () => context,
    );
  }

  /// Creates an adapter that resolves a navigator from a [GlobalKey].
  ///
  /// Throws [StateError] when the key has no current state/context.
  factory FlutterNavigatorAdapter.fromKey(final GlobalKey<NavigatorState> key) {
    return FlutterNavigatorAdapter(
      navigatorResolver: () {
        final NavigatorState? navigator = key.currentState;
        if (navigator == null) {
          throw StateError('NavigatorState is unavailable for the given key.');
        }
        return navigator;
      },
      contextResolver: () {
        final BuildContext? context = key.currentContext;
        if (context == null) {
          throw StateError(
            'Navigator BuildContext is unavailable for the given key.',
          );
        }
        return context;
      },
    );
  }

  final NavigatorState Function() _navigatorResolver;
  final BuildContext Function() _contextResolver;

  // Per-navigator stack of route result contracts.
  //
  // This allows pop/maybePop to validate values against the top-most pushed
  // route contract for the active navigator instance.
  static final Expando<List<RouteResultContract>> _resultContractsByNavigator =
      Expando<List<RouteResultContract>>('foundry_nav_result_contracts');

  static List<RouteResultContract> _stackForNavigator(
    NavigatorState navigator,
  ) {
    final List<RouteResultContract>? existing =
        _resultContractsByNavigator[navigator];
    if (existing != null) {
      return existing;
    }
    final List<RouteResultContract> created = <RouteResultContract>[];
    _resultContractsByNavigator[navigator] = created;
    return created;
  }

  @override
  Future<T> push<T>(final RouteConfig<T> config) {
    final NavigatorState navigator = _navigatorResolver();
    final BuildContext context = _contextResolver();
    final RouteResultContract contract = config.resultContract;
    _stackForNavigator(navigator).add(contract);
    return navigator.push<T>(config.build(context)).then((T? value) {
      if (!contract.accepts(value)) {
        final String actualType = value == null
            ? 'null'
            : value.runtimeType.toString();
        throw StateError(
          'Invalid navigation completion result for push. '
          'Expected ${contract.debugType} '
          '(${contract.expectsVoid ? 'void' : (contract.isNullable ? 'nullable' : 'non-nullable')}), '
          'but received $actualType.',
        );
      }
      return value as T;
    });
  }

  @override
  void pop([final Object? result]) {
    final NavigatorState navigator = _navigatorResolver();
    final List<RouteResultContract> stack = _stackForNavigator(navigator);
    final RouteResultContract? contract = stack.isNotEmpty ? stack.last : null;
    _validateResult(contract, result, operation: 'pop');
    navigator.pop(result);
    if (contract != null) {
      stack.removeLast();
    }
  }

  @override
  Future<bool> maybePop([final Object? result]) async {
    final NavigatorState navigator = _navigatorResolver();
    final List<RouteResultContract> stack = _stackForNavigator(navigator);
    final RouteResultContract? contract = stack.isNotEmpty ? stack.last : null;
    _validateResult(contract, result, operation: 'maybePop');
    final bool popped = await navigator.maybePop(result);
    if (popped && contract != null) {
      stack.removeLast();
    }
    return popped;
  }

  @override
  bool canPop() {
    return _navigatorResolver().canPop();
  }

  @override
  void popToRoot() {
    final NavigatorState navigator = _navigatorResolver();
    _stackForNavigator(navigator).clear();
    navigator.popUntil((route) => route.isFirst);
  }

  // Validates [result] against [contract], throwing [StateError] on mismatch.
  void _validateResult(
    RouteResultContract? contract,
    Object? result, {
    required String operation,
  }) {
    if (contract == null) {
      return;
    }
    if (!contract.accepts(result)) {
      final String actualType = result == null
          ? 'null'
          : result.runtimeType.toString();
      throw StateError(
        'Invalid navigation result for $operation. '
        'Expected ${contract.debugType} '
        '(${contract.expectsVoid ? 'void' : (contract.isNullable ? 'nullable' : 'non-nullable')}), '
        'but received $actualType.',
      );
    }
  }
}
