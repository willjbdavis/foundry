import 'package:flutter/material.dart';
import 'package:foundry_annotations/foundry_annotations.dart' as foundry;
import 'package:foundry_flutter/foundry_flutter.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

import '../../core/domain/workout.dart';
import '../../core/models/workout_session_model.dart';

part 'workout_summary_view.g.dart';

class WorkoutSummaryArgs extends RouteArgs {
  const WorkoutSummaryArgs({required this.draftId});

  final String draftId;
}

@foundry.FoundryViewState()
class WorkoutSummaryState with _$WorkoutSummaryStateMixin {
  final bool isLoading;
  final bool isSaving;
  final int totalExercises;
  final int totalSets;
  final String? error;

  const WorkoutSummaryState({
    this.isLoading = false,
    this.isSaving = false,
    this.totalExercises = 0,
    this.totalSets = 0,
    this.title = 'Workout',
    this.draftId = '',
    this.error,
  });

  final String title;
  final String draftId;
}

@foundry.FoundryViewModel()
class WorkoutSummaryViewModel extends FoundryViewModel<WorkoutSummaryState> {
  WorkoutSummaryViewModel(this._sessionModel) {
    emitNewState(const WorkoutSummaryState());
  }

  final WorkoutSessionModel _sessionModel;

  void _onSessionStateChanged(WorkoutSessionState sessionState) {
    final Workout? draft = sessionState.activeDraft;
    final int totalSets = draft == null
        ? 0
        : draft.exercises.fold<int>(
            0,
            (int prev, exercise) => prev + exercise.sets.length,
          );

    emitNewState(
      WorkoutSummaryState(
        isLoading: sessionState.isLoading,
        isSaving: sessionState.isSaving,
        totalExercises: draft?.exercises.length ?? 0,
        totalSets: totalSets,
        title: draft?.title ?? 'Workout',
        draftId: draft?.id ?? '',
        error: sessionState.error,
      ),
    );
  }

  @override
  Future<void> onInit() async {
    _sessionModel.subscribe(_onSessionStateChanged);
    _onSessionStateChanged(_sessionModel.state);
  }

  @override
  Future<void> onDispose() async {
    _sessionModel.unsubscribe(_onSessionStateChanged);
  }

  Future<bool> finalize() async {
    final Workout? workout = await _sessionModel.finalizeActiveDraft();
    return workout != null;
  }
}

@foundry.FoundryView(route: '/workout/summary', args: WorkoutSummaryArgs)
class WorkoutSummaryView
    extends FoundryView<WorkoutSummaryViewModel, WorkoutSummaryState> {
  const WorkoutSummaryView({required this.args, super.key});

  final WorkoutSummaryArgs args;

  @override
  Widget buildWithState(
    BuildContext context,
    WorkoutSummaryState? oldState,
    WorkoutSummaryState state,
  ) {
    final WorkoutSummaryViewModel viewModel = FoundryScope.of(
      context,
    ).resolve<WorkoutSummaryViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Summary')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(state.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Draft ID: ${args.draftId}'),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('Exercises'),
              trailing: Text('${state.totalExercises}'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Total Sets'),
              trailing: Text('${state.totalSets}'),
            ),
          ),
          if (state.error != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              state.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: state.isSaving
                ? null
                : () async {
                    final bool ok = await viewModel.finalize();
                    if (ok && context.mounted) {
                      FoundryNavigation.instance.popToRootDefault();
                    }
                  },
            icon: const Icon(Icons.check_circle_outline),
            label: state.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Complete Workout'),
          ),
        ],
      ),
    );
  }
}
