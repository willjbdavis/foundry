import 'package:flutter/material.dart';
import 'package:foundry_annotations/foundry_annotations.dart' as foundry;
import 'package:foundry_flutter/foundry_flutter.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

import '../../core/domain/logged_exercise.dart';
import '../../core/domain/logged_set.dart';
import '../../core/domain/workout.dart';
import '../../core/models/rest_timer_service.dart';
import '../../core/models/workout_session_model.dart';
import '../../core/widgets/app_animations.dart';
import 'exercise_picker_view.dart';
import 'workout_summary_view.dart';

part 'exercise_log_view.g.dart';

const int _defaultExerciseLogTimerSeconds = 90;

class ExerciseLogArgs extends RouteArgs {
  const ExerciseLogArgs({required this.draftId, this.initialExerciseIndex = 0});

  final String draftId;
  final int initialExerciseIndex;
}

@foundry.FoundryViewState()
class ExerciseLogState with _$ExerciseLogStateMixin {
  final bool isLoading;
  final bool isSaving;
  final String draftTitle;
  final String draftId;
  final List<LoggedExercise> exercises;
  final int selectedExerciseIndex;
  final int timerRemainingSeconds;
  final int timerTotalSeconds;
  final bool isTimerRunning;
  final bool showRestFinishedBanner;
  final String repsInput;
  final String weightInput;
  final String? error;

  const ExerciseLogState({
    this.isLoading = false,
    this.isSaving = false,
    this.draftTitle = 'Workout',
    this.draftId = '',
    this.exercises = const <LoggedExercise>[],
    this.selectedExerciseIndex = 0,
    this.timerRemainingSeconds = _defaultExerciseLogTimerSeconds,
    this.timerTotalSeconds = _defaultExerciseLogTimerSeconds,
    this.isTimerRunning = false,
    this.showRestFinishedBanner = false,
    this.repsInput = '8',
    this.weightInput = '0',
    this.error,
  });
}

@foundry.FoundryViewModel()
class ExerciseLogViewModel extends FoundryViewModel<ExerciseLogState> {
  ExerciseLogViewModel(this._sessionModel, this._timerService) {
    emitNewState(const ExerciseLogState());
  }

  final WorkoutSessionModel _sessionModel;
  final RestTimerService _timerService;

  void _onSessionChanged(WorkoutSessionState session) {
    final Workout? draft = session.activeDraft;
    final int selected = state.selectedExerciseIndex;
    final int maxIndex = (draft?.exercises.length ?? 1) - 1;

    emitNewState(
      state.copyWith(
        isLoading: session.isLoading,
        isSaving: session.isSaving,
        draftId: draft?.id ?? '',
        draftTitle: draft?.title ?? 'Workout',
        exercises: draft?.exercises ?? const <LoggedExercise>[],
        selectedExerciseIndex: selected.clamp(0, maxIndex < 0 ? 0 : maxIndex),
        error: session.error,
      ),
    );
  }

  void _onTimerChanged(RestTimerState timerState) {
    emitNewState(
      state.copyWith(
        timerRemainingSeconds: timerState.remainingSeconds,
        timerTotalSeconds: timerState.totalSeconds,
        isTimerRunning: timerState.isRunning,
        showRestFinishedBanner: timerState.showRestFinishedBanner,
      ),
    );
  }

  @override
  Future<void> onInit() async {
    _sessionModel.subscribe(_onSessionChanged);
    _timerService.subscribe(_onTimerChanged);
    _onSessionChanged(_sessionModel.state);
    _onTimerChanged(_timerService.state);
  }

  @override
  Future<void> onDispose() async {
    _sessionModel.unsubscribe(_onSessionChanged);
    _timerService.unsubscribe(_onTimerChanged);
  }

  void selectExercise(int index) {
    emitNewState(state.copyWith(selectedExerciseIndex: index, error: null));
  }

  void updateRepsInput(String value) {
    emitNewState(state.copyWith(repsInput: value, error: null));
  }

  void updateWeightInput(String value) {
    emitNewState(state.copyWith(weightInput: value, error: null));
  }

  Future<void> addSet() async {
    if (state.exercises.isEmpty) {
      emitNewState(state.copyWith(error: 'Add an exercise first.'));
      return;
    }

    final int? reps = int.tryParse(state.repsInput.trim());
    final double? weight = double.tryParse(state.weightInput.trim());
    if (reps == null || reps <= 0 || weight == null || weight < 0) {
      emitNewState(state.copyWith(error: 'Enter valid reps and weight.'));
      return;
    }

    final LoggedExercise selected =
        state.exercises[state.selectedExerciseIndex];
    await _sessionModel.addSet(
      exerciseId: selected.exerciseId,
      reps: reps,
      weight: weight,
    );
  }

  Future<void> removeSet(String setId) async {
    if (state.exercises.isEmpty) {
      return;
    }
    final LoggedExercise selected =
        state.exercises[state.selectedExerciseIndex];
    await _sessionModel.removeSet(
      exerciseId: selected.exerciseId,
      setId: setId,
    );
  }

  Future<void> updateSet(
    LoggedSet set, {
    required int reps,
    required double weight,
  }) async {
    if (state.exercises.isEmpty) {
      return;
    }
    final LoggedExercise selected =
        state.exercises[state.selectedExerciseIndex];
    await _sessionModel.updateSet(
      exerciseId: selected.exerciseId,
      setId: set.id,
      reps: reps,
      weight: weight,
    );
  }

  Future<void> removeCurrentExercise() async {
    if (state.exercises.isEmpty) {
      return;
    }
    final LoggedExercise selected =
        state.exercises[state.selectedExerciseIndex];
    await _sessionModel.removeExercise(selected.exerciseId);
  }

  Future<void> discardWorkout() async {
    await _sessionModel.discardActiveDraft();
  }

  void toggleTimer() {
    _timerService.dismissBanner();
    _timerService.toggleStartPause();
  }

  void restartTimer() {
    _timerService.dismissBanner();
    _timerService.restart();
  }

  void setTimerDuration(int totalSeconds) {
    _timerService.setDuration(totalSeconds);
  }

  void dismissTimerBanner() {
    _timerService.dismissBanner();
  }
}

@foundry.FoundryView(route: '/workout/log', args: ExerciseLogArgs)
class ExerciseLogView extends FoundryView<ExerciseLogViewModel, ExerciseLogState> {
  const ExerciseLogView({required this.args, super.key});

  final ExerciseLogArgs args;

  @override
  Widget buildWithState(
    BuildContext context,
    ExerciseLogState? oldState,
    ExerciseLogState state,
  ) {
    final ExerciseLogViewModel viewModel = FoundryScope.of(
      context,
    ).resolve<ExerciseLogViewModel>();

    final LoggedExercise? selectedExercise = state.exercises.isEmpty
        ? null
        : state.exercises[state.selectedExerciseIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(state.draftTitle),
        actions: <Widget>[
          IconButton(
            tooltip: 'Add exercise',
            icon: const Icon(Icons.add),
            onPressed: () async {
              await FoundryNavigation.instance.pushDefault(
                ExercisePickerViewRoute(
                  ExercisePickerArgs(draftId: args.draftId),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Finish workout',
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () async {
              await FoundryNavigation.instance.pushDefault(
                WorkoutSummaryViewRoute(
                  WorkoutSummaryArgs(draftId: args.draftId),
                ),
              );
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                FoundrySelectorBuilder<ExerciseLogState>(
                  emitter: viewModel,
                  selector:
                      (ExerciseLogState? oldState, ExerciseLogState newState) =>
                          oldState?.timerRemainingSeconds !=
                              newState.timerRemainingSeconds ||
                          oldState?.timerTotalSeconds !=
                              newState.timerTotalSeconds ||
                          oldState?.isTimerRunning != newState.isTimerRunning ||
                          oldState?.showRestFinishedBanner !=
                              newState.showRestFinishedBanner,
                  builder: (BuildContext context, ExerciseLogState state) {
                    return _RestTimerSection(
                      state: state,
                      onToggleTimer: viewModel.toggleTimer,
                      onRestartTimer: viewModel.restartTimer,
                      onDismissBanner: viewModel.dismissTimerBanner,
                      onEditDuration: () => _showTimerDurationDialog(
                        context,
                        viewModel: viewModel,
                        initialTotalSeconds: state.timerTotalSeconds,
                      ),
                    );
                  },
                ),
                if (state.exercises.isNotEmpty)
                  SizedBox(
                    height: 56,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.exercises.length,
                      itemBuilder: (BuildContext context, int index) {
                        final LoggedExercise exercise = state.exercises[index];
                        final bool selected =
                            index == state.selectedExerciseIndex;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 8,
                          ),
                          child: ChoiceChip(
                            label: Text(exercise.displayName),
                            selected: selected,
                            onSelected: (_) => viewModel.selectExercise(index),
                          ),
                        );
                      },
                    ),
                  ),
                if (selectedExercise == null)
                  const Expanded(
                    child: Center(
                      child: Text('No exercises yet. Tap + to add one.'),
                    ),
                  )
                else
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: ControlledField(
                                initialValue: state.repsInput,
                                decoration: const InputDecoration(
                                  labelText: 'Reps',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: viewModel.updateRepsInput,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ControlledField(
                                initialValue: state.weightInput,
                                decoration: const InputDecoration(
                                  labelText: 'Weight',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                onChanged: viewModel.updateWeightInput,
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: viewModel.addSet,
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sets',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (selectedExercise.sets.isEmpty)
                          const Text('No sets yet.')
                        else
                          ...selectedExercise.sets.map(
                            (LoggedSet set) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Card(
                                child: ListTile(
                                  title: Text(
                                    '${set.reps} reps x ${set.weight}',
                                  ),
                                  subtitle: Text(
                                    set.loggedAt.toLocal().toString(),
                                  ),
                                  onTap: () async {
                                    final int? reps = await _showSetEditDialog(
                                      context,
                                      title: 'Edit reps',
                                      initial: set.reps.toString(),
                                    );
                                    if (reps == null || !context.mounted) {
                                      return;
                                    }
                                    final double? weight =
                                        await _showSetEditDialogDouble(
                                          context,
                                          title: 'Edit weight',
                                          initial: set.weight.toString(),
                                        );
                                    if (weight == null) {
                                      return;
                                    }
                                    await viewModel.updateSet(
                                      set,
                                      reps: reps,
                                      weight: weight,
                                    );
                                  },
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () =>
                                        viewModel.removeSet(set.id),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: viewModel.removeCurrentExercise,
                          icon: const Icon(Icons.remove_circle_outline),
                          label: const Text('Remove Current Exercise'),
                        ),
                      ],
                    ),
                  ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      state.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  await viewModel.discardWorkout();
                  if (context.mounted) {
                    FoundryNavigation.instance.popDefault();
                  }
                },
                child: const Text('Discard'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: state.exercises.isEmpty
                    ? null
                    : () async {
                        await FoundryNavigation.instance.pushDefault(
                          WorkoutSummaryViewRoute(
                            WorkoutSummaryArgs(draftId: args.draftId),
                          ),
                        );
                      },
                child: const Text('Review & Finish'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<int?> _showSetEditDialog(
    BuildContext context, {
    required String title,
    required String initial,
  }) async {
    final TextEditingController controller = TextEditingController(
      text: initial,
    );
    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (value == null) {
      return null;
    }

    final int? parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  Future<double?> _showSetEditDialogDouble(
    BuildContext context, {
    required String title,
    required String initial,
  }) async {
    final TextEditingController controller = TextEditingController(
      text: initial,
    );
    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (value == null) {
      return null;
    }

    final double? parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return null;
    }
    return parsed;
  }

  Future<void> _showTimerDurationDialog(
    BuildContext context, {
    required ExerciseLogViewModel viewModel,
    required int initialTotalSeconds,
  }) async {
    final int initialMinutes = initialTotalSeconds ~/ 60;
    final int initialSeconds = initialTotalSeconds % 60;
    final TextEditingController minutesController = TextEditingController(
      text: initialMinutes.toString(),
    );
    final TextEditingController secondsController = TextEditingController(
      text: initialSeconds.toString().padLeft(2, '0'),
    );
    String? validationError;

    final int? totalSeconds = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (BuildContext context, void Function(VoidCallback) setState) {
                return AlertDialog(
                  title: const Text('Set rest timer'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: minutesController,
                              keyboardType: TextInputType.number,
                              autofocus: true,
                              decoration: const InputDecoration(
                                labelText: 'Minutes',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: secondsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Seconds',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Maximum 59m 59s',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      if (validationError != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          validationError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        final int? minutes = int.tryParse(
                          minutesController.text.trim(),
                        );
                        final int? seconds = int.tryParse(
                          secondsController.text.trim(),
                        );

                        if (minutes == null || seconds == null) {
                          setState(() {
                            validationError =
                                'Enter whole numbers for minutes and seconds.';
                          });
                          return;
                        }

                        if (minutes < 0 ||
                            minutes > 59 ||
                            seconds < 0 ||
                            seconds > 59) {
                          setState(() {
                            validationError =
                                'Choose a time from 0:01 to 59:59.';
                          });
                          return;
                        }

                        final int nextTotalSeconds = (minutes * 60) + seconds;
                        if (nextTotalSeconds <= 0 ||
                            nextTotalSeconds > maxRestTimerSeconds) {
                          setState(() {
                            validationError =
                                'Choose a time from 0:01 to 59:59.';
                          });
                          return;
                        }

                        Navigator.of(context).pop(nextTotalSeconds);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                );
              },
        );
      },
    );

    if (totalSeconds == null) {
      return;
    }

    viewModel.setTimerDuration(totalSeconds);
  }
}

class _RestTimerSection extends StatelessWidget {
  const _RestTimerSection({
    required this.state,
    required this.onToggleTimer,
    required this.onRestartTimer,
    required this.onDismissBanner,
    required this.onEditDuration,
  });

  final ExerciseLogState state;
  final VoidCallback onToggleTimer;
  final VoidCallback onRestartTimer;
  final VoidCallback onDismissBanner;
  final Future<void> Function() onEditDuration;

  @override
  Widget build(BuildContext context) {
    final int minutes = state.timerRemainingSeconds ~/ 60;
    final int seconds = state.timerRemainingSeconds % 60;
    final String timerText =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: <Widget>[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              final Animation<Offset> offsetAnimation = Tween<Offset>(
                begin: const Offset(0, -0.18),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offsetAnimation, child: child),
              );
            },
            child: state.showRestFinishedBanner
                ? Padding(
                    key: const ValueKey<String>('rest-finished-banner'),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Dismissible(
                      key: const ValueKey<String>('rest-finished-dismissible'),
                      direction: DismissDirection.horizontal,
                      onDismissed: (_) => onDismissBanner(),
                      child: Material(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          title: Text(
                            'Rest Finished. Start next set!',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: onDismissBanner,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(
                    key: ValueKey<String>('rest-finished-banner-hidden'),
                  ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        onDismissBanner();
                        await onEditDuration();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Rest timer',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timerText,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: state.isTimerRunning
                        ? 'Pause timer'
                        : 'Start timer',
                    onPressed: onToggleTimer,
                    icon: Icon(
                      state.isTimerRunning
                          ? Icons.pause_circle
                          : Icons.play_circle,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Restart timer',
                    onPressed: onRestartTimer,
                    icon: const Icon(Icons.replay_circle_filled),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
