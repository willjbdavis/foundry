import 'package:flutter/material.dart';
import 'package:foundry_annotations/foundry_annotations.dart' as foundry;
import 'package:foundry_flutter/foundry_flutter.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

import '../../core/domain/workout.dart';
import '../../core/repositories/workout_repository.dart';
import '../../core/widgets/app_animations.dart';

part 'workout_detail_view.g.dart';

class WorkoutDetailArgs extends RouteArgs {
  const WorkoutDetailArgs({required this.workoutId});

  final String workoutId;
}

@foundry.FoundryViewState()
class WorkoutDetailState with _$WorkoutDetailStateMixin {
  final bool isLoading;
  final String workoutId;
  final Workout? workout;
  final String? error;

  const WorkoutDetailState({
    this.isLoading = true,
    this.workoutId = '',
    this.workout,
    this.error,
  });
}

@foundry.FoundryViewModel()
class WorkoutDetailViewModel extends FoundryViewModel<WorkoutDetailState> {
  WorkoutDetailViewModel(this._workoutRepository) {
    emitNewState(const WorkoutDetailState());
  }

  final WorkoutRepository _workoutRepository;
  bool _initialized = false;

  Future<void> initialize(WorkoutDetailArgs args) async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    emitNewState(
      state.copyWith(isLoading: true, workoutId: args.workoutId, error: null),
    );

    try {
      final Workout? workout = await _workoutRepository.getCompletedWorkoutById(
        args.workoutId,
      );
      if (workout == null) {
        emitNewState(
          state.copyWith(isLoading: false, error: 'Workout not found.'),
        );
        return;
      }

      emitNewState(
        state.copyWith(isLoading: false, workout: workout, error: null),
      );
    } catch (_) {
      emitNewState(
        state.copyWith(
          isLoading: false,
          error: 'Could not load workout details.',
        ),
      );
    }
  }
}

@foundry.FoundryView(
  route: '/history/detail',
  args: WorkoutDetailArgs,
  deepLink: '/history/:workoutId',
)
class WorkoutDetailView
    extends FoundryView<WorkoutDetailViewModel, WorkoutDetailState> {
  const WorkoutDetailView({required this.args, super.key});

  final WorkoutDetailArgs args;

  String _formatDate(DateTime date) {
    final DateTime local = date.toLocal();
    final String mm = local.month.toString().padLeft(2, '0');
    final String dd = local.day.toString().padLeft(2, '0');
    return '${local.year}-$mm-$dd';
  }

  @override
  Widget buildWithState(
    BuildContext context,
    WorkoutDetailState? oldState,
    WorkoutDetailState state,
  ) {
    final WorkoutDetailViewModel viewModel = FoundryScope.of(
      context,
    ).resolve<WorkoutDetailViewModel>();

    if (oldState == null) {
      viewModel.initialize(args);
    }

    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int totalExercises = state.workout?.exercises.length ?? 0;
    final int totalSets =
        state.workout?.exercises.fold<int>(
          0,
          (int p, e) => p + e.sets.length,
        ) ??
        0;

    return Scaffold(
      appBar: AppBar(title: Text(state.workout?.title ?? 'Workout')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.workout == null
          ? AppEmptyState(
              icon: Icons.error_outline,
              title: state.error ?? 'Workout not found',
            )
          : ScreenFadeIn(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(
                                  state.workout!.completedAt ??
                                      state.workout!.date,
                                ),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                          if (state.workout!.notes.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 8),
                            Text(
                              state.workout!.notes,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Row(
                            children: <Widget>[
                              _StatPill(
                                icon: Icons.fitness_center_outlined,
                                label:
                                    '$totalExercises exercise${totalExercises == 1 ? '' : 's'}',
                                scheme: scheme,
                              ),
                              const SizedBox(width: 8),
                              _StatPill(
                                icon: Icons.repeat_outlined,
                                label:
                                    '$totalSets set${totalSets == 1 ? '' : 's'}',
                                scheme: scheme,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Exercises',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  for (
                    int i = 0;
                    i < state.workout!.exercises.length;
                    i++
                  ) ...<Widget>[
                    StaggeredFadeSlide(
                      index: i.clamp(0, 5),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        state.workout!.exercises[i].displayName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        color: scheme.tertiaryContainer,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        child: Text(
                                          '${state.workout!.exercises[i].sets.length} sets',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: scheme.onTertiaryContainer,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (state.workout!.exercises[i].sets.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'No sets logged',
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                else ...<Widget>[
                                  const SizedBox(height: 10),
                                  for (
                                    int j = 0;
                                    j < state.workout!.exercises[i].sets.length;
                                    j++
                                  )
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: <Widget>[
                                          DecoratedBox(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              color: scheme.primaryContainer
                                                  .withValues(alpha: 0.7),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 2,
                                                  ),
                                              child: Text(
                                                '${j + 1}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      scheme.onPrimaryContainer,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            '${state.workout!.exercises[i].sets[j].reps} reps',
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            '${state.workout!.exercises[i].sets[j].weight} kg',
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.scheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.secondaryContainer,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: scheme.onSecondaryContainer),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
