import 'package:flutter/material.dart';
import 'package:foundry_annotations/foundry_annotations.dart' as foundry;
import 'package:foundry_flutter/foundry_flutter.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

import '../../core/domain/workout.dart';
import '../../core/models/workout_session_model.dart';
import '../../core/repositories/workout_repository.dart';
import '../../core/widgets/app_animations.dart';
import '../history/workout_detail_view.dart';
import '../workout/exercise_log_view.dart';
import '../workout/workout_session_setup_view.dart';

part 'home_view.g.dart';

@foundry.FoundryViewState()
class HomeState with _$HomeStateMixin {
  final bool isLoading;
  final bool hasActiveWorkout;
  final String? activeWorkoutTitle;
  final List<Workout> recentWorkouts;
  final String? error;

  const HomeState({
    this.isLoading = false,
    this.hasActiveWorkout = false,
    this.activeWorkoutTitle,
    this.recentWorkouts = const <Workout>[],
    this.error,
  });
}

@foundry.FoundryViewModel()
class HomeViewModel extends FoundryViewModel<HomeState> {
  HomeViewModel(this._sessionModel, this._workoutRepository) {
    emitNewState(const HomeState());
  }

  final WorkoutSessionModel _sessionModel;
  final WorkoutRepository _workoutRepository;

  String? get currentDraftId => _sessionModel.state.activeDraft?.id;

  void _onSessionChanged(WorkoutSessionState sessionState) {
    emitNewState(
      state.copyWith(
        isLoading: sessionState.isLoading,
        hasActiveWorkout: sessionState.activeDraft != null,
        activeWorkoutTitle: sessionState.activeDraft?.title,
        error: sessionState.error,
      ),
    );
  }

  Future<void> refreshRecentWorkouts() async {
    try {
      final List<Workout> all = await _workoutRepository
          .listCompletedWorkouts();
      emitNewState(
        state.copyWith(
          recentWorkouts: all.take(5).toList(),
          error: state.error,
        ),
      );
    } catch (_) {
      emitNewState(state.copyWith(error: 'Could not load recent workouts.'));
    }
  }

  @override
  Future<void> onInit() async {
    _sessionModel.subscribe(_onSessionChanged);
    _onSessionChanged(_sessionModel.state);
    await refreshRecentWorkouts();
  }

  @override
  Future<void> onDispose() async {
    _sessionModel.unsubscribe(_onSessionChanged);
  }
}

@foundry.FoundryView(route: '/home', deepLink: '/home')
class HomeView extends FoundryView<HomeViewModel, HomeState> {
  const HomeView({super.key});

  String _formatDate(DateTime date) {
    final DateTime local = date.toLocal();
    final String mm = local.month.toString().padLeft(2, '0');
    final String dd = local.day.toString().padLeft(2, '0');
    return '${local.year}-$mm-$dd';
  }

  @override
  Widget buildWithState(
    BuildContext context,
    HomeState? oldState,
    HomeState state,
  ) {
    final HomeViewModel viewModel = FoundryScope.of(
      context,
    ).resolve<HomeViewModel>();

    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Lift Log'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[scheme.primary, scheme.tertiary],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Today',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.hasActiveWorkout
                        ? 'Your current session is waiting. Pick up where you left off.'
                        : 'Build momentum. Start a focused session now.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.onPrimary,
                      foregroundColor: scheme.primary,
                    ),
                    onPressed: state.isLoading
                        ? null
                        : () async {
                            final String? draftId = viewModel.currentDraftId;

                            if (draftId != null) {
                              await FoundryNavigation.instance.pushDefault(
                                ExerciseLogViewRoute(
                                  ExerciseLogArgs(draftId: draftId),
                                ),
                              );
                              if (context.mounted) {
                                await viewModel.refreshRecentWorkouts();
                              }
                              return;
                            }

                            await FoundryNavigation.instance.pushDefault(
                              const WorkoutSessionSetupViewRoute(
                                WorkoutSessionSetupArgs(),
                              ),
                            );
                            if (context.mounted) {
                              await viewModel.refreshRecentWorkouts();
                            }
                          },
                    icon: Icon(
                      state.hasActiveWorkout
                          ? Icons.play_circle_fill
                          : Icons.add_circle,
                    ),
                    label: Text(
                      state.hasActiveWorkout
                          ? 'Resume Workout'
                          : 'Start Workout',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.hasActiveWorkout) ...<Widget>[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.timelapse,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(state.activeWorkoutTitle ?? 'Untitled workout'),
                subtitle: const Text('Draft in progress'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ],
          if (state.error != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              state.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Text(
                'Recent Workouts',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: scheme.secondaryContainer,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    '${state.recentWorkouts.length}',
                    style: TextStyle(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.recentWorkouts.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: AppEmptyState(
                icon: Icons.history_outlined,
                title: 'No completed workouts yet',
                subtitle: 'Finish a workout to see it here.',
              ),
            )
          else
            for (final MapEntry<int, Workout> entry
                in state.recentWorkouts.asMap().entries) ...<Widget>[
              StaggeredFadeSlide(
                index: entry.key.clamp(0, 5),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.fitness_center_outlined,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(entry.value.title),
                      subtitle: Text(
                        '${_formatDate(entry.value.completedAt ?? entry.value.date)} • '
                        '${entry.value.exercises.length} exercises • '
                        '${entry.value.exercises.fold<int>(0, (int p, e) => p + e.sets.length)} sets',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => FoundryNavigation.instance.pushDefault(
                        WorkoutDetailViewRoute(
                          WorkoutDetailArgs(workoutId: entry.value.id),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }
}
