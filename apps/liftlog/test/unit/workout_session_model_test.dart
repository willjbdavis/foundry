import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lift_log/core/models/workout_session_model.dart';
import 'package:lift_log/core/repositories/workout_repository.dart';

import '../test_helpers.dart';

const Timeout _defaultTestTimeout = Timeout(Duration(seconds: 30));

void main() {
  late Directory tempDirectory;
  late TestHiveDatabaseService databaseService;
  late WorkoutRepository repository;
  late WorkoutSessionModel model;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'liftlog_model_test_',
    );
    databaseService = TestHiveDatabaseService(tempDirectory);
    await databaseService.initialize();

    repository = WorkoutRepository(databaseService);
    model = WorkoutSessionModel(repository);
    await model.initialize();
  });

  tearDown(() async {
    await model.disposeStream();
    await databaseService.dispose();
  });

  test(
    'exercise and set mutations are autosaved through repository',
    () async {
      final draft = await model.createDraft(
        title: 'Push',
        date: DateTime.utc(2026, 3, 4),
      );
      expect(draft, isNotNull);

      await model.addExercise(exerciseId: 'bench', displayName: 'Bench Press');
      await model.addSet(exerciseId: 'bench', reps: 8, weight: 135);

      final persisted = await repository.loadActiveDraft();
      expect(persisted, isNotNull);
      expect(persisted!.exercises.length, 1);
      expect(persisted.exercises.first.sets.length, 1);
      expect(persisted.exercises.first.sets.first.reps, 8);
    },
    timeout: _defaultTestTimeout,
  );

  test(
    'finalizeActiveDraft clears active draft and writes completed workout',
    () async {
      await model.createDraft(title: 'Pull', date: DateTime.utc(2026, 3, 5));

      final completed = await model.finalizeActiveDraft();
      expect(completed, isNotNull);

      final active = await repository.loadActiveDraft();
      expect(active, isNull);

      final completedList = await repository.listCompletedWorkouts();
      expect(completedList.length, 1);
    },
    timeout: _defaultTestTimeout,
  );
}
