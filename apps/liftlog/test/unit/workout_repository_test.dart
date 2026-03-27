import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lift_log/core/repositories/workout_repository.dart';

import '../test_helpers.dart';

const Timeout _defaultTestTimeout = Timeout(Duration(seconds: 30));

void main() {
  late Directory tempDirectory;
  late TestHiveDatabaseService databaseService;
  late WorkoutRepository repository;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('liftlog_repo_test_');
    databaseService = TestHiveDatabaseService(tempDirectory);
    await databaseService.initialize();
    repository = WorkoutRepository(databaseService);
  });

  tearDown(() async {
    await databaseService.dispose();
  });

  test(
    'createDraft persists and only one draft is allowed',
    () async {
      final draft = await repository.createDraft(
        title: 'Pull Day',
        date: DateTime.utc(2026, 3, 1),
      );

      final loaded = await repository.loadActiveDraft();
      expect(loaded?.id, draft.id);

      expect(
        () => repository.createDraft(
          title: 'Push Day',
          date: DateTime.utc(2026, 3, 2),
        ),
        throwsA(isA<WorkoutRepositoryException>()),
      );
    },
    timeout: _defaultTestTimeout,
  );

  test(
    'finalizeDraft moves active draft to completed list and clears active',
    () async {
      final draft = await repository.createDraft(
        title: 'Leg Day',
        date: DateTime.utc(2026, 3, 3),
        notes: 'Heavy squats',
      );

      final completed = await repository.finalizeDraft();
      expect(completed.id, draft.id);
      expect(completed.completedAt, isNotNull);

      final active = await repository.loadActiveDraft();
      expect(active, isNull);

      final allCompleted = await repository.listCompletedWorkouts();
      expect(allCompleted.length, 1);
      expect(allCompleted.first.id, draft.id);
    },
    timeout: _defaultTestTimeout,
  );
}
