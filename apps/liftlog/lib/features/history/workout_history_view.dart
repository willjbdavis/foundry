import 'package:flutter/material.dart';
import 'package:foundry_annotations/foundry_annotations.dart' as foundry;
import 'package:foundry_flutter/foundry_flutter.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

import '../../core/domain/workout.dart';
import '../../core/repositories/workout_repository.dart';
import '../../core/widgets/app_animations.dart';
import 'workout_detail_view.dart';

part 'workout_history_view.g.dart';

@foundry.FoundryViewState()
class WorkoutHistoryState with _$WorkoutHistoryStateMixin {
  final bool isLoading;
  final String searchQuery;
  final List<Workout> workouts;
  final String? error;

  const WorkoutHistoryState({
    this.isLoading = false,
    this.searchQuery = '',
    this.workouts = const <Workout>[],
    this.error,
  });
}

@foundry.FoundryViewModel()
class WorkoutHistoryViewModel extends FoundryViewModel<WorkoutHistoryState> {
  WorkoutHistoryViewModel(this._workoutRepository) {
    emitNewState(const WorkoutHistoryState());
  }

  final WorkoutRepository _workoutRepository;

  @override
  Future<void> onInit() async {
    await refreshWorkouts();
  }

  Future<void> refreshWorkouts() async {
    emitNewState(state.copyWith(isLoading: true, error: null));
    try {
      final List<Workout> workouts = await _workoutRepository
          .listCompletedWorkouts();
      emitNewState(
        state.copyWith(isLoading: false, workouts: workouts, error: null),
      );
    } catch (_) {
      emitNewState(
        state.copyWith(
          isLoading: false,
          error: 'Could not load workout history.',
        ),
      );
    }
  }

  void updateSearchQuery(String query) {
    emitNewState(state.copyWith(searchQuery: query));
  }
}

@foundry.FoundryView(route: '/history', deepLink: '/history')
class WorkoutHistoryView
    extends FoundryView<WorkoutHistoryViewModel, WorkoutHistoryState> {
  const WorkoutHistoryView({super.key});

  String _formatDate(DateTime date) {
    final DateTime local = date.toLocal();
    final String mm = local.month.toString().padLeft(2, '0');
    final String dd = local.day.toString().padLeft(2, '0');
    return '${local.year}-$mm-$dd';
  }

  List<Workout> _filtered(List<Workout> workouts, String search) {
    final String query = search.trim().toLowerCase();
    if (query.isEmpty) {
      return workouts;
    }

    return workouts.where((Workout workout) {
      return workout.title.toLowerCase().contains(query) ||
          workout.notes.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget buildWithState(
    BuildContext context,
    WorkoutHistoryState? oldState,
    WorkoutHistoryState state,
  ) {
    final WorkoutHistoryViewModel viewModel = FoundryScope.of(
      context,
    ).resolve<WorkoutHistoryViewModel>();
    final List<Workout> visible = _filtered(state.workouts, state.searchQuery);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchField(
              hintText: 'Search history',
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
                : visible.isEmpty
                ? AppEmptyState(
                    icon: state.searchQuery.trim().isNotEmpty
                        ? Icons.search_off_outlined
                        : Icons.history_outlined,
                    title: state.searchQuery.trim().isNotEmpty
                        ? 'No results for "${state.searchQuery}"'
                        : 'No workouts yet',
                    subtitle: state.searchQuery.trim().isEmpty
                        ? 'Complete a session to start\nbuilding your history.'
                        : null,
                  )
                : RefreshIndicator(
                    onRefresh: viewModel.refreshWorkouts,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: visible.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Workout workout = visible[index];
                        final int totalSets = workout.exercises.fold<int>(
                          0,
                          (int prev, exercise) => prev + exercise.sets.length,
                        );
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
                                  backgroundColor: scheme.primaryContainer,
                                  child: Icon(
                                    Icons.fitness_center,
                                    size: 18,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ),
                                title: Text(workout.title),
                                subtitle: Text(
                                  '${_formatDate(workout.completedAt ?? workout.date)} · '
                                  '${workout.exercises.length} exercise${workout.exercises.length == 1 ? '' : 's'} · '
                                  '$totalSets set${totalSets == 1 ? '' : 's'}',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () =>
                                    FoundryNavigation.instance.pushDefault(
                                      WorkoutDetailViewRoute(
                                        WorkoutDetailArgs(
                                          workoutId: workout.id,
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
