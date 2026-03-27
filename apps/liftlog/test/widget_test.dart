import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lift_log/core/models/rest_timer_service.dart';
import 'package:lift_log/core/models/workout_session_model.dart';
import 'package:lift_log/core/repositories/exercise_repository.dart';
import 'package:lift_log/core/repositories/workout_repository.dart';
import 'package:lift_log/features/exercises/exercise_editor_view.dart';
import 'package:lift_log/features/home/home_view.dart';
import 'package:lift_log/features/workout/exercise_log_view.dart';
import 'package:lift_log/features/workout/exercise_picker_view.dart';
import 'package:lift_log/features/workout/workout_session_setup_view.dart';
import 'package:lift_log/features/workout/workout_summary_view.dart';
import 'package:foundry_flutter/foundry_flutter.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

import 'test_helpers.dart';

const Timeout _defaultTestTimeout = Timeout(Duration(seconds: 30));

void main() {
  late Directory tempDirectory;
  late TestHiveDatabaseService databaseService;
  late WorkoutRepository workoutRepository;
  late ExerciseRepository exerciseRepository;
  late WorkoutSessionModel sessionModel;
  late RestTimerService restTimerService;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'liftlog_widget_test_',
    );
    databaseService = TestHiveDatabaseService(tempDirectory);
    await databaseService.initialize();

    workoutRepository = WorkoutRepository(databaseService);
    exerciseRepository = ExerciseRepository(databaseService);
    sessionModel = WorkoutSessionModel(workoutRepository);
    restTimerService = RestTimerService();
    await sessionModel.initialize();
  });

  tearDown(() async {
    await restTimerService.disposeStream();
    await sessionModel.disposeStream();
    await databaseService.dispose();
  });

  Future<GlobalKey<NavigatorState>> pumpWithScope(
    WidgetTester tester,
    Widget home,
  ) async {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    final FlutterNavigatorAdapter defaultAdapter =
        FlutterNavigatorAdapter.fromKey(navigatorKey);
    FoundryNavigator.configure(defaultAdapter);
    FoundryNavigation.configure(
      FoundryNavigation(defaultAdapter: defaultAdapter),
    );

    final GlobalScope scope = GlobalScope.create();
    scope.register<WorkoutRepository>((_) => workoutRepository);
    scope.register<ExerciseRepository>((_) => exerciseRepository);
    scope.register<WorkoutSessionModel>((_) => sessionModel);
    scope.register<RestTimerService>((_) => restTimerService);
    scope.register<HomeViewModel>(
      (Scope s) => HomeViewModel(
        s.resolve<WorkoutSessionModel>(),
        s.resolve<WorkoutRepository>(),
      ),
    );
    scope.register<WorkoutSessionSetupViewModel>(
      (Scope s) =>
          WorkoutSessionSetupViewModel(s.resolve<WorkoutSessionModel>()),
    );
    scope.register<ExercisePickerViewModel>(
      (Scope s) => ExercisePickerViewModel(
        s.resolve<WorkoutSessionModel>(),
        s.resolve<ExerciseRepository>(),
      ),
    );
    scope.register<ExerciseLogViewModel>(
      (Scope s) => ExerciseLogViewModel(
        s.resolve<WorkoutSessionModel>(),
        s.resolve<RestTimerService>(),
      ),
    );
    scope.register<WorkoutSummaryViewModel>(
      (Scope s) => WorkoutSummaryViewModel(s.resolve<WorkoutSessionModel>()),
    );
    scope.register<ExerciseEditorViewModel>(
      (Scope s) => ExerciseEditorViewModel(s.resolve<ExerciseRepository>()),
    );

    await tester.pumpWidget(
      FoundryScope(
        scope: scope,
        child: MaterialApp(navigatorKey: navigatorKey, home: home),
      ),
    );
    await tester.pumpAndSettleTwice(
      firstStep: const Duration(milliseconds: 120),
      secondStep: const Duration(milliseconds: 120),
    );
    return navigatorKey;
  }

  testWidgets(
    'start workout flow smoke: Home -> Workout Setup',
    (WidgetTester tester) async {
      await pumpWithScope(tester, const HomeView());

      await tester.tap(find.text('Start Workout'));
      await tester.pumpAndSettleTwice(
        firstStep: const Duration(milliseconds: 120),
        secondStep: const Duration(milliseconds: 120),
      );

      expect(find.text('Workout Setup'), findsOneWidget);
    },
    timeout: _defaultTestTimeout,
  );
}
