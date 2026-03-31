// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_session_setup_view.dart';

// **************************************************************************
// ViewGenerator
// **************************************************************************

// Generated code for @FoundryView WorkoutSessionSetupView

extension WorkoutSessionSetupViewGeneratedExt on WorkoutSessionSetupView {
  static const String generatedRoute = '/workout/setup';
  static const String? generatedDeepLink = null;
}

/// Typed route for [WorkoutSessionSetupView]. Use [WorkoutSessionSetupViewRoute] to navigate.
class WorkoutSessionSetupViewRoute extends RouteConfig<void> {
  const WorkoutSessionSetupViewRoute(this.args);

  final WorkoutSessionSetupArgs args;

  @override
  String? get name => '/workout/setup';

  @override
  Route<void> build(BuildContext context) {
    return MaterialPageRoute<void>(
      builder: (_) => WorkoutSessionSetupView(args: args),
    );
  }

  @override
  Route<void> buildDeepLink(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => WorkoutSessionSetupView(args: args),
    );
  }
}

/// Navigation helpers for [WorkoutSessionSetupView].
extension WorkoutSessionSetupViewNavigation on BuildContext {
  Future<void> pushWorkoutSessionSetupView(WorkoutSessionSetupArgs args) =>
      FoundryNavigator.push(WorkoutSessionSetupViewRoute(args), context: this);
}

// **************************************************************************
// ViewModelGenerator
// **************************************************************************

// Generated helpers for @FoundryViewModel WorkoutSessionSetupViewModel

mixin _$WorkoutSessionSetupViewModelHelpers
    on FoundryViewModel<WorkoutSessionSetupState> {
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
  /// `error` field of [WorkoutSessionSetupState].
  void setError(String error) {
    emitNewState(state.copyWith(error: error));
  }

  /// Clears the error field on [WorkoutSessionSetupState].
  void clearError() {
    emitNewState(state.copyWith(error: null));
  }
}

// **************************************************************************
// ViewStateGenerator
// **************************************************************************

// ignore_for_file: unused_element, annotate_overrides, prefer_interpolation_to_compose_strings

// Generated code for @FoundryViewState WorkoutSessionSetupState

const _$WorkoutSessionSetupStateSentinel = Object();

/// Whether [WorkoutSessionSetupState] has an `error` field.
const bool $WorkoutSessionSetupStateHasErrorField = true;

mixin _$WorkoutSessionSetupStateMixin {
  WorkoutSessionSetupState copyWith({
    Object? isLoading = _$WorkoutSessionSetupStateSentinel,
    Object? isSaving = _$WorkoutSessionSetupStateSentinel,
    Object? title = _$WorkoutSessionSetupStateSentinel,
    Object? date = _$WorkoutSessionSetupStateSentinel,
    Object? notes = _$WorkoutSessionSetupStateSentinel,
    Object? error = _$WorkoutSessionSetupStateSentinel,
  }) {
    final WorkoutSessionSetupState self = this as WorkoutSessionSetupState;
    return WorkoutSessionSetupState(
      isLoading: identical(isLoading, _$WorkoutSessionSetupStateSentinel)
          ? self.isLoading
          : isLoading as bool,
      isSaving: identical(isSaving, _$WorkoutSessionSetupStateSentinel)
          ? self.isSaving
          : isSaving as bool,
      title: identical(title, _$WorkoutSessionSetupStateSentinel)
          ? self.title
          : title as String,
      date: identical(date, _$WorkoutSessionSetupStateSentinel)
          ? self.date
          : date as DateTime,
      notes: identical(notes, _$WorkoutSessionSetupStateSentinel)
          ? self.notes
          : notes as String,
      error: identical(error, _$WorkoutSessionSetupStateSentinel)
          ? self.error
          : error as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final WorkoutSessionSetupState self = this as WorkoutSessionSetupState;
    return other is WorkoutSessionSetupState &&
        self.isLoading == other.isLoading &&
        self.isSaving == other.isSaving &&
        self.title == other.title &&
        self.date == other.date &&
        self.notes == other.notes &&
        self.error == other.error;
  }

  @override
  int get hashCode {
    final WorkoutSessionSetupState self = this as WorkoutSessionSetupState;
    return Object.hash(
      self.isLoading,
      self.isSaving,
      self.title,
      self.date,
      self.notes,
      self.error,
    );
  }

  @override
  String toString() {
    final WorkoutSessionSetupState self = this as WorkoutSessionSetupState;
    final List<String> values = <String>[
      'isLoading: ' + self.isLoading.toString(),
      'isSaving: ' + self.isSaving.toString(),
      'title: ' + self.title.toString(),
      'date: ' + self.date.toString(),
      'notes: ' + self.notes.toString(),
      'error: ' + self.error.toString(),
    ];
    return 'WorkoutSessionSetupState(' + values.join(', ') + ')';
  }
}
