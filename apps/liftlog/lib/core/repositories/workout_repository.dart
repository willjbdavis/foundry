import 'package:foundry_annotations/foundry_annotations.dart' as foundry;

import '../domain/workout.dart';
import '../persistence/hive_database_service.dart';
import '../persistence/records/active_workout_draft_record.dart';
import '../persistence/records/workout_record.dart';

part 'workout_repository.g.dart';

class WorkoutRepositoryException implements Exception {
  WorkoutRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

@foundry.FoundryModel()
class WorkoutRepository {
  WorkoutRepository(this._databaseService);

  static const String _activeDraftKey = 'active_workout_draft';

  final HiveDatabaseService _databaseService;

  Future<Workout> createDraft({
    required String title,
    required DateTime date,
    String notes = '',
  }) async {
    final Workout? existing = await loadActiveDraft();
    if (existing != null) {
      throw WorkoutRepositoryException(
        'An active workout draft already exists.',
      );
    }

    final DateTime now = DateTime.now().toUtc();
    final Workout draft = Workout(
      id: now.microsecondsSinceEpoch.toString(),
      title: title.trim().isEmpty ? 'Workout' : title.trim(),
      date: date.toUtc(),
      notes: notes.trim(),
      createdAt: now,
    );

    await saveDraft(draft);
    return draft;
  }

  Future<Workout?> loadActiveDraft() async {
    final dynamic raw = _databaseService.activeWorkoutBox.get(_activeDraftKey);
    if (raw is! Map<dynamic, dynamic>) {
      return null;
    }

    return ActiveWorkoutDraftRecord.fromMap(raw).toDomain();
  }

  Future<Workout> saveDraft(Workout draft) async {
    final Workout? existing = await loadActiveDraft();
    if (existing != null && existing.id != draft.id) {
      throw WorkoutRepositoryException(
        'Only one active workout draft is allowed at a time.',
      );
    }

    final Workout sanitized = draft.copyWith(
      title: draft.title.trim().isEmpty ? 'Workout' : draft.title.trim(),
      notes: draft.notes.trim(),
    );

    await _databaseService.activeWorkoutBox.put(
      _activeDraftKey,
      ActiveWorkoutDraftRecord.fromDomain(sanitized).toMap(),
    );

    return sanitized;
  }

  Future<void> discardDraft() async {
    await _databaseService.activeWorkoutBox.delete(_activeDraftKey);
  }

  Future<Workout> finalizeDraft() async {
    final Workout? active = await loadActiveDraft();
    if (active == null) {
      throw WorkoutRepositoryException('No active workout draft found.');
    }

    final Workout completed = active.copyWith(
      completedAt: DateTime.now().toUtc(),
    );

    await _databaseService.workoutsBox.put(
      completed.id,
      WorkoutRecord.fromDomain(completed).toMap(),
    );
    await discardDraft();

    return completed;
  }

  Future<List<Workout>> listCompletedWorkouts() async {
    final List<Workout> workouts = _databaseService.workoutsBox.values
        .whereType<Map<dynamic, dynamic>>()
        .map(WorkoutRecord.fromMap)
        .map((WorkoutRecord r) => r.toDomain())
        .toList();

    workouts.sort((Workout a, Workout b) {
      final DateTime aDate = a.completedAt ?? a.createdAt;
      final DateTime bDate = b.completedAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });

    return workouts;
  }

  Future<Workout?> getCompletedWorkoutById(String workoutId) async {
    final dynamic raw = _databaseService.workoutsBox.get(workoutId);
    if (raw is! Map<dynamic, dynamic>) {
      return null;
    }

    return WorkoutRecord.fromMap(raw).toDomain();
  }
}
