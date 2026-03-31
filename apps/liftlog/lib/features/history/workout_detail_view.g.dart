// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_detail_view.dart';

// **************************************************************************
// ViewGenerator
// **************************************************************************

// Generated code for @FoundryView WorkoutDetailView

extension WorkoutDetailViewGeneratedExt on WorkoutDetailView {
  static const String generatedRoute = '/history/detail';
  static const String generatedDeepLink = '/history/:workoutId';
}

/// Typed route for [WorkoutDetailView]. Use [WorkoutDetailViewRoute] to navigate.
class WorkoutDetailViewRoute extends RouteConfig<void> {
  const WorkoutDetailViewRoute(this.args);

  final WorkoutDetailArgs args;

  @override
  String? get name => '/history/detail';

  @override
  Route<void> build(BuildContext context) {
    return MaterialPageRoute<void>(
      builder: (_) => WorkoutDetailView(args: args),
    );
  }

  @override
  Route<void> buildDeepLink(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => WorkoutDetailView(args: args),
    );
  }

  /// Returns a [WorkoutDetailView Route] if [uri] matches the deep link pattern,
  /// otherwise returns null.
  static WorkoutDetailViewRoute? matchDeepLink(Uri uri) {
    final Uri patternUri = Uri.parse('/history/:workoutId');
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
    final String? workoutIdRaw =
        params['workoutId'] ?? uri.queryParameters['workoutId'];
    final Object? workoutIdValue;
    if (workoutIdRaw == null) {
      return null;
    } else {
      workoutIdValue = workoutIdRaw;
    }
    final WorkoutDetailArgs args = WorkoutDetailArgs(
      workoutId: workoutIdValue as String,
    );
    return WorkoutDetailViewRoute(args);
  }
}

/// Navigation helpers for [WorkoutDetailView].
extension WorkoutDetailViewNavigation on BuildContext {
  Future<void> pushWorkoutDetailView(WorkoutDetailArgs args) =>
      FoundryNavigator.push(WorkoutDetailViewRoute(args), context: this);
}

// **************************************************************************
// ViewModelGenerator
// **************************************************************************

// Generated helpers for @FoundryViewModel WorkoutDetailViewModel

mixin _$WorkoutDetailViewModelHelpers on FoundryViewModel<WorkoutDetailState> {
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
  /// `error` field of [WorkoutDetailState].
  void setError(String error) {
    emitNewState(state.copyWith(error: error));
  }

  /// Clears the error field on [WorkoutDetailState].
  void clearError() {
    emitNewState(state.copyWith(error: null));
  }
}

// **************************************************************************
// ViewStateGenerator
// **************************************************************************

// ignore_for_file: unused_element, annotate_overrides, prefer_interpolation_to_compose_strings

// Generated code for @FoundryViewState WorkoutDetailState

const _$WorkoutDetailStateSentinel = Object();

/// Whether [WorkoutDetailState] has an `error` field.
const bool $WorkoutDetailStateHasErrorField = true;

mixin _$WorkoutDetailStateMixin {
  WorkoutDetailState copyWith({
    Object? isLoading = _$WorkoutDetailStateSentinel,
    Object? workoutId = _$WorkoutDetailStateSentinel,
    Object? workout = _$WorkoutDetailStateSentinel,
    Object? error = _$WorkoutDetailStateSentinel,
  }) {
    final WorkoutDetailState self = this as WorkoutDetailState;
    return WorkoutDetailState(
      isLoading: identical(isLoading, _$WorkoutDetailStateSentinel)
          ? self.isLoading
          : isLoading as bool,
      workoutId: identical(workoutId, _$WorkoutDetailStateSentinel)
          ? self.workoutId
          : workoutId as String,
      workout: identical(workout, _$WorkoutDetailStateSentinel)
          ? self.workout
          : workout as Workout?,
      error: identical(error, _$WorkoutDetailStateSentinel)
          ? self.error
          : error as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final WorkoutDetailState self = this as WorkoutDetailState;
    return other is WorkoutDetailState &&
        self.isLoading == other.isLoading &&
        self.workoutId == other.workoutId &&
        self.workout == other.workout &&
        self.error == other.error;
  }

  @override
  int get hashCode {
    final WorkoutDetailState self = this as WorkoutDetailState;
    return Object.hash(
      self.isLoading,
      self.workoutId,
      self.workout,
      self.error,
    );
  }

  @override
  String toString() {
    final WorkoutDetailState self = this as WorkoutDetailState;
    final List<String> values = <String>[
      'isLoading: ' + self.isLoading.toString(),
      'workoutId: ' + self.workoutId.toString(),
      'workout: ' + self.workout.toString(),
      'error: ' + self.error.toString(),
    ];
    return 'WorkoutDetailState(' + values.join(', ') + ')';
  }
}
