// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_picker_view.dart';

// **************************************************************************
// ViewGenerator
// **************************************************************************

// Generated code for @FoundryView ExercisePickerView

extension ExercisePickerViewGeneratedExt on ExercisePickerView {
  static const String generatedRoute = '/workout/pick-exercise';
  static const String? generatedDeepLink = null;
}

/// Typed route for [ExercisePickerView]. Use [ExercisePickerViewRoute] to navigate.
class ExercisePickerViewRoute extends RouteConfig<void> {
  const ExercisePickerViewRoute(this.args);

  final ExercisePickerArgs args;

  @override
  String? get name => '/workout/pick-exercise';

  @override
  Route<void> build(BuildContext context) {
    return MaterialPageRoute<void>(
        builder: (_) => ExercisePickerView(args: args));
  }
}

/// Navigation helpers for [ExercisePickerView].
extension ExercisePickerViewNavigation on BuildContext {
  Future<void> pushExercisePickerView(ExercisePickerArgs args) =>
      FoundryNavigator.push(ExercisePickerViewRoute(args), context: this);
}

// **************************************************************************
// ViewModelGenerator
// **************************************************************************

// Generated helpers for @FoundryViewModel ExercisePickerViewModel

mixin _$ExercisePickerViewModelHelpers
    on FoundryViewModel<ExercisePickerState> {
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
  /// `error` field of [ExercisePickerState].
  void setError(String error) {
    emitNewState(state.copyWith(error: error));
  }

  /// Clears the error field on [ExercisePickerState].
  void clearError() {
    emitNewState(state.copyWith(error: null));
  }
}

// **************************************************************************
// ViewStateGenerator
// **************************************************************************

// ignore_for_file: unused_element, annotate_overrides, prefer_interpolation_to_compose_strings

// Generated code for @FoundryViewState ExercisePickerState

const _$ExercisePickerStateSentinel = Object();

/// Whether [ExercisePickerState] has an `error` field.
const bool $ExercisePickerStateHasErrorField = true;

mixin _$ExercisePickerStateMixin {
  ExercisePickerState copyWith({
    Object? isLoading = _$ExercisePickerStateSentinel,
    Object? searchQuery = _$ExercisePickerStateSentinel,
    Object? selectedExerciseId = _$ExercisePickerStateSentinel,
    Object? exercises = _$ExercisePickerStateSentinel,
    Object? error = _$ExercisePickerStateSentinel,
  }) {
    final ExercisePickerState self = this as ExercisePickerState;
    return ExercisePickerState(
      isLoading: identical(isLoading, _$ExercisePickerStateSentinel)
          ? self.isLoading
          : isLoading as bool,
      searchQuery: identical(searchQuery, _$ExercisePickerStateSentinel)
          ? self.searchQuery
          : searchQuery as String,
      selectedExerciseId:
          identical(selectedExerciseId, _$ExercisePickerStateSentinel)
              ? self.selectedExerciseId
              : selectedExerciseId as String?,
      exercises: identical(exercises, _$ExercisePickerStateSentinel)
          ? self.exercises
          : exercises as List<ExerciseDefinition>,
      error: identical(error, _$ExercisePickerStateSentinel)
          ? self.error
          : error as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final ExercisePickerState self = this as ExercisePickerState;
    return other is ExercisePickerState &&
        self.isLoading == other.isLoading &&
        self.searchQuery == other.searchQuery &&
        self.selectedExerciseId == other.selectedExerciseId &&
        self.exercises == other.exercises &&
        self.error == other.error;
  }

  @override
  int get hashCode {
    final ExercisePickerState self = this as ExercisePickerState;
    return Object.hash(self.isLoading, self.searchQuery,
        self.selectedExerciseId, self.exercises, self.error);
  }

  @override
  String toString() {
    final ExercisePickerState self = this as ExercisePickerState;
    final List<String> values = <String>[
      'isLoading: ' + self.isLoading.toString(),
      'searchQuery: ' + self.searchQuery.toString(),
      'selectedExerciseId: ' + self.selectedExerciseId.toString(),
      'exercises: ' + self.exercises.toString(),
      'error: ' + self.error.toString(),
    ];
    return 'ExercisePickerState(' + values.join(', ') + ')';
  }
}
