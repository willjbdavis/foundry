// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_editor_view.dart';

// **************************************************************************
// ViewGenerator
// **************************************************************************

// Generated code for @FoundryView ExerciseEditorView

extension ExerciseEditorViewGeneratedExt on ExerciseEditorView {
  static const String generatedRoute = '/exercises/editor';
  static const String generatedDeepLink = '/exercises/:exerciseId/edit';
}

/// Typed route for [ExerciseEditorView]. Use [ExerciseEditorViewRoute] to navigate.
class ExerciseEditorViewRoute extends RouteConfig<bool?> {
  const ExerciseEditorViewRoute(this.args);

  final ExerciseEditorArgs args;

  @override
  String? get name => '/exercises/editor';

  @override
  Route<bool?> build(BuildContext context) {
    return MaterialPageRoute<bool?>(
      builder: (_) => ExerciseEditorView(args: args),
    );
  }

  @override
  Route<bool?> buildDeepLink(RouteSettings settings) {
    return MaterialPageRoute<bool?>(
      settings: settings,
      builder: (_) => ExerciseEditorView(args: args),
    );
  }

  /// Returns a [ExerciseEditorView Route] if [uri] matches the deep link pattern,
  /// otherwise returns null.
  static ExerciseEditorViewRoute? matchDeepLink(Uri uri) {
    final Uri patternUri = Uri.parse('/exercises/:exerciseId/edit');
    final List<String> pattern = patternUri.pathSegments;
    final List<String> actual = uri.pathSegments;
    if (pattern.length != actual.length) return null;
    final Map<String, String> params = <String, String>{};
    for (int i = 0; i < pattern.length; i++) {
      final String p = pattern[i];
      final String a = actual[i];
      if (p.startsWith(':')) {
        params[p.substring(1)] = a;
        continue;
      }
      if (p != a) return null;
    }
    final String? exerciseIdRaw =
        params['exerciseId'] ?? uri.queryParameters['exerciseId'];
    final Object? exerciseIdValue;
    if (exerciseIdRaw == null) {
      exerciseIdValue = null;
    } else {
      exerciseIdValue = exerciseIdRaw;
    }
    final String? returnToWorkoutDraftIdRaw =
        params['returnToWorkoutDraftId'] ??
        uri.queryParameters['returnToWorkoutDraftId'];
    final Object? returnToWorkoutDraftIdValue;
    if (returnToWorkoutDraftIdRaw == null) {
      returnToWorkoutDraftIdValue = null;
    } else {
      returnToWorkoutDraftIdValue = returnToWorkoutDraftIdRaw;
    }
    final String? selectAfterSaveRaw =
        params['selectAfterSave'] ?? uri.queryParameters['selectAfterSave'];
    final Object? selectAfterSaveValue;
    if (selectAfterSaveRaw == null) {
      selectAfterSaveValue = false;
    } else {
      if (selectAfterSaveRaw == "true") {
        selectAfterSaveValue = true;
      } else if (selectAfterSaveRaw == "false") {
        selectAfterSaveValue = false;
      } else {
        return null;
      }
    }
    final ExerciseEditorArgs args = ExerciseEditorArgs(
      exerciseId: exerciseIdValue as String?,
      returnToWorkoutDraftId: returnToWorkoutDraftIdValue as String?,
      selectAfterSave: selectAfterSaveValue as bool,
    );
    return ExerciseEditorViewRoute(args);
  }
}

/// Navigation helpers for [ExerciseEditorView].
extension ExerciseEditorViewNavigation on BuildContext {
  Future<bool?> pushExerciseEditorView(ExerciseEditorArgs args) =>
      FoundryNavigator.push(ExerciseEditorViewRoute(args), context: this);
}

// **************************************************************************
// ViewModelGenerator
// **************************************************************************

// Generated helpers for @FoundryViewModel ExerciseEditorViewModel

mixin _$ExerciseEditorViewModelHelpers
    on FoundryViewModel<ExerciseEditorState> {
  /// Runs [action] inside a try/catch, forwarding any
  /// error to [invokeOnError] automatically.
  Future<void> safeAsync(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      await invokeOnError(error, stackTrace);
    }
  }

  /// Emits a new state with [error] set on the
  /// `error` field of [ExerciseEditorState].
  void setError(String error) {
    emitNewState(state.copyWith(error: error));
  }

  /// Clears the error field on [ExerciseEditorState].
  void clearError() {
    emitNewState(state.copyWith(error: null));
  }
}

// **************************************************************************
// ViewStateGenerator
// **************************************************************************

// ignore_for_file: unused_element, annotate_overrides, prefer_interpolation_to_compose_strings

// Generated code for @FoundryViewState ExerciseEditorState

const _$ExerciseEditorStateSentinel = Object();

/// Whether [ExerciseEditorState] has an `error` field.
const bool $ExerciseEditorStateHasErrorField = true;

mixin _$ExerciseEditorStateMixin {
  ExerciseEditorState copyWith({
    Object? isLoading = _$ExerciseEditorStateSentinel,
    Object? isSaving = _$ExerciseEditorStateSentinel,
    Object? isEditMode = _$ExerciseEditorStateSentinel,
    Object? exerciseId = _$ExerciseEditorStateSentinel,
    Object? name = _$ExerciseEditorStateSentinel,
    Object? description = _$ExerciseEditorStateSentinel,
    Object? error = _$ExerciseEditorStateSentinel,
  }) {
    final ExerciseEditorState self = this as ExerciseEditorState;
    return ExerciseEditorState(
      isLoading: identical(isLoading, _$ExerciseEditorStateSentinel)
          ? self.isLoading
          : isLoading as bool,
      isSaving: identical(isSaving, _$ExerciseEditorStateSentinel)
          ? self.isSaving
          : isSaving as bool,
      isEditMode: identical(isEditMode, _$ExerciseEditorStateSentinel)
          ? self.isEditMode
          : isEditMode as bool,
      exerciseId: identical(exerciseId, _$ExerciseEditorStateSentinel)
          ? self.exerciseId
          : exerciseId as String?,
      name: identical(name, _$ExerciseEditorStateSentinel)
          ? self.name
          : name as String,
      description: identical(description, _$ExerciseEditorStateSentinel)
          ? self.description
          : description as String,
      error: identical(error, _$ExerciseEditorStateSentinel)
          ? self.error
          : error as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final ExerciseEditorState self = this as ExerciseEditorState;
    return other is ExerciseEditorState &&
        self.isLoading == other.isLoading &&
        self.isSaving == other.isSaving &&
        self.isEditMode == other.isEditMode &&
        self.exerciseId == other.exerciseId &&
        self.name == other.name &&
        self.description == other.description &&
        self.error == other.error;
  }

  @override
  int get hashCode {
    final ExerciseEditorState self = this as ExerciseEditorState;
    return Object.hash(
      self.isLoading,
      self.isSaving,
      self.isEditMode,
      self.exerciseId,
      self.name,
      self.description,
      self.error,
    );
  }

  @override
  String toString() {
    final ExerciseEditorState self = this as ExerciseEditorState;
    final List<String> values = <String>[
      'isLoading: ' + self.isLoading.toString(),
      'isSaving: ' + self.isSaving.toString(),
      'isEditMode: ' + self.isEditMode.toString(),
      'exerciseId: ' + self.exerciseId.toString(),
      'name: ' + self.name.toString(),
      'description: ' + self.description.toString(),
      'error: ' + self.error.toString(),
    ];
    return 'ExerciseEditorState(' + values.join(', ') + ')';
  }
}
