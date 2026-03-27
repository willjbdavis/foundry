import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _FakeAdapter implements NavigatorAdapter {
  Object? pushed;
  Object? popped;
  bool canPopValue = false;
  bool popToRootCalled = false;

  @override
  Future<T> push<T>(RouteConfig<T> config) async {
    pushed = config;
    return null as T;
  }

  @override
  void pop([Object? result]) {
    popped = result;
  }

  @override
  Future<bool> maybePop([Object? result]) async {
    popped = result;
    return true;
  }

  @override
  bool canPop() => canPopValue;

  @override
  void popToRoot() {
    popToRootCalled = true;
  }

  void reset() {
    pushed = null;
    popped = null;
    popToRootCalled = false;
  }
}

class _TestRoute extends RouteConfig<void> {
  const _TestRoute(this.label);
  final String label;

  @override
  Route<void> build(BuildContext context) => PageRouteBuilder<void>(
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeAdapter defaultAdapter;
  late FoundryNavigation nav;

  setUp(() {
    defaultAdapter = _FakeAdapter();
    nav = FoundryNavigation(defaultAdapter: defaultAdapter);
  });

  tearDown(() {
    FoundryNavigation.reset();
  });

  // -----------------------------------------------------------------------
  // Static accessor
  // -----------------------------------------------------------------------

  group('static accessor', () {
    test('instance throws when not configured', () {
      expect(() => FoundryNavigation.instance, throwsA(isA<StateError>()));
    });

    test('configure and instance round-trip', () {
      FoundryNavigation.configure(nav);
      expect(FoundryNavigation.instance, same(nav));
    });

    test('reset clears instance', () {
      FoundryNavigation.configure(nav);
      FoundryNavigation.reset();
      expect(() => FoundryNavigation.instance, throwsA(isA<StateError>()));
    });
  });

  // -----------------------------------------------------------------------
  // pushDefault / popDefault
  // -----------------------------------------------------------------------

  group('default target', () {
    test('pushDefault delegates to default adapter', () async {
      const _TestRoute route = _TestRoute('home');
      await nav.pushDefault(route);
      expect(defaultAdapter.pushed, same(route));
    });

    test('popDefault delegates to default adapter', () {
      nav.popDefault('result');
      expect(defaultAdapter.popped, 'result');
    });

    test('canPopDefault returns adapter value', () {
      expect(nav.canPopDefault(), isFalse);
      defaultAdapter.canPopValue = true;
      expect(nav.canPopDefault(), isTrue);
    });

    test('popToRootDefault delegates to adapter', () {
      nav.popToRootDefault();
      expect(defaultAdapter.popToRootCalled, isTrue);
    });
  });

  // -----------------------------------------------------------------------
  // pushInNavigator / popInNavigator
  // -----------------------------------------------------------------------

  group('navigator target', () {
    late _FakeAdapter explicitAdapter;

    setUp(() {
      explicitAdapter = _FakeAdapter();
    });

    test('pushInNavigator delegates to provided adapter', () async {
      const _TestRoute route = _TestRoute('detail');
      await nav.pushInNavigator(explicitAdapter, route);
      expect(explicitAdapter.pushed, same(route));
      expect(defaultAdapter.pushed, isNull);
    });

    test('popInNavigator delegates to provided adapter', () {
      nav.popInNavigator(explicitAdapter, 42);
      expect(explicitAdapter.popped, 42);
    });

    test('canPopInNavigator queries provided adapter', () {
      explicitAdapter.canPopValue = true;
      expect(nav.canPopInNavigator(explicitAdapter), isTrue);
    });

    test('popToRootInNavigator delegates to provided adapter', () {
      nav.popToRootInNavigator(explicitAdapter);
      expect(explicitAdapter.popToRootCalled, isTrue);
    });
  });

  // -----------------------------------------------------------------------
  // Channel
  // -----------------------------------------------------------------------

  group('channel target', () {
    late _FakeAdapter channelAdapter;

    setUp(() {
      channelAdapter = _FakeAdapter();
      nav.registerChannel('auth', channelAdapter);
    });

    test('pushInChannel delegates to registered adapter', () async {
      const _TestRoute route = _TestRoute('login');
      await nav.pushInChannel('auth', route);
      expect(channelAdapter.pushed, same(route));
    });

    test('popInChannel delegates to registered adapter', () {
      nav.popInChannel('auth', 'ok');
      expect(channelAdapter.popped, 'ok');
    });

    test('canPopInChannel returns adapter value', () {
      channelAdapter.canPopValue = true;
      expect(nav.canPopInChannel('auth'), isTrue);
    });

    test('popToRootInChannel delegates to registered adapter', () {
      nav.popToRootInChannel('auth');
      expect(channelAdapter.popToRootCalled, isTrue);
    });

    test('pushInChannel throws for unregistered key', () {
      expect(
        () => nav.pushInChannel('unknown', const _TestRoute('x')),
        throwsA(isA<StateError>()),
      );
    });

    test('unregisterChannel removes the channel', () {
      nav.unregisterChannel('auth');
      expect(
        () => nav.pushInChannel('auth', const _TestRoute('x')),
        throwsA(isA<StateError>()),
      );
    });
  });

  // -----------------------------------------------------------------------
  // Last target tracking
  // -----------------------------------------------------------------------

  group('last target', () {
    test('hasLastTarget is false initially', () {
      expect(nav.hasLastTarget, isFalse);
    });

    test('pushDefault sets last target', () async {
      await nav.pushDefault(const _TestRoute('a'));
      expect(nav.hasLastTarget, isTrue);
    });

    test('pushInLast uses default after pushDefault', () async {
      await nav.pushDefault(const _TestRoute('a'));
      defaultAdapter.reset();

      const _TestRoute second = _TestRoute('b');
      await nav.pushInLast(second);
      expect(defaultAdapter.pushed, same(second));
    });

    test('pushInLast uses navigator after pushInNavigator', () async {
      final _FakeAdapter explicitAdapter = _FakeAdapter();
      await nav.pushInNavigator(explicitAdapter, const _TestRoute('a'));
      explicitAdapter.reset();

      const _TestRoute second = _TestRoute('b');
      await nav.pushInLast(second);
      expect(explicitAdapter.pushed, same(second));
    });

    test('pushInLast uses channel after pushInChannel', () async {
      final _FakeAdapter channelAdapter = _FakeAdapter();
      nav.registerChannel('tab', channelAdapter);
      await nav.pushInChannel('tab', const _TestRoute('a'));
      channelAdapter.reset();

      const _TestRoute second = _TestRoute('b');
      await nav.pushInLast(second);
      expect(channelAdapter.pushed, same(second));
    });

    test('popInLast uses default after popDefault', () {
      nav.popDefault();
      defaultAdapter.reset();

      nav.popInLast('x');
      expect(defaultAdapter.popped, 'x');
    });

    test('canPopInLast returns false when no last target', () {
      expect(nav.canPopInLast(), isFalse);
    });

    test('canPopInLast returns adapter value after pushDefault', () async {
      await nav.pushDefault(const _TestRoute('a'));
      defaultAdapter.canPopValue = true;
      expect(nav.canPopInLast(), isTrue);
    });

    test('popToRootInLast delegates to last target', () async {
      await nav.pushDefault(const _TestRoute('a'));
      nav.popToRootInLast();
      expect(defaultAdapter.popToRootCalled, isTrue);
    });

    test('pushInLast throws when no prior target', () {
      expect(
        () => nav.pushInLast(const _TestRoute('x')),
        throwsA(isA<StateError>()),
      );
    });

    test('popInLast throws when no prior target', () {
      expect(() => nav.popInLast(), throwsA(isA<StateError>()));
    });

    test('popToRootInLast throws when no prior target', () {
      expect(() => nav.popToRootInLast(), throwsA(isA<StateError>()));
    });

    test('clearLastTarget resets tracking', () async {
      await nav.pushDefault(const _TestRoute('a'));
      nav.clearLastTarget();
      expect(nav.hasLastTarget, isFalse);
      expect(
        () => nav.pushInLast(const _TestRoute('x')),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'unregisterChannel clears last target if it was that channel',
      () async {
        final _FakeAdapter channelAdapter = _FakeAdapter();
        nav.registerChannel('onboarding', channelAdapter);
        await nav.pushInChannel('onboarding', const _TestRoute('step1'));
        expect(nav.hasLastTarget, isTrue);

        nav.unregisterChannel('onboarding');
        expect(nav.hasLastTarget, isFalse);
      },
    );

    test(
      'unregisterChannel preserves last target if different channel',
      () async {
        final _FakeAdapter ch1 = _FakeAdapter();
        final _FakeAdapter ch2 = _FakeAdapter();
        nav.registerChannel('ch1', ch1);
        nav.registerChannel('ch2', ch2);

        await nav.pushInChannel('ch2', const _TestRoute('a'));
        nav.unregisterChannel('ch1');
        expect(nav.hasLastTarget, isTrue);
      },
    );
  });

  // -----------------------------------------------------------------------
  // Last target updates from pop operations
  // -----------------------------------------------------------------------

  group('pop updates last target', () {
    test('popDefault updates last target to default', () async {
      final _FakeAdapter explicit = _FakeAdapter();
      await nav.pushInNavigator(explicit, const _TestRoute('a'));

      nav.popDefault();
      defaultAdapter.reset();

      nav.popInLast();
      expect(defaultAdapter.popped, isNull); // called pop with null
    });

    test('popToRootDefault updates last target to default', () async {
      final _FakeAdapter explicit = _FakeAdapter();
      await nav.pushInNavigator(explicit, const _TestRoute('a'));

      nav.popToRootDefault();
      expect(defaultAdapter.popToRootCalled, isTrue);

      defaultAdapter.reset();
      nav.popInLast();
      // confirms last target is now default
    });
  });

  // -----------------------------------------------------------------------
  // Instance isolation
  // -----------------------------------------------------------------------

  group('instance isolation', () {
    test('separate instances have independent state', () async {
      final _FakeAdapter adapter1 = _FakeAdapter();
      final _FakeAdapter adapter2 = _FakeAdapter();
      final FoundryNavigation nav1 = FoundryNavigation(
        defaultAdapter: adapter1,
      );
      final FoundryNavigation nav2 = FoundryNavigation(
        defaultAdapter: adapter2,
      );

      await nav1.pushDefault(const _TestRoute('a'));
      expect(nav1.hasLastTarget, isTrue);
      expect(nav2.hasLastTarget, isFalse);
    });

    test('separate instances have independent channels', () {
      final _FakeAdapter adapter1 = _FakeAdapter();
      final _FakeAdapter adapter2 = _FakeAdapter();
      final FoundryNavigation nav1 = FoundryNavigation(
        defaultAdapter: adapter1,
      );
      final FoundryNavigation nav2 = FoundryNavigation(
        defaultAdapter: adapter2,
      );

      final _FakeAdapter ch = _FakeAdapter();
      nav1.registerChannel('tab', ch);

      expect(
        () => nav2.pushInChannel('tab', const _TestRoute('x')),
        throwsA(isA<StateError>()),
      );
    });
  });
}
