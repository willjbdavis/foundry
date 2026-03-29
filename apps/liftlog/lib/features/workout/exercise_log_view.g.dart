// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_log_view.dart';

// **************************************************************************
// ViewGenerator
// **************************************************************************

// Generated code for @FoundryView ExerciseLogView

extension ExerciseLogViewGeneratedExt on ExerciseLogView {
  static const String generatedRoute = '/workout/log';
  static const String? generatedDeepLink = null;
}

/// Typed route for [ExerciseLogView]. Use [ExerciseLogViewRoute] to navigate.
class ExerciseLogViewRoute extends RouteConfig<void> {
  const ExerciseLogViewRoute(this.args);

  final ExerciseLogArgs args;

  @override
  String? get name => '/workout/log';

  @override
  Route<void> build(BuildContext context) {
    return MaterialPageRoute<void>(builder: (_) => ExerciseLogView(args: args));
  }

  @override
  Route<void> buildDeepLink(RouteSettings settings) {
    return MaterialPageRoute<void>(
        settings: settings, builder: (_) => ExerciseLogView(args: args));
  }
}

/// Navigation helpers for [ExerciseLogView].
extension ExerciseLogViewNavigation on BuildContext {
  Future<void> pushExerciseLogView(ExerciseLogArgs args) =>
      FoundryNavigator.push(ExerciseLogViewRoute(args), context: this);
}

// **************************************************************************
// ViewModelGenerator
// **************************************************************************

// Generated helpers for @FoundryViewModel ExerciseLogViewModel

mixin _$ExerciseLogViewModelHelpers on FoundryViewModel<ExerciseLogState> {
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
  /// `error` field of [ExerciseLogState].
  void setError(String error) {
    emitNewState(state.copyWith(error: error));
  }

  /// Clears the error field on [ExerciseLogState].
  void clearError() {
    emitNewState(state.copyWith(error: null));
  }
}

// **************************************************************************
// ViewStateGenerator
// **************************************************************************

// ignore_for_file: unused_element, annotate_overrides, prefer_interpolation_to_compose_strings

// Generated code for @FoundryViewState ExerciseLogState

const _$ExerciseLogStateSentinel = Object();

/// Whether [ExerciseLogState] has an `error` field.
const bool $ExerciseLogStateHasErrorField = true;

mixin _$ExerciseLogStateMixin {
  ExerciseLogState copyWith({
    Object? isLoading = _$ExerciseLogStateSentinel,
    Object? isSaving = _$ExerciseLogStateSentinel,
    Object? draftTitle = _$ExerciseLogStateSentinel,
    Object? draftId = _$ExerciseLogStateSentinel,
    Object? exercises = _$ExerciseLogStateSentinel,
    Object? selectedExerciseIndex = _$ExerciseLogStateSentinel,
    Object? timerRemainingSeconds = _$ExerciseLogStateSentinel,
    Object? timerTotalSeconds = _$ExerciseLogStateSentinel,
    Object? isTimerRunning = _$ExerciseLogStateSentinel,
    Object? showRestFinishedBanner = _$ExerciseLogStateSentinel,
    Object? repsInput = _$ExerciseLogStateSentinel,
    Object? weightInput = _$ExerciseLogStateSentinel,
    Object? error = _$ExerciseLogStateSentinel,
  }) {
    final ExerciseLogState self = this as ExerciseLogState;
    return ExerciseLogState(
      isLoading: identical(isLoading, _$ExerciseLogStateSentinel)
          ? self.isLoading
          : isLoading as bool,
      isSaving: identical(isSaving, _$ExerciseLogStateSentinel)
          ? self.isSaving
          : isSaving as bool,
      draftTitle: identical(draftTitle, _$ExerciseLogStateSentinel)
          ? self.draftTitle
          : draftTitle as String,
      draftId: identical(draftId, _$ExerciseLogStateSentinel)
          ? self.draftId
          : draftId as String,
      exercises: identical(exercises, _$ExerciseLogStateSentinel)
          ? self.exercises
          : exercises as List<LoggedExercise>,
      selectedExerciseIndex:
          identical(selectedExerciseIndex, _$ExerciseLogStateSentinel)
              ? self.selectedExerciseIndex
              : selectedExerciseIndex as int,
      timerRemainingSeconds:
          identical(timerRemainingSeconds, _$ExerciseLogStateSentinel)
              ? self.timerRemainingSeconds
              : timerRemainingSeconds as int,
      timerTotalSeconds:
          identical(timerTotalSeconds, _$ExerciseLogStateSentinel)
              ? self.timerTotalSeconds
              : timerTotalSeconds as int,
      isTimerRunning: identical(isTimerRunning, _$ExerciseLogStateSentinel)
          ? self.isTimerRunning
          : isTimerRunning as bool,
      showRestFinishedBanner:
          identical(showRestFinishedBanner, _$ExerciseLogStateSentinel)
              ? self.showRestFinishedBanner
              : showRestFinishedBanner as bool,
      repsInput: identical(repsInput, _$ExerciseLogStateSentinel)
          ? self.repsInput
          : repsInput as String,
      weightInput: identical(weightInput, _$ExerciseLogStateSentinel)
          ? self.weightInput
          : weightInput as String,
      error: identical(error, _$ExerciseLogStateSentinel)
          ? self.error
          : error as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final ExerciseLogState self = this as ExerciseLogState;
    return other is ExerciseLogState &&
        self.isLoading == other.isLoading &&
        self.isSaving == other.isSaving &&
        self.draftTitle == other.draftTitle &&
        self.draftId == other.draftId &&
        self.exercises == other.exercises &&
        self.selectedExerciseIndex == other.selectedExerciseIndex &&
        self.timerRemainingSeconds == other.timerRemainingSeconds &&
        self.timerTotalSeconds == other.timerTotalSeconds &&
        self.isTimerRunning == other.isTimerRunning &&
        self.showRestFinishedBanner == other.showRestFinishedBanner &&
        self.repsInput == other.repsInput &&
        self.weightInput == other.weightInput &&
        self.error == other.error;
  }

  @override
  int get hashCode {
    final ExerciseLogState self = this as ExerciseLogState;
    return Object.hash(
        self.isLoading,
        self.isSaving,
        self.draftTitle,
        self.draftId,
        self.exercises,
        self.selectedExerciseIndex,
        self.timerRemainingSeconds,
        self.timerTotalSeconds,
        self.isTimerRunning,
        self.showRestFinishedBanner,
        self.repsInput,
        self.weightInput,
        self.error);
  }

  @override
  String toString() {
    final ExerciseLogState self = this as ExerciseLogState;
    final List<String> values = <String>[
      'isLoading: ' + self.isLoading.toString(),
      'isSaving: ' + self.isSaving.toString(),
      'draftTitle: ' + self.draftTitle.toString(),
      'draftId: ' + self.draftId.toString(),
      'exercises: ' + self.exercises.toString(),
      'selectedExerciseIndex: ' + self.selectedExerciseIndex.toString(),
      'timerRemainingSeconds: ' + self.timerRemainingSeconds.toString(),
      'timerTotalSeconds: ' + self.timerTotalSeconds.toString(),
      'isTimerRunning: ' + self.isTimerRunning.toString(),
      'showRestFinishedBanner: ' + self.showRestFinishedBanner.toString(),
      'repsInput: ' + self.repsInput.toString(),
      'weightInput: ' + self.weightInput.toString(),
      'error: ' + self.error.toString(),
    ];
    return 'ExerciseLogState(' + values.join(', ') + ')';
  }
}
