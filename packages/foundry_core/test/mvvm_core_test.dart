import 'package:flutter_test/flutter_test.dart';
import 'package:foundry_core/foundry_core.dart';

class _Box {
  _Box(this.value);

  final int value;
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
}
