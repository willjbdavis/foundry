import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:foundry_flutter/foundry_flutter.dart';

class TestViewModel extends FoundryViewModel<int> {
  TestViewModel(this._state);

  int _state;
  final StreamController<int> _controller = StreamController<int>.broadcast(
    sync: true,
  );

  int initCount = 0;
  int disposeCount = 0;

  @override
  int get state => _state;

  @override
  Stream<int> get states => _controller.stream;

  @override
  void emitNewState(final int newState) {
    _state = newState;
    _controller.add(newState);
  }

  @override
  Future<void> onInit() async {
    initCount += 1;
  }

  @override
  Future<void> onDispose() async {
    disposeCount += 1;
    await _controller.close();
  }

  void increment() => emitNewState(_state + 1);
}

class TestView extends FoundryView<TestViewModel, int> {
  const TestView({super.key});

  @override
  Widget buildWithState(
    final BuildContext context,
    final int? oldState,
    final int newState,
  ) {
    return Text(
      'state:$newState old:${oldState ?? -1}',
      textDirection: TextDirection.ltr,
    );
  }
}

class ScopedIdentityViewModel extends FoundryViewModel<int> {
  ScopedIdentityViewModel() {
    _id = ++_nextId;
    emitNewState(_id);
  }

  late final int _id;
  static int _nextId = 0;
  static int disposeCalls = 0;

  static void resetForTest() {
    _nextId = 0;
    disposeCalls = 0;
  }

  @override
  Future<void> onDispose() async {
    disposeCalls += 1;
  }
}

class ScopedIdentityView extends FoundryView<ScopedIdentityViewModel, int> {
  const ScopedIdentityView({required this.label, super.key});

  final String label;

  @override
  Widget buildWithState(
    final BuildContext context,
    final int? oldState,
    final int newState,
  ) {
    final ScopedIdentityViewModel resolved = FoundryScope.of(
      context,
    ).resolve<ScopedIdentityViewModel>();
    return Text(
      '$label:$newState/${resolved.state}',
      textDirection: TextDirection.ltr,
    );
  }
}

void main() {
  testWidgets('FoundryScope.of resolves nearest scope', (
    final WidgetTester tester,
  ) async {
    final GlobalScope scope = GlobalScope.create();

    await tester.pumpWidget(
      FoundryScope(
        scope: scope,
        child: Builder(
          builder: (final BuildContext context) {
            final Scope resolved = FoundryScope.of(context);
            return Text(
              identical(scope, resolved) ? 'ok' : 'fail',
              textDirection: TextDirection.ltr,
            );
          },
        ),
      ),
    );

    expect(find.text('ok'), findsOneWidget);
  });

  testWidgets('FoundryView binds ViewModel and renders old/new states', (
    final WidgetTester tester,
  ) async {
    final GlobalScope scope = GlobalScope.create();
    scope.register<TestViewModel>((_) => TestViewModel(0));

    await tester.pumpWidget(
      FoundryScope(scope: scope, child: const TestView()),
    );

    final TestViewModel viewModel = scope.resolve<TestViewModel>();
    expect(viewModel.initCount, 1);
    expect(find.text('state:0 old:-1'), findsOneWidget);

    viewModel.increment();
    await tester.pump();
    await tester.pump();

    expect(find.text('state:1 old:0'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(viewModel.disposeCount, 1);
  });

  testWidgets(
    'scoped ViewModel gives each view its own instance and context resolves same instance',
    (final WidgetTester tester) async {
      ScopedIdentityViewModel.resetForTest();
      final GlobalScope scope = GlobalScope.create();
      scope.register<ScopedIdentityViewModel>(
        (_) => ScopedIdentityViewModel(),
        lifetime: Lifetime.scoped,
      );

      await tester.pumpWidget(
        FoundryScope(
          scope: scope,
          child: const Column(
            children: <Widget>[
              ScopedIdentityView(label: 'a'),
              ScopedIdentityView(label: 'b'),
            ],
          ),
        ),
      );
      await tester.pump();

      final String a = tester.widget<Text>(find.textContaining('a:')).data!;
      final String b = tester.widget<Text>(find.textContaining('b:')).data!;

      final List<String> aParts = a.substring(2).split('/');
      final List<String> bParts = b.substring(2).split('/');

      expect(aParts[0], aParts[1]);
      expect(bParts[0], bParts[1]);
      expect(aParts[0], isNot(equals(bParts[0])));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(ScopedIdentityViewModel.disposeCalls, 2);
    },
  );

  testWidgets('FoundryBuilder and FoundryListener react to state changes', (
    final WidgetTester tester,
  ) async {
    final TestViewModel emitter = TestViewModel(10);
    int listenerCalls = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FoundryListener<int>(
          emitter: emitter,
          listener:
              (
                final BuildContext context,
                final int? oldState,
                final int newState,
              ) {
                listenerCalls += 1;
              },
          child: FoundryBuilder<int>(
            emitter: emitter,
            builder: (_, oldState, newState) {
              return Text('b:$newState/${oldState ?? -1}');
            },
          ),
        ),
      ),
    );

    expect(find.text('b:10/-1'), findsOneWidget);

    emitter.increment();
    await tester.pump();
    await tester.pump();

    expect(find.text('b:11/10'), findsOneWidget);
    expect(listenerCalls, 1);
  });

  testWidgets('FoundrySelectorBuilder only rebuilds when selector allows', (
    final WidgetTester tester,
  ) async {
    final TestViewModel emitter = TestViewModel(0);
    int buildCount = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FoundrySelectorBuilder<int>(
          emitter: emitter,
          selector: (final oldState, final newState) => newState.isEven,
          builder: (_, state) {
            buildCount += 1;
            return Text('s:$state');
          },
        ),
      ),
    );

    expect(find.text('s:0'), findsOneWidget);
    final int initialBuilds = buildCount;

    emitter.increment();
    await tester.pump();
    expect(find.text('s:0'), findsOneWidget);
    expect(buildCount, initialBuilds);

    emitter.increment();
    await tester.pump();
    expect(find.text('s:2'), findsOneWidget);
    expect(buildCount, initialBuilds + 1);
  });

  testWidgets('FoundryScope.of throws StateError when no scope ancestor', (
    final WidgetTester tester,
  ) async {
    late Object caughtError;

    await tester.pumpWidget(
      Builder(
        builder: (final BuildContext context) {
          try {
            FoundryScope.of(context);
          } catch (e) {
            caughtError = e;
          }
          return const SizedBox.shrink();
        },
      ),
    );

    expect(caughtError, isA<StateError>());
  });

  testWidgets(
    'FoundryScope.childScope resolves parent registrations and disposes on removal',
    (final WidgetTester tester) async {
      final GlobalScope root = GlobalScope.create();
      root.register<String>((_) => 'hello');

      String? resolved;

      await tester.pumpWidget(
        FoundryScope(
          scope: root,
          child: FoundryScope.childScope(
            child: Builder(
              builder: (final BuildContext context) {
                resolved = FoundryScope.of(context).resolve<String>();
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(resolved, 'hello');

      // Remove the subtree — child scope should be disposed without error.
      await tester.pumpWidget(
        FoundryScope(scope: root, child: const SizedBox.shrink()),
      );
    },
  );

  testWidgets('FoundryBuilder rebinds when emitter is swapped', (
    final WidgetTester tester,
  ) async {
    final TestViewModel first = TestViewModel(1);
    final TestViewModel second = TestViewModel(99);

    final ValueNotifier<TestViewModel> emitterNotifier =
        ValueNotifier<TestViewModel>(first);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ValueListenableBuilder<TestViewModel>(
          valueListenable: emitterNotifier,
          builder: (context, emitter, child) => FoundryBuilder<int>(
            emitter: emitter,
            builder: (ctx, oldState, state) => Text('v:$state'),
          ),
        ),
      ),
    );

    expect(find.text('v:1'), findsOneWidget);

    emitterNotifier.value = second;
    await tester.pump();

    expect(find.text('v:99'), findsOneWidget);
  });

  testWidgets('FoundryListener does not fire for initial state', (
    final WidgetTester tester,
  ) async {
    final TestViewModel emitter = TestViewModel(5);
    int listenerCalls = 0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FoundryListener<int>(
          emitter: emitter,
          listener: (context, oldState, newState) => listenerCalls++,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    // After initial pump the listener must not have been called.
    expect(listenerCalls, 0);

    emitter.increment();
    await tester.pump();

    expect(listenerCalls, 1);
  });

  testWidgets(
    'FoundryListener tracks oldState correctly across multiple emissions',
    (final WidgetTester tester) async {
      final TestViewModel emitter = TestViewModel(10);
      final List<(int?, int)> calls = <(int?, int)>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FoundryListener<int>(
            emitter: emitter,
            listener: (_, old, next) => calls.add((old, next)),
            child: const SizedBox.shrink(),
          ),
        ),
      );

      emitter.increment(); // 10 → 11
      await tester.pump();
      emitter.increment(); // 11 → 12
      await tester.pump();

      expect(calls, <(int, int)>[(10, 11), (11, 12)]);
    },
  );

  testWidgets('FoundrySelectorBuilder tracks state between blocked rebuilds', (
    final WidgetTester tester,
  ) async {
    // Selector only allows even numbers through.
    // Emit 0(even) -> 1(blocked) -> 2(allowed).
    // The builder should receive 2, not 0 (i.e. the blocked emission was tracked).
    final TestViewModel emitter = TestViewModel(0);
    final List<int> builtStates = <int>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FoundrySelectorBuilder<int>(
          emitter: emitter,
          selector: (_, next) => next.isEven,
          builder: (_, state) {
            builtStates.add(state);
            return Text('s:$state');
          },
        ),
      ),
    );

    emitter.increment(); // → 1, blocked
    await tester.pump();
    emitter.increment(); // → 2, allowed
    await tester.pump();

    // Should have rebuilt with 2, not 0 (tracked through blocked step).
    expect(find.text('s:2'), findsOneWidget);
    expect(builtStates.last, 2);
  });

  testWidgets('FoundrySelectorBuilder rebinds when emitter is swapped', (
    final WidgetTester tester,
  ) async {
    final TestViewModel first = TestViewModel(3);
    final TestViewModel second = TestViewModel(77);

    final ValueNotifier<TestViewModel> emitterNotifier =
        ValueNotifier<TestViewModel>(first);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ValueListenableBuilder<TestViewModel>(
          valueListenable: emitterNotifier,
          builder: (context, emitter, child) => FoundrySelectorBuilder<int>(
            emitter: emitter,
            selector: (oldState, newState) => true,
            builder: (ctx, state) => Text('v:$state'),
          ),
        ),
      ),
    );

    expect(find.text('v:3'), findsOneWidget);

    emitterNotifier.value = second;
    await tester.pump();

    expect(find.text('v:77'), findsOneWidget);
  });
}
