import 'package:foundry_annotations/foundry_annotations.dart' as foundry;
import 'package:foundry_core/foundry_core.dart';

import '../domain/logged_exercise.dart';
import '../domain/logged_set.dart';
import '../domain/workout.dart';
import '../repositories/workout_repository.dart';

part 'workout_session_model.g.dart';

@foundry.FoundryModelState()
class WorkoutSessionState with _$WorkoutSessionStateMixin {
  const WorkoutSessionState({
    this.isLoading = false,
    this.isSaving = false,
    this.activeDraft,
    this.error,
  });

  final bool isLoading;
  final bool isSaving;
  final Workout? activeDraft;
  final String? error;
}

@foundry.FoundryModel(stateful: true)
class WorkoutSessionModel extends StatefulModel<WorkoutSessionState> {
  WorkoutSessionModel(this._workoutRepository) {
    emitNewState(const WorkoutSessionState(isLoading: true));
  }

  final WorkoutRepository _workoutRepository;

  @override
  Future<void> initialize() async {
    await loadActiveDraft();
  }

  Future<void> loadActiveDraft() async {
    emitNewState(state.copyWith(isLoading: true, error: null));
    try {
      final Workout? activeDraft = await _workoutRepository.loadActiveDraft();
      emitNewState(
        state.copyWith(isLoading: false, activeDraft: activeDraft, error: null),
      );
    } catch (_) {
      emitNewState(
        state.copyWith(
          isLoading: false,
          error: 'Could not load active workout.',
        ),
      );
    }
  }

  Future<Workout?> createDraft({
    String title = 'Workout',
    DateTime? date,
    String notes = '',
  }) async {
    emitNewState(state.copyWith(isSaving: true, error: null));
    try {
      final Workout created = await _workoutRepository.createDraft(
        title: title,
        date: date ?? DateTime.now(),
        notes: notes,
      );
      emitNewState(
        state.copyWith(isSaving: false, activeDraft: created, error: null),
      );
      return created;
    } on WorkoutRepositoryException catch (e) {
      emitNewState(state.copyWith(isSaving: false, error: e.message));
      return state.activeDraft;
    } catch (_) {
      emitNewState(
        state.copyWith(
          isSaving: false,
          error: 'Could not create workout draft.',
        ),
      );
      return null;
    }
  }

  Future<Workout?> updateDraft(Workout updatedDraft) async {
    emitNewState(state.copyWith(isSaving: true, error: null));
    try {
      final Workout saved = await _workoutRepository.saveDraft(updatedDraft);
      emitNewState(state.copyWith(isSaving: false, activeDraft: saved));
      return saved;
    } on WorkoutRepositoryException catch (e) {
      emitNewState(state.copyWith(isSaving: false, error: e.message));
      return null;
    } catch (_) {
      emitNewState(
        state.copyWith(isSaving: false, error: 'Could not save workout draft.'),
      );
      return null;
    }
  }

  Future<Workout?> updateTitle(String title) async {
    final Workout? draft = state.activeDraft;
    if (draft == null) {
      emitNewState(state.copyWith(error: 'No active draft to update.'));
      return null;
    }
    return updateDraft(draft.copyWith(title: title));
  }

  Future<Workout?> updateNotes(String notes) async {
    final Workout? draft = state.activeDraft;
    if (draft == null) {
      emitNewState(state.copyWith(error: 'No active draft to update.'));
      return null;
    }
    return updateDraft(draft.copyWith(notes: notes));
  }

  Future<Workout?> updateDate(DateTime date) async {
    final Workout? draft = state.activeDraft;
    if (draft == null) {
      emitNewState(state.copyWith(error: 'No active draft to update.'));
      return null;
    }
    return updateDraft(draft.copyWith(date: date));
  }

  Future<Workout?> addExercise({
    required String exerciseId,
    required String displayName,
  }) async {
    final Workout? draft = state.activeDraft;
    if (draft == null) {
      emitNewState(state.copyWith(error: 'No active draft to update.'));
      return null;
    }

    final bool alreadyExists = draft.exercises.any(
      (LoggedExercise e) => e.exerciseId == exerciseId,
    );
    if (alreadyExists) {
      emitNewState(state.copyWith(error: 'Exercise already in workout.'));
      return draft;
    }

    final LoggedExercise added = LoggedExercise(
      exerciseId: exerciseId,
      displayName: displayName,
      notes: '',
      sortOrder: draft.exercises.length,
    );

    return updateDraft(
      draft.copyWith(exercises: <LoggedExercise>[...draft.exercises, added]),
    );
  }

  Future<Workout?> removeExercise(String exerciseId) async {
    final Workout? draft = state.activeDraft;
    if (draft == null) {
      emitNewState(state.copyWith(error: 'No active draft to update.'));
      return null;
    }

    final List<LoggedExercise> filtered = draft.exercises
        .where((LoggedExercise e) => e.exerciseId != exerciseId)
        .toList();

    final List<LoggedExercise> reindexed = filtered
        .asMap()
        .entries
        .map(
          (MapEntry<int, LoggedExercise> entry) =>
              entry.value.copyWith(sortOrder: entry.key),
        )
        .toList();

    return updateDraft(draft.copyWith(exercises: reindexed));
  }

  Future<Workout?> addSet({
    required String exerciseId,
    required int reps,
    required double weight,
    String? setType,
  }) async {
    final Workout? draft = state.activeDraft;
    if (draft == null) {
      emitNewState(state.copyWith(error: 'No active draft to update.'));
      return null;
    }

    final int index = draft.exercises.indexWhere(
      (LoggedExercise e) => e.exerciseId == exerciseId,
    );
    if (index < 0) {
      emitNewState(state.copyWith(error: 'Exercise is not in this draft.'));
      return null;
    }

    final LoggedSet newSet = LoggedSet(
      id: DateTime.now().toUtc().microsecondsSinceEpoch.toString(),
      reps: reps,
      weight: weight,
      setType: setType,
      loggedAt: DateTime.now().toUtc(),
    );

    final LoggedExercise target = draft.exercises[index];
    final LoggedExercise updatedExercise = target.copyWith(
      sets: <LoggedSet>[...target.sets, newSet],
    );

    final List<LoggedExercise> updatedExercises = List<LoggedExercise>.from(
      draft.exercises,
    );
    updatedExercises[index] = updatedExercise;

    return updateDraft(draft.copyWith(exercises: updatedExercises));
  }

  Future<Workout?> updateSet({
    required String exerciseId,
    required String setId,
    required int reps,
    required double weight,
    String? setType,
  }) async {
    final Workout? draft = state.activeDraft;
    if (draft == null) {
      emitNewState(state.copyWith(error: 'No active draft to update.'));
      return null;
    }

    final int exerciseIndex = draft.exercises.indexWhere(
      (LoggedExercise e) => e.exerciseId == exerciseId,
    );
    if (exerciseIndex < 0) {
      emitNewState(state.copyWith(error: 'Exercise is not in this draft.'));
      return null;
    }

    final LoggedExercise targetExercise = draft.exercises[exerciseIndex];
    final int setIndex = targetExercise.sets.indexWhere(
      (LoggedSet s) => s.id == setId,
    );
    if (setIndex < 0) {
      emitNewState(state.copyWith(error: 'Set not found.'));
      return null;
    }

    final List<LoggedSet> updatedSets = List<LoggedSet>.from(
      targetExercise.sets,
    );
    final LoggedSet existingSet = updatedSets[setIndex];
    updatedSets[setIndex] = existingSet.copyWith(
      reps: reps,
      weight: weight,
      setType: setType,
      loggedAt: DateTime.now().toUtc(),
    );

    final List<LoggedExercise> updatedExercises = List<LoggedExercise>.from(
      draft.exercises,
    );
    updatedExercises[exerciseIndex] = targetExercise.copyWith(
      sets: updatedSets,
    );

    return updateDraft(draft.copyWith(exercises: updatedExercises));
  }

  Future<Workout?> removeSet({
    required String exerciseId,
    required String setId,
  }) async {
    final Workout? draft = state.activeDraft;
    if (draft == null) {
      emitNewState(state.copyWith(error: 'No active draft to update.'));
      return null;
    }

    final int exerciseIndex = draft.exercises.indexWhere(
      (LoggedExercise e) => e.exerciseId == exerciseId,
    );
    if (exerciseIndex < 0) {
      emitNewState(state.copyWith(error: 'Exercise is not in this draft.'));
      return null;
    }

    final LoggedExercise targetExercise = draft.exercises[exerciseIndex];
    final List<LoggedSet> updatedSets = targetExercise.sets
        .where((LoggedSet s) => s.id != setId)
        .toList();

    final List<LoggedExercise> updatedExercises = List<LoggedExercise>.from(
      draft.exercises,
    );
    updatedExercises[exerciseIndex] = targetExercise.copyWith(
      sets: updatedSets,
    );

    return updateDraft(draft.copyWith(exercises: updatedExercises));
  }

  Future<Workout?> discardActiveDraft() async {
    emitNewState(state.copyWith(isSaving: true, error: null));
    try {
      await _workoutRepository.discardDraft();
      emitNewState(
        state.copyWith(isSaving: false, activeDraft: null, error: null),
      );
      return null;
    } catch (_) {
      emitNewState(
        state.copyWith(
          isSaving: false,
          error: 'Could not discard workout draft.',
        ),
      );
      return state.activeDraft;
    }
  }

  Future<Workout?> finalizeActiveDraft() async {
    emitNewState(state.copyWith(isSaving: true, error: null));
    try {
      final Workout completed = await _workoutRepository.finalizeDraft();
      emitNewState(
        state.copyWith(isSaving: false, activeDraft: null, error: null),
      );
      return completed;
    } on WorkoutRepositoryException catch (e) {
      emitNewState(state.copyWith(isSaving: false, error: e.message));
      return null;
    } catch (_) {
      emitNewState(
        state.copyWith(isSaving: false, error: 'Could not finalize workout.'),
      );
      return null;
    }
  }
}
