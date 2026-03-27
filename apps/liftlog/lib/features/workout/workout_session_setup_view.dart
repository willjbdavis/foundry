import 'package:flutter/material.dart';
import 'package:foundry_annotations/foundry_annotations.dart' as foundry;
import 'package:foundry_flutter/foundry_flutter.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

import '../../core/models/workout_session_model.dart';
import '../../core/domain/workout.dart';
import 'exercise_picker_view.dart';
import '../../core/widgets/app_animations.dart';

part 'workout_session_setup_view.g.dart';

class WorkoutSessionSetupArgs extends RouteArgs {
  const WorkoutSessionSetupArgs({this.draftId, this.isResume = false});

  final String? draftId;
  final bool isResume;
}

@foundry.FoundryViewState()
class WorkoutSessionSetupState with _$WorkoutSessionSetupStateMixin {
  final bool isLoading;
  final bool isSaving;
  final String title;
  final DateTime date;
  final String notes;
  final String? error;

  WorkoutSessionSetupState({
    this.isLoading = false,
    this.isSaving = false,
    this.title = '',
    DateTime? date,
    this.notes = '',
    this.error,
  }) : date = date ?? DateTime.now();
}

@foundry.FoundryViewModel()
class WorkoutSessionSetupViewModel
    extends FoundryViewModel<WorkoutSessionSetupState> {
  WorkoutSessionSetupViewModel(this._sessionModel) {
    emitNewState(WorkoutSessionSetupState());
  }

  final WorkoutSessionModel _sessionModel;
  bool _initialized = false;

  Future<void> initialize(WorkoutSessionSetupArgs args) async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    final Workout? existing = _sessionModel.state.activeDraft;
    if (existing == null) {
      return;
    }

    if (args.draftId != null && args.draftId != existing.id) {
      emitNewState(
        state.copyWith(error: 'Another workout draft is currently active.'),
      );
      return;
    }

    emitNewState(
      state.copyWith(
        title: existing.title,
        date: existing.date,
        notes: existing.notes,
      ),
    );
  }

  void updateTitle(String value) {
    emitNewState(state.copyWith(title: value, error: null));
  }

  void updateNotes(String value) {
    emitNewState(state.copyWith(notes: value, error: null));
  }

  Future<void> pickDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year - 2);
    final DateTime lastDate = DateTime(now.year + 2);

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: state.date,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selected != null) {
      emitNewState(state.copyWith(date: selected, error: null));
    }
  }

  Future<String?> saveAndContinue() async {
    emitNewState(state.copyWith(isSaving: true, error: null));

    try {
      final Workout? existing = _sessionModel.state.activeDraft;
      Workout? draft;

      if (existing == null) {
        draft = await _sessionModel.createDraft(
          title: state.title,
          date: state.date,
          notes: state.notes,
        );
      } else {
        draft = await _sessionModel.updateDraft(
          existing.copyWith(
            title: state.title,
            date: state.date,
            notes: state.notes,
          ),
        );
      }

      if (draft == null) {
        emitNewState(
          state.copyWith(
            isSaving: false,
            error: _sessionModel.state.error ?? 'Unable to save workout setup.',
          ),
        );
        return null;
      }

      emitNewState(state.copyWith(isSaving: false));
      return draft.id;
    } catch (_) {
      emitNewState(
        state.copyWith(isSaving: false, error: 'Unable to save workout setup.'),
      );
      return null;
    }
  }
}

@foundry.FoundryView(route: '/workout/setup', args: WorkoutSessionSetupArgs)
class WorkoutSessionSetupView
    extends FoundryView<WorkoutSessionSetupViewModel, WorkoutSessionSetupState> {
  const WorkoutSessionSetupView({required this.args, super.key});

  final WorkoutSessionSetupArgs args;

  @override
  Widget buildWithState(
    BuildContext context,
    WorkoutSessionSetupState? oldState,
    WorkoutSessionSetupState state,
  ) {
    final WorkoutSessionSetupViewModel viewModel = FoundryScope.of(
      context,
    ).resolve<WorkoutSessionSetupViewModel>();

    if (oldState == null) {
      viewModel.initialize(args);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Setup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          ControlledField(
            initialValue: state.title,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            onChanged: viewModel.updateTitle,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: state.isSaving
                ? null
                : () => viewModel.pickDate(context),
            icon: const Icon(Icons.calendar_today),
            label: Text(
              'Date: ${state.date.toLocal().toString().split(' ').first}',
            ),
          ),
          const SizedBox(height: 12),
          ControlledField(
            initialValue: state.notes,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 4,
            onChanged: viewModel.updateNotes,
          ),
          if (state.error != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              state.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: state.isSaving
                ? null
                : () async {
                    final String? draftId = await viewModel.saveAndContinue();
                    if (draftId != null && context.mounted) {
                      await FoundryNavigation.instance.pushDefault(
                        ExercisePickerViewRoute(
                          ExercisePickerArgs(draftId: draftId),
                        ),
                      );
                    }
                  },
            child: state.isSaving
                ? const CircularProgressIndicator()
                : const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
