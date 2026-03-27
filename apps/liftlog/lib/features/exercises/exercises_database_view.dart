import 'package:flutter/material.dart';
import 'package:foundry_annotations/foundry_annotations.dart' as foundry;
import 'package:foundry_flutter/foundry_flutter.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

import '../../core/domain/exercise_definition.dart';
import '../../core/repositories/exercise_repository.dart';
import '../../core/widgets/app_animations.dart';
import 'exercise_editor_view.dart';

part 'exercises_database_view.g.dart';

@foundry.FoundryViewState()
class ExercisesDatabaseState with _$ExercisesDatabaseStateMixin {
  final bool isLoading;
  final String searchQuery;
  final List<ExerciseDefinition> exercises;
  final String? error;

  const ExercisesDatabaseState({
    this.isLoading = false,
    this.searchQuery = '',
    this.exercises = const <ExerciseDefinition>[],
    this.error,
  });
}

@foundry.FoundryViewModel()
class ExercisesDatabaseViewModel extends FoundryViewModel<ExercisesDatabaseState> {
  ExercisesDatabaseViewModel(this._exerciseRepository) {
    emitNewState(const ExercisesDatabaseState());
  }

  final ExerciseRepository _exerciseRepository;

  @override
  Future<void> onInit() async {
    await reloadExercises();
  }

  Future<void> reloadExercises() async {
    emitNewState(state.copyWith(isLoading: true, error: null));
    try {
      final List<ExerciseDefinition> exercises = await _exerciseRepository
          .listExercises();
      emitNewState(
        state.copyWith(isLoading: false, exercises: exercises, error: null),
      );
    } catch (_) {
      emitNewState(
        state.copyWith(
          isLoading: false,
          error: 'Could not load exercises. Please try again.',
        ),
      );
    }
  }

  void updateSearchQuery(String query) {
    emitNewState(state.copyWith(searchQuery: query));
  }
}

@foundry.FoundryView(route: '/exercises', deepLink: '/exercises')
class ExercisesDatabaseView
    extends FoundryView<ExercisesDatabaseViewModel, ExercisesDatabaseState> {
  const ExercisesDatabaseView({super.key});

  List<ExerciseDefinition> _filteredExercises(ExercisesDatabaseState state) {
    final String q = state.searchQuery.trim().toLowerCase();
    if (q.isEmpty) {
      return state.exercises;
    }

    return state.exercises.where((ExerciseDefinition exercise) {
      final String name = exercise.name.toLowerCase();
      final String description = exercise.description.toLowerCase();
      return name.contains(q) || description.contains(q);
    }).toList();
  }

  @override
  Widget buildWithState(
    BuildContext context,
    ExercisesDatabaseState? oldState,
    ExercisesDatabaseState state,
  ) {
    final ExercisesDatabaseViewModel viewModel = FoundryScope.of(
      context,
    ).resolve<ExercisesDatabaseViewModel>();
    final List<ExerciseDefinition> filtered = _filteredExercises(state);

    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await FoundryNavigation.instance.pushDefault(
            const ExerciseEditorViewRoute(ExerciseEditorArgs()),
          );
          if (context.mounted) {
            await viewModel.reloadExercises();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Exercise'),
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
              child: Text(state.error!, style: TextStyle(color: scheme.error)),
            ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? AppEmptyState(
                    icon: state.searchQuery.trim().isNotEmpty
                        ? Icons.search_off_outlined
                        : Icons.fitness_center_outlined,
                    title: state.searchQuery.trim().isNotEmpty
                        ? 'No results for "${state.searchQuery}"'
                        : 'No exercises yet',
                    subtitle: state.searchQuery.trim().isEmpty
                        ? 'Tap + to add your first exercise.'
                        : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ExerciseDefinition exercise = filtered[index];
                      return StaggeredFadeSlide(
                        index: index.clamp(0, 7),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: scheme.secondaryContainer,
                                child: Text(
                                  exercise.name.isNotEmpty
                                      ? exercise.name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                              title: Text(exercise.name),
                              subtitle: Text(
                                exercise.description.isEmpty
                                    ? 'No description'
                                    : exercise.description,
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                await FoundryNavigation.instance.pushDefault(
                                  ExerciseEditorViewRoute(
                                    ExerciseEditorArgs(exerciseId: exercise.id),
                                  ),
                                );
                                if (context.mounted) {
                                  await viewModel.reloadExercises();
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
