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
}
