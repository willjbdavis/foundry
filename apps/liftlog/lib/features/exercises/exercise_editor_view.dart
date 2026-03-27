import 'package:flutter/material.dart';
import 'package:foundry_annotations/foundry_annotations.dart' as foundry;
import 'package:foundry_flutter/foundry_flutter.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

import '../../core/domain/exercise_definition.dart';
import '../../core/repositories/exercise_repository.dart';
import '../../core/widgets/app_animations.dart';

part 'exercise_editor_view.g.dart';

class ExerciseEditorArgs extends RouteArgs {
  const ExerciseEditorArgs({
    this.exerciseId,
    this.returnToWorkoutDraftId,
    this.selectAfterSave = false,
  });

  final String? exerciseId;
  final String? returnToWorkoutDraftId;
  final bool selectAfterSave;
}

typedef ExerciseEditorResult = bool?;

@foundry.FoundryViewState()
class ExerciseEditorState with _$ExerciseEditorStateMixin {
  final bool isLoading;
  final bool isSaving;
  final bool isEditMode;
  final String? exerciseId;
  final String name;
  final String description;
  final String? error;

  const ExerciseEditorState({
    this.isLoading = false,
    this.isSaving = false,
    this.isEditMode = false,
    this.exerciseId,
    this.name = '',
    this.description = '',
    this.error,
  });
}

@foundry.FoundryViewModel()
class ExerciseEditorViewModel extends FoundryViewModel<ExerciseEditorState> {
  ExerciseEditorViewModel(this._exerciseRepository) {
    emitNewState(const ExerciseEditorState());
  }

  final ExerciseRepository _exerciseRepository;

  Future<void> initialize(ExerciseEditorArgs args) async {
    if (args.exerciseId == null) {
      emitNewState(
        state.copyWith(
          isEditMode: false,
          exerciseId: null,
          name: '',
          description: '',
          isSaving: false,
          isLoading: false,
          error: null,
        ),
      );
      return;
    }

    emitNewState(
      state.copyWith(
        isLoading: true,
        isEditMode: true,
        exerciseId: args.exerciseId,
        error: null,
      ),
    );

    final ExerciseDefinition? existing = await _exerciseRepository
        .getExerciseById(args.exerciseId!);

    if (existing == null) {
      emitNewState(
        state.copyWith(isLoading: false, error: 'Exercise not found.'),
      );
      return;
    }

    emitNewState(
      state.copyWith(
        isLoading: false,
        name: existing.name,
        description: existing.description,
        error: null,
      ),
    );
  }

  void updateName(String value) {
    emitNewState(state.copyWith(name: value, error: null));
  }

  void updateDescription(String value) {
    emitNewState(state.copyWith(description: value, error: null));
  }

  Future<bool> save() async {
    emitNewState(state.copyWith(isSaving: true, error: null));
    try {
      if (state.isEditMode) {
        await _exerciseRepository.updateExercise(
          id: state.exerciseId!,
          name: state.name,
          description: state.description,
        );
      } else {
        await _exerciseRepository.createExercise(
          name: state.name,
          description: state.description,
        );
      }
      emitNewState(state.copyWith(isSaving: false, error: null));
      return true;
    } on ExerciseValidationException catch (e) {
      emitNewState(state.copyWith(isSaving: false, error: e.message));
      return false;
    } catch (_) {
      emitNewState(
        state.copyWith(
          isSaving: false,
          error: 'Unable to save exercise. Please try again.',
        ),
      );
      return false;
    }
  }
}

@foundry.FoundryView(
  route: '/exercises/editor',
  args: ExerciseEditorArgs,
  result: ExerciseEditorResult,
  deepLink: '/exercises/:exerciseId/edit',
)
class ExerciseEditorView
    extends FoundryView<ExerciseEditorViewModel, ExerciseEditorState> {
  const ExerciseEditorView({required this.args, super.key});

  final ExerciseEditorArgs args;

  @override
  Widget buildWithState(
    BuildContext context,
    ExerciseEditorState? oldState,
    ExerciseEditorState state,
  ) {
    final ExerciseEditorViewModel viewModel = FoundryScope.of(
      context,
    ).resolve<ExerciseEditorViewModel>();

    if (oldState == null) {
      viewModel.initialize(args);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(state.isEditMode ? 'Edit Exercise' : 'Create Exercise'),
        actions: <Widget>[
          TextButton(
            onPressed: state.isSaving
                ? null
                : () async {
                    final bool saved = await viewModel.save();
                    if (saved && context.mounted) {
                      FoundryNavigation.instance.popDefault(true);
                    }
                  },
            child: state.isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                ControlledField(
                  initialValue: state.name,
                  decoration: const InputDecoration(
                    labelText: 'Exercise name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: viewModel.updateName,
                ),
                const SizedBox(height: 12),
                ControlledField(
                  initialValue: state.description,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  onChanged: viewModel.updateDescription,
                ),
                if (state.error != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    state.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
