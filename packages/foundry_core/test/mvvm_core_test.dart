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
}
