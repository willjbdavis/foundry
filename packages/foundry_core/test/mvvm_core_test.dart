import 'package:flutter_test/flutter_test.dart';
import 'package:foundry_core/foundry_core.dart';

class _Box {
  _Box(this.value);

  final int value;
}

class _TestLogger implements FoundryLogger {
  final List<LogEvent> events = <LogEvent>[];

  @override
  void log(LogEvent event) {
    events.add(event);
  }
}

void main() {
  group('GlobalScope', () {
    test('register and resolve returns same scoped instance', () {
      final GlobalScope scope = GlobalScope.create();
      int createCount = 0;

      scope.register<_Box>((_) {
        createCount += 1;
        return _Box(42);
      });

      final _Box first = scope.resolve<_Box>();
      final _Box second = scope.resolve<_Box>();

      expect(first, same(second));
      expect(first.value, 42);
      expect(createCount, 1);
    });

    test('transient lifetime returns a new instance each resolution', () {
      final GlobalScope scope = GlobalScope.create();
      int createCount = 0;

      scope.register<_Box>((_) {
        createCount += 1;
        return _Box(createCount);
      }, lifetime: Lifetime.transient);

      final _Box first = scope.resolve<_Box>();
      final _Box second = scope.resolve<_Box>();

      expect(first, isNot(same(second)));
      expect(first.value, 1);
      expect(second.value, 2);
      expect(createCount, 2);
    });

    test('scoped lifetime returns same instance within the same scope', () {
      final GlobalScope scope = GlobalScope.create();
      int createCount = 0;

      scope.register<_Box>((_) {
        createCount += 1;
        return _Box(100 + createCount);
      }, lifetime: Lifetime.scoped);

      final _Box first = scope.resolve<_Box>();
      final _Box second = scope.resolve<_Box>();

      expect(first, same(second));
      expect(createCount, 1);
    });

    test('supports named registrations', () {
      final GlobalScope scope = GlobalScope.create();
      scope.register<String>((_) => 'primary', named: 'primary');
      scope.register<String>((_) => 'staging', named: 'staging');

      expect(scope.resolve<String>(named: 'primary'), 'primary');
      expect(scope.resolve<String>(named: 'staging'), 'staging');
    });

    test('throws clear error for missing registration', () {
      final GlobalScope scope = GlobalScope.create();
      expect(() => scope.resolve<int>(), throwsA(isA<StateError>()));
    });

    test('dispose invalidates scope operations', () {
      final GlobalScope scope = GlobalScope.create();
      scope.dispose();

      expect(() => scope.register<int>((_) => 1), throwsA(isA<StateError>()));
      expect(() => scope.resolve<int>(), throwsA(isA<StateError>()));
      expect(() => scope.createChild(), throwsA(isA<StateError>()));
    });
  });

  group('ChildScope', () {
    tearDown(() {
      Foundry.clearLogger();
    });

    test('falls back to parent registration', () {
      final GlobalScope root = GlobalScope.create();
      root.register<int>((_) => 7);

      final Scope child = root.createChild();
      expect(child.resolve<int>(), 7);
    });

    test('shadows parent registration', () {
      final GlobalScope root = GlobalScope.create();
      root.register<int>((_) => 7);

      final Scope child = root.createChild();
      child.register<int>((_) => 99);

      expect(root.resolve<int>(), 7);
      expect(child.resolve<int>(), 99);
    });

    test('supports named shadowing', () {
      final GlobalScope root = GlobalScope.create();
      root.register<String>((_) => 'root', named: 'api');

      final Scope child = root.createChild();
      child.register<String>((_) => 'child', named: 'api');

      expect(root.resolve<String>(named: 'api'), 'root');
      expect(child.resolve<String>(named: 'api'), 'child');
    });

    test('caches parent scoped instance into child after first resolve', () {
      final _TestLogger logger = _TestLogger();
      Foundry.configureLogger(logger);

      final GlobalScope root = GlobalScope.create();
      int createCount = 0;

      root.register<_Box>((_) {
        createCount += 1;
        return _Box(createCount);
      }, lifetime: Lifetime.scoped);

      final Scope child = root.createChild();
      final _Box first = child.resolve<_Box>();
      final _Box second = child.resolve<_Box>();

      expect(first, same(second));
      expect(createCount, 1);

      final List<String> messages = logger.events
          .map((event) => event.message)
          .toList();

      expect(
        messages
            .where(
              (message) =>
                  message.contains('No local entry for _Box') &&
                  message.contains('delegating to parent scope'),
            )
            .length,
        1,
      );
      expect(
        messages
            .where(
              (message) =>
                  message.contains('Resolved _Box from GlobalScope') &&
                  message.contains(
                    'new instance created and cached in requesting child scope',
                  ),
            )
            .length,
        1,
      );
      expect(
        messages
            .where(
              (message) =>
                  message.contains('Resolved _Box from child scope') &&
                  message.contains('scope-local cache hit'),
            )
            .length,
        1,
      );
    });

    test(
      'scoped registration in parent creates separate instances per child',
      () {
        final GlobalScope root = GlobalScope.create();
        int createCount = 0;

        root.register<_Box>((_) {
          createCount += 1;
          return _Box(createCount);
        }, lifetime: Lifetime.scoped);

        final Scope childA = root.createChild();
        final Scope childB = root.createChild();

        final _Box a1 = childA.resolve<_Box>();
        final _Box a2 = childA.resolve<_Box>();
        final _Box b1 = childB.resolve<_Box>();

        expect(a1, same(a2));
        expect(a1, isNot(same(b1)));
        expect(createCount, 2);
      },
    );

    test('named scoped registrations are cached back into child scope', () {
      final _TestLogger logger = _TestLogger();
      Foundry.configureLogger(logger);

      final GlobalScope root = GlobalScope.create();
      int createCount = 0;

      root.register<_Box>(
        (_) {
          createCount += 1;
          return _Box(createCount);
        },
        named: 'api',
        lifetime: Lifetime.scoped,
      );

      final Scope child = root.createChild();
      final _Box first = child.resolve<_Box>(named: 'api');
      final _Box second = child.resolve<_Box>(named: 'api');

      expect(first, same(second));
      expect(createCount, 1);

      final List<String> messages = logger.events
          .map((event) => event.message)
          .toList();

      expect(
        messages
            .where(
              (message) =>
                  message.contains('No local entry for _Box') &&
                  message.contains('delegating to parent scope'),
            )
            .length,
        1,
      );
      expect(
        messages
            .where(
              (message) =>
                  message.contains('Resolved _Box from child scope') &&
                  message.contains('scope-local cache hit'),
            )
            .length,
        1,
      );
    });

    test('singleton registration in parent is shared across children', () {
      final GlobalScope root = GlobalScope.create();

      root.register<_Box>((_) => _Box(7), lifetime: Lifetime.singleton);

      final Scope childA = root.createChild();
      final Scope childB = root.createChild();

      final _Box rootInstance = root.resolve<_Box>();
      final _Box a = childA.resolve<_Box>();
      final _Box b = childB.resolve<_Box>();

      expect(rootInstance, same(a));
      expect(a, same(b));
    });

    test('singleton parent registrations are not attached to child cache', () {
      final _TestLogger logger = _TestLogger();
      Foundry.configureLogger(logger);

      final GlobalScope root = GlobalScope.create();
      int createCount = 0;

      root.register<_Box>((_) {
        createCount += 1;
        return _Box(7);
      }, lifetime: Lifetime.singleton);

      final Scope child = root.createChild();
      final _Box first = child.resolve<_Box>();
      final _Box second = child.resolve<_Box>();

      expect(first, same(second));
      expect(createCount, 1);

      final List<String> messages = logger.events
          .map((event) => event.message)
          .toList();

      expect(
        messages
            .where(
              (message) =>
                  message.contains('No local entry for _Box') &&
                  message.contains('delegating to parent scope'),
            )
            .length,
        2,
      );
      expect(
        messages
            .where(
              (message) =>
                  message.contains('Resolved _Box from child scope') &&
                  message.contains('scope-local cache hit'),
            )
            .isEmpty,
        isTrue,
      );
    });

    test(
      'transient registration in parent returns new instance per resolve',
      () {
        final GlobalScope root = GlobalScope.create();
        int createCount = 0;

        root.register<_Box>((_) {
          createCount += 1;
          return _Box(createCount);
        }, lifetime: Lifetime.transient);

        final Scope child = root.createChild();
        final _Box first = child.resolve<_Box>();
        final _Box second = child.resolve<_Box>();

        expect(first, isNot(same(second)));
        expect(createCount, 2);
      },
    );

    test(
      'transient parent registrations are never cached into child scope',
      () {
        final _TestLogger logger = _TestLogger();
        Foundry.configureLogger(logger);

        final GlobalScope root = GlobalScope.create();
        int createCount = 0;

        root.register<_Box>((_) {
          createCount += 1;
          return _Box(createCount);
        }, lifetime: Lifetime.transient);

        final Scope child = root.createChild();
        final _Box first = child.resolve<_Box>();
        final _Box second = child.resolve<_Box>();

        expect(first, isNot(same(second)));
        expect(createCount, 2);

        final List<String> messages = logger.events
            .map((event) => event.message)
            .toList();

        expect(
          messages
              .where(
                (message) =>
                    message.contains('No local entry for _Box') &&
                    message.contains('delegating to parent scope'),
              )
              .length,
          2,
        );
        expect(
          messages
              .where(
                (message) =>
                    message.contains('Resolved _Box from child scope') &&
                    message.contains('scope-local cache hit'),
              )
              .isEmpty,
          isTrue,
        );
      },
    );

    test(
      'disposes descendants in reverse order and invalidates child scopes',
      () {
        final GlobalScope root = GlobalScope.create();
        final Scope child = root.createChild();
        final Scope grandchild = child.createChild();

        child.dispose();

        expect(() => child.resolve<int>(), throwsA(isA<StateError>()));
        expect(() => grandchild.resolve<int>(), throwsA(isA<StateError>()));
      },
    );

    test('global dispose invalidates existing descendants', () {
      final GlobalScope root = GlobalScope.create();
      final Scope child = root.createChild();
      final Scope grandchild = child.createChild();

      root.dispose();

      expect(() => child.resolve<int>(), throwsA(isA<StateError>()));
      expect(() => grandchild.resolve<int>(), throwsA(isA<StateError>()));
    });
  });

  group('Foundry logging', () {
    tearDown(() {
      Foundry.clearLogger();
    });

    test('configureLogger routes events to logger object', () {
      final _TestLogger logger = _TestLogger();
      Foundry.configureLogger(logger);

      Foundry.log(
        const LogEvent(level: LogLevel.info, tag: 'test', message: 'hello'),
      );

      expect(logger.events, hasLength(1));
      expect(logger.events.single.message, 'hello');
      expect(logger.events.single.level, LogLevel.info);
    });

    test('configureLoggerFn routes events to callback', () {
      final List<LogEvent> events = <LogEvent>[];
      Foundry.configureLoggerFn(events.add);

      Foundry.log(
        const LogEvent(
          level: LogLevel.debug,
          tag: 'test',
          message: 'callback-event',
        ),
      );

      expect(events, hasLength(1));
      expect(events.single.message, 'callback-event');
      expect(events.single.level, LogLevel.debug);
    });

    test('clearLogger disables logging without throwing', () {
      final _TestLogger logger = _TestLogger();
      Foundry.configureLogger(logger);
      Foundry.clearLogger();

      expect(
        () => Foundry.log(
          const LogEvent(level: LogLevel.warning, message: 'ignored'),
        ),
        returnsNormally,
      );
      expect(logger.events, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // FoundryViewModel
  // ---------------------------------------------------------------------------

  group('FoundryViewModel', () {
    late _CounterViewModel vm;

    setUp(() => vm = _CounterViewModel());
    tearDown(() => vm.disposeStream());

    test('state throws StateError before any state emitted', () {
      expect(() => vm.state, throwsA(isA<StateError>()));
    });

    test('state returns the last emitted value', () {
      vm.push(1);
      expect(vm.state, 1);
      vm.push(42);
      expect(vm.state, 42);
    });

    test('emitNewState emits to states stream', () async {
      // Subscribe before pushing so no events are missed on a broadcast stream.
      final Future<List<int>> future = vm.states.take(3).toList();

      vm.push(10);
      vm.push(20);
      vm.push(30);

      expect(await future, <int>[10, 20, 30]);
    });

    test('onInit hook is invoked by invokeOnInit', () async {
      expect(vm.initCalled, isFalse);
      await vm.invokeOnInit();
      expect(vm.initCalled, isTrue);
    });

    test('onResumed hook is invoked by invokeOnResumed', () async {
      expect(vm.resumedCalled, isFalse);
      await vm.invokeOnResumed();
      expect(vm.resumedCalled, isTrue);
    });

    test('onPaused hook is invoked by invokeOnPaused', () async {
      expect(vm.pausedCalled, isFalse);
      await vm.invokeOnPaused();
      expect(vm.pausedCalled, isTrue);
    });

    test('onDispose hook is invoked by invokeOnDispose', () async {
      expect(vm.disposeCalled, isFalse);
      await vm.invokeOnDispose();
      expect(vm.disposeCalled, isTrue);
    });

    test('onBackPressed returns true by default', () async {
      final bool result = await vm.invokeOnBackPressed();
      expect(result, isTrue);
    });

    test('disposeStream closes the states stream', () async {
      vm.push(1);

      bool doneFired = false;
      vm.states.listen(null, onDone: () => doneFired = true);

      vm.disposeStream();
      // yield so the stream onDone callback fires
      await Future<void>.microtask(() {});

      expect(doneFired, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // StatefulService
  // ---------------------------------------------------------------------------

  group('StatefulService', () {
    late _CounterService service;

    setUp(() => service = _CounterService());
    tearDown(() => service.disposeStream());

    test('state throws StateError before any state emitted', () {
      expect(() => service.state, throwsA(isA<StateError>()));
    });

    test('emitNewState updates state and broadcasts to stream', () async {
      // Subscribe before pushing so no events are missed on a broadcast stream.
      final Future<List<int>> future = service.states.take(2).toList();

      service.push(5);
      service.push(10);

      expect(await future, <int>[5, 10]);
      expect(service.state, 10);
    });

    test('subscribe listener receives future emissions', () {
      final List<int> received = <int>[];
      service.subscribe(received.add);

      service.push(7);
      service.push(8);

      expect(received, <int>[7, 8]);
    });

    test('unsubscribe stops listener receiving emissions', () {
      final List<int> received = <int>[];
      void listener(int v) => received.add(v);

      service.subscribe(listener);
      service.push(1);
      service.unsubscribe(listener);
      service.push(2);

      expect(received, <int>[1]);
    });

    test('duplicate subscribe is ignored (called once per emission)', () {
      int callCount = 0;
      void listener(int _) => callCount++;

      service.subscribe(listener);
      service.subscribe(listener); // duplicate
      service.push(99);

      expect(callCount, 1);
    });

    test('initialize delegates to onInit hook', () async {
      expect(service.initCalled, isFalse);
      await service.initialize();
      expect(service.initCalled, isTrue);
    });

    test('disposeStream closes stream without error', () async {
      service.push(1);

      bool doneFired = false;
      service.states.listen(null, onDone: () => doneFired = true);

      service.disposeStream();
      await Future<void>.microtask(() {});

      expect(doneFired, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Container
  // ---------------------------------------------------------------------------

  group('Container', () {
    test('register and resolve delegates to global scope', () {
      final Container container = Container();
      container.register<int>((_) => 42);
      expect(container.resolve<int>(), 42);
    });

    test('createChild returns scope with parent fallback', () {
      final Container container = Container();
      container.register<String>((_) => 'hello');

      final Scope child = container.createChild();
      expect(child.resolve<String>(), 'hello');
    });

    test('globalScope is accessible and consistent with container', () {
      final Container container = Container();
      container.register<double>((_) => 3.14);

      expect(container.globalScope.resolve<double>(), 3.14);
    });
  });

  // ---------------------------------------------------------------------------
  // Foundry deep-link fallback
  // ---------------------------------------------------------------------------

  group('Foundry deep-link fallback', () {
    tearDown(() => Foundry.clearDeepLinkFallbackPath());

    test('configureDeepLinkFallbackPath stores value', () {
      Foundry.configureDeepLinkFallbackPath('/home');
      expect(Foundry.deepLinkFallbackPath, '/home');
    });

    test('clearDeepLinkFallbackPath resets to null', () {
      Foundry.configureDeepLinkFallbackPath('/home');
      Foundry.clearDeepLinkFallbackPath();
      expect(Foundry.deepLinkFallbackPath, isNull);
    });

    test('deepLinkFallbackPath is null before configuration', () {
      expect(Foundry.deepLinkFallbackPath, isNull);
    });
  });
}

// ---------------------------------------------------------------------------
// Concrete test subclasses
// ---------------------------------------------------------------------------

class _CounterViewModel extends FoundryViewModel<int> {
  bool initCalled = false;
  bool resumedCalled = false;
  bool pausedCalled = false;
  bool disposeCalled = false;

  void push(int value) => emitNewState(value);

  @override
  Future<void> onInit() async => initCalled = true;

  @override
  Future<void> onResumed() async => resumedCalled = true;

  @override
  Future<void> onPaused() async => pausedCalled = true;

  @override
  Future<void> onDispose() async => disposeCalled = true;
}

class _CounterService extends StatefulService<int> {
  bool initCalled = false;

  void push(int value) => emitNewState(value);

  @override
  Future<void> onInit() async => initCalled = true;
}
