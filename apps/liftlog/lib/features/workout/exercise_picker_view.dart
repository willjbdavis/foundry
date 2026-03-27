import 'package:flutter/material.dart';
import 'package:foundry_annotations/foundry_annotations.dart' as foundry;
import 'package:foundry_flutter/foundry_flutter.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

import '../../core/domain/exercise_definition.dart';
import '../../core/models/workout_session_model.dart';
import '../../core/repositories/exercise_repository.dart';
import '../exercises/exercise_editor_view.dart';
import 'exercise_log_view.dart';
import '../../core/widgets/app_animations.dart';

part 'exercise_picker_view.g.dart';

class ExercisePickerArgs extends RouteArgs {
  const ExercisePickerArgs({
    required this.draftId,
    this.excludeExerciseIds = const <String>[],
  });

  final String draftId;
  final List<String> excludeExerciseIds;
}

@foundry.FoundryViewState()
class ExercisePickerState with _$ExercisePickerStateMixin {
  final bool isLoading;
  final String searchQuery;
  final String? selectedExerciseId;
  final List<ExerciseDefinition> exercises;
  final String? error;

  const ExercisePickerState({
    this.isLoading = false,
    this.searchQuery = '',
    this.selectedExerciseId,
    this.exercises = const <ExerciseDefinition>[],
    this.error,
  });
}

@foundry.FoundryViewModel()
class ExercisePickerViewModel extends FoundryViewModel<ExercisePickerState> {
  ExercisePickerViewModel(this._sessionModel, this._exerciseRepository) {
    emitNewState(const ExercisePickerState());
  }

  final WorkoutSessionModel _sessionModel;
  final ExerciseRepository _exerciseRepository;

  Future<void> initialize(ExercisePickerArgs args) async {
    emitNewState(state.copyWith(isLoading: true, error: null));
    try {
      final List<ExerciseDefinition> all = await _exerciseRepository
          .listExercises();
      final List<ExerciseDefinition> filtered = all
          .where(
            (ExerciseDefinition e) => !args.excludeExerciseIds.contains(e.id),
          )
          .toList();

      emitNewState(
        state.copyWith(isLoading: false, exercises: filtered, error: null),
      );
    } catch (_) {
      emitNewState(
        state.copyWith(isLoading: false, error: 'Could not load exercises.'),
      );
    }
  }

  void updateSearchQuery(String value) {
    emitNewState(state.copyWith(searchQuery: value));
  }

  Future<bool> selectExercise(ExerciseDefinition exercise) async {
    final updated = await _sessionModel.addExercise(
      exerciseId: exercise.id,
      displayName: exercise.name,
    );
    if (updated == null) {
      emitNewState(
        state.copyWith(
          error: _sessionModel.state.error ?? 'Could not add exercise.',
        ),
      );
      return false;
    }

    emitNewState(state.copyWith(selectedExerciseId: exercise.id, error: null));
    return true;
  }
}

@foundry.FoundryView(route: '/workout/pick-exercise', args: ExercisePickerArgs)
class ExercisePickerView
    extends FoundryView<ExercisePickerViewModel, ExercisePickerState> {
  const ExercisePickerView({required this.args, super.key});

  final ExercisePickerArgs args;

  List<ExerciseDefinition> _filteredExercises(ExercisePickerState state) {
    final String query = state.searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return state.exercises;
    }

    return state.exercises.where((ExerciseDefinition e) {
      return e.name.toLowerCase().contains(query) ||
          e.description.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget buildWithState(
    BuildContext context,
    ExercisePickerState? oldState,
    ExercisePickerState state,
  ) {
    final ExercisePickerViewModel viewModel = FoundryScope.of(
      context,
    ).resolve<ExercisePickerViewModel>();

    if (oldState == null) {
      viewModel.initialize(args);
    }

    final List<ExerciseDefinition> visible = _filteredExercises(state);

    return Scaffold(
      appBar: AppBar(title: const Text('Pick Exercise')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await FoundryNavigation.instance.pushDefault(
            const ExerciseEditorViewRoute(ExerciseEditorArgs()),
          );
          if (context.mounted) {
            await viewModel.initialize(args);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Exercise'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchField(
              hintText: 'Search exercises',
              onChanged: viewModel.updateSearchQuery,
            ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                state.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : visible.isEmpty
                ? const Center(child: Text('No exercises available.'))
                : ListView.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, index) => const Divider(height: 0),
                    itemBuilder: (BuildContext context, int index) {
                      final ExerciseDefinition exercise = visible[index];
                      return ListTile(
                        title: Text(exercise.name),
                        subtitle: exercise.description.isEmpty
                            ? null
                            : Text(exercise.description),
                        onTap: () async {
                          final bool ok = await viewModel.selectExercise(
                            exercise,
                          );
                          if (!ok || !context.mounted) {
                            return;
                          }
                          await FoundryNavigation.instance.pushDefault(
                            ExerciseLogViewRoute(
                              ExerciseLogArgs(draftId: args.draftId),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
