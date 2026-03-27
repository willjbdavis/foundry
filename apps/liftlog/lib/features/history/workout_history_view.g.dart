// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_history_view.dart';

// **************************************************************************
// ViewGenerator
// **************************************************************************

// Generated code for @FoundryView WorkoutHistoryView

extension WorkoutHistoryViewGeneratedExt on WorkoutHistoryView {
  static const String generatedRoute = '/history';
  static const String generatedDeepLink = '/history';
}

/// Typed route for [WorkoutHistoryView]. Use [WorkoutHistoryViewRoute] to navigate.
class WorkoutHistoryViewRoute extends RouteConfig<void> {
  const WorkoutHistoryViewRoute();

  @override
  String? get name => '/history';

  @override
  Route<void> build(BuildContext context) {
    return MaterialPageRoute<void>(builder: (_) => const WorkoutHistoryView());
  }

  /// Returns a [WorkoutHistoryView Route] if [uri] matches the deep link pattern,
  /// otherwise returns null.
  static WorkoutHistoryViewRoute? matchDeepLink(Uri uri) {
    final Uri patternUri = Uri.parse('/history');
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
    return const WorkoutHistoryViewRoute();
  }
}

/// Navigation helpers for [WorkoutHistoryView].
extension WorkoutHistoryViewNavigation on BuildContext {
  Future<void> pushWorkoutHistoryView() =>
      FoundryNavigator.push(const WorkoutHistoryViewRoute(), context: this);
}

// **************************************************************************
// ViewModelGenerator
// **************************************************************************

// Generated helpers for @FoundryViewModel WorkoutHistoryViewModel

mixin _$WorkoutHistoryViewModelHelpers
    on FoundryViewModel<WorkoutHistoryState> {
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
  /// `error` field of [WorkoutHistoryState].
  void setError(String error) {
    emitNewState(state.copyWith(error: error));
  }

  /// Clears the error field on [WorkoutHistoryState].
  void clearError() {
    emitNewState(state.copyWith(error: null));
  }
}

// **************************************************************************
// ViewStateGenerator
// **************************************************************************

// ignore_for_file: unused_element, annotate_overrides, prefer_interpolation_to_compose_strings

// Generated code for @FoundryViewState WorkoutHistoryState

const _$WorkoutHistoryStateSentinel = Object();

/// Whether [WorkoutHistoryState] has an `error` field.
const bool $WorkoutHistoryStateHasErrorField = true;

mixin _$WorkoutHistoryStateMixin {
  WorkoutHistoryState copyWith({
    Object? isLoading = _$WorkoutHistoryStateSentinel,
    Object? searchQuery = _$WorkoutHistoryStateSentinel,
    Object? workouts = _$WorkoutHistoryStateSentinel,
    Object? error = _$WorkoutHistoryStateSentinel,
  }) {
    final WorkoutHistoryState self = this as WorkoutHistoryState;
    return WorkoutHistoryState(
      isLoading: identical(isLoading, _$WorkoutHistoryStateSentinel)
          ? self.isLoading
          : isLoading as bool,
      searchQuery: identical(searchQuery, _$WorkoutHistoryStateSentinel)
          ? self.searchQuery
          : searchQuery as String,
      workouts: identical(workouts, _$WorkoutHistoryStateSentinel)
          ? self.workouts
          : workouts as List<Workout>,
      error: identical(error, _$WorkoutHistoryStateSentinel)
          ? self.error
          : error as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final WorkoutHistoryState self = this as WorkoutHistoryState;
    return other is WorkoutHistoryState &&
        self.isLoading == other.isLoading &&
        self.searchQuery == other.searchQuery &&
        self.workouts == other.workouts &&
        self.error == other.error;
  }

  @override
  int get hashCode {
    final WorkoutHistoryState self = this as WorkoutHistoryState;
    return Object.hash(
        self.isLoading, self.searchQuery, self.workouts, self.error);
  }

  @override
  String toString() {
    final WorkoutHistoryState self = this as WorkoutHistoryState;
    final List<String> values = <String>[
      'isLoading: ' + self.isLoading.toString(),
      'searchQuery: ' + self.searchQuery.toString(),
      'workouts: ' + self.workouts.toString(),
      'error: ' + self.error.toString(),
    ];
    return 'WorkoutHistoryState(' + values.join(', ') + ')';
  }
}
