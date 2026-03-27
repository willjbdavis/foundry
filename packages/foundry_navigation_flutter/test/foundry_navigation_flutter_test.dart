import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

class _TestRouteConfig extends RouteConfig<void> {
  const _TestRouteConfig(this.child);

  final Widget child;

  @override
  Route<void> build(final BuildContext context) {
    return PageRouteBuilder<void>(
      pageBuilder:
          (
            final BuildContext context,
            final Animation<double> animation,
            final Animation<double> secondaryAnimation,
          ) => child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}

class _IntResultRouteConfig extends RouteConfig<int> {
  const _IntResultRouteConfig(this.child);

  final Widget child;

  @override
  Route<int> build(final BuildContext context) {
    return PageRouteBuilder<int>(
      pageBuilder:
          (
            final BuildContext context,
            final Animation<double> animation,
            final Animation<double> secondaryAnimation,
          ) => child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}

class _NullableIntResultRouteConfig extends RouteConfig<int?> {
  const _NullableIntResultRouteConfig(this.child);

  final Widget child;

  @override
  Route<int?> build(final BuildContext context) {
    return PageRouteBuilder<int?>(
      pageBuilder:
          (
            final BuildContext context,
            final Animation<double> animation,
            final Animation<double> secondaryAnimation,
          ) => child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}

class _FakeAdapter implements NavigatorAdapter {
  Object? pushed;
  Object? popped;
  bool canPopValue = false;
  bool popToRootCalled = false;

  @override
  bool canPop() => canPopValue;

  @override
  Future<bool> maybePop([final Object? result]) async {
    popped = result;
    return true;
  }

  @override
  void pop([final Object? result]) {
    popped = result;
  }

  @override
  Future<T> push<T>(final RouteConfig<T> config) async {
    pushed = config;
    return null as T;
  }

  @override
  void popToRoot() {
    popToRootCalled = true;
  }
}

void main() {
  test('FoundryNavigator delegates to configured adapter', () async {
    final _FakeAdapter adapter = _FakeAdapter();
    FoundryNavigator.configure(adapter);

    const _TestRouteConfig config = _TestRouteConfig(SizedBox.shrink());
    await FoundryNavigator.push<void>(config);

    expect(adapter.pushed, same(config));

    FoundryNavigator.pop('done');
    expect(adapter.popped, 'done');

    FoundryNavigator.reset();
  });

  testWidgets('FlutterNavigatorAdapter pushes route from context', (
    final WidgetTester tester,
  ) async {
    final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          key: key,
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder:
                (
                  final BuildContext context,
                  final Animation<double> animation,
                  final Animation<double> secondaryAnimation,
                ) => const Text('root'),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        ),
      ),
    );

    final FlutterNavigatorAdapter adapter = FlutterNavigatorAdapter.fromKey(
      key,
    );
    final Future<void> pushed = adapter.push<void>(
      const _TestRouteConfig(Text('next')),
    );
    await tester.pumpAndSettle();

    expect(find.text('next'), findsOneWidget);

    adapter.pop();
    await tester.pumpAndSettle();
    await pushed;

    expect(find.text('root'), findsOneWidget);
  });

  test('FoundryNavigator throws when no adapter or context available', () {
    FoundryNavigator.reset();

    expect(() => FoundryNavigator.canPop(), throwsA(isA<StateError>()));
  });

  testWidgets(
    'FlutterNavigatorAdapter rejects non-null result for void route',
    (final WidgetTester tester) async {
      final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Navigator(
            key: key,
            onGenerateRoute: (_) => PageRouteBuilder<void>(
              pageBuilder:
                  (
                    final BuildContext context,
                    final Animation<double> animation,
                    final Animation<double> secondaryAnimation,
                  ) => const Text('root'),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          ),
        ),
      );

      final FlutterNavigatorAdapter adapter = FlutterNavigatorAdapter.fromKey(
        key,
      );
      final Future<void> pushed = adapter.push<void>(
        const _TestRouteConfig(Text('next')),
      );
      await tester.pumpAndSettle();

      expect(() => adapter.pop('bad'), throwsA(isA<StateError>()));
      adapter.pop();
      await tester.pumpAndSettle();
      await pushed;
    },
  );

  testWidgets('FlutterNavigatorAdapter enforces non-nullable typed results', (
    final WidgetTester tester,
  ) async {
    final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          key: key,
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder:
                (
                  final BuildContext context,
                  final Animation<double> animation,
                  final Animation<double> secondaryAnimation,
                ) => const Text('root'),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        ),
      ),
    );

    final FlutterNavigatorAdapter adapter = FlutterNavigatorAdapter.fromKey(
      key,
    );

    final Future<int> pushed = adapter.push<int>(
      const _IntResultRouteConfig(Text('next')),
    );
    await tester.pumpAndSettle();

    expect(() => adapter.pop(), throwsA(isA<StateError>()));
    expect(() => adapter.pop('bad'), throwsA(isA<StateError>()));

    adapter.pop(7);
    await tester.pumpAndSettle();
    expect(await pushed, 7);
  });

  testWidgets('FlutterNavigatorAdapter allows nullable typed results', (
    final WidgetTester tester,
  ) async {
    final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          key: key,
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder:
                (
                  final BuildContext context,
                  final Animation<double> animation,
                  final Animation<double> secondaryAnimation,
                ) => const Text('root'),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        ),
      ),
    );

    final FlutterNavigatorAdapter adapter = FlutterNavigatorAdapter.fromKey(
      key,
    );

    final Future<int?> pushed = adapter.push<int?>(
      const _NullableIntResultRouteConfig(Text('next')),
    );
    await tester.pumpAndSettle();

    adapter.pop();
    await tester.pumpAndSettle();
    expect(await pushed, isNull);
  });
}
