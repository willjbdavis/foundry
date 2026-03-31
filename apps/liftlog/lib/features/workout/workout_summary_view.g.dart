// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_summary_view.dart';

// **************************************************************************
// ViewGenerator
// **************************************************************************

// Generated code for @FoundryView WorkoutSummaryView

extension WorkoutSummaryViewGeneratedExt on WorkoutSummaryView {
  static const String generatedRoute = '/workout/summary';
  static const String? generatedDeepLink = null;
}

/// Typed route for [WorkoutSummaryView]. Use [WorkoutSummaryViewRoute] to navigate.
class WorkoutSummaryViewRoute extends RouteConfig<void> {
  const WorkoutSummaryViewRoute(this.args);

  final WorkoutSummaryArgs args;

  @override
  String? get name => '/workout/summary';

  @override
  Route<void> build(BuildContext context) {
    return MaterialPageRoute<void>(
      builder: (_) => WorkoutSummaryView(args: args),
    );
  }

  @override
  Route<void> buildDeepLink(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => WorkoutSummaryView(args: args),
    );
  }
}

/// Navigation helpers for [WorkoutSummaryView].
extension WorkoutSummaryViewNavigation on BuildContext {
  Future<void> pushWorkoutSummaryView(WorkoutSummaryArgs args) =>
      FoundryNavigator.push(WorkoutSummaryViewRoute(args), context: this);
}

// **************************************************************************
// ViewModelGenerator
// **************************************************************************

// Generated helpers for @FoundryViewModel WorkoutSummaryViewModel

mixin _$WorkoutSummaryViewModelHelpers
    on FoundryViewModel<WorkoutSummaryState> {
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
  /// `error` field of [WorkoutSummaryState].
  void setError(String error) {
    emitNewState(state.copyWith(error: error));
  }

  /// Clears the error field on [WorkoutSummaryState].
  void clearError() {
    emitNewState(state.copyWith(error: null));
  }
}

// **************************************************************************
// ViewStateGenerator
// **************************************************************************

// ignore_for_file: unused_element, annotate_overrides, prefer_interpolation_to_compose_strings

// Generated code for @FoundryViewState WorkoutSummaryState

const _$WorkoutSummaryStateSentinel = Object();

/// Whether [WorkoutSummaryState] has an `error` field.
const bool $WorkoutSummaryStateHasErrorField = true;

mixin _$WorkoutSummaryStateMixin {
  WorkoutSummaryState copyWith({
    Object? isLoading = _$WorkoutSummaryStateSentinel,
    Object? isSaving = _$WorkoutSummaryStateSentinel,
    Object? totalExercises = _$WorkoutSummaryStateSentinel,
    Object? totalSets = _$WorkoutSummaryStateSentinel,
    Object? error = _$WorkoutSummaryStateSentinel,
    Object? title = _$WorkoutSummaryStateSentinel,
    Object? draftId = _$WorkoutSummaryStateSentinel,
  }) {
    final WorkoutSummaryState self = this as WorkoutSummaryState;
    return WorkoutSummaryState(
      isLoading: identical(isLoading, _$WorkoutSummaryStateSentinel)
          ? self.isLoading
          : isLoading as bool,
      isSaving: identical(isSaving, _$WorkoutSummaryStateSentinel)
          ? self.isSaving
          : isSaving as bool,
      totalExercises: identical(totalExercises, _$WorkoutSummaryStateSentinel)
          ? self.totalExercises
          : totalExercises as int,
      totalSets: identical(totalSets, _$WorkoutSummaryStateSentinel)
          ? self.totalSets
          : totalSets as int,
      error: identical(error, _$WorkoutSummaryStateSentinel)
          ? self.error
          : error as String?,
      title: identical(title, _$WorkoutSummaryStateSentinel)
          ? self.title
          : title as String,
      draftId: identical(draftId, _$WorkoutSummaryStateSentinel)
          ? self.draftId
          : draftId as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final WorkoutSummaryState self = this as WorkoutSummaryState;
    return other is WorkoutSummaryState &&
        self.isLoading == other.isLoading &&
        self.isSaving == other.isSaving &&
        self.totalExercises == other.totalExercises &&
        self.totalSets == other.totalSets &&
        self.error == other.error &&
        self.title == other.title &&
        self.draftId == other.draftId;
  }

  @override
  int get hashCode {
    final WorkoutSummaryState self = this as WorkoutSummaryState;
    return Object.hash(
      self.isLoading,
      self.isSaving,
      self.totalExercises,
      self.totalSets,
      self.error,
      self.title,
      self.draftId,
    );
  }

  @override
  String toString() {
    final WorkoutSummaryState self = this as WorkoutSummaryState;
    final List<String> values = <String>[
      'isLoading: ' + self.isLoading.toString(),
      'isSaving: ' + self.isSaving.toString(),
      'totalExercises: ' + self.totalExercises.toString(),
      'totalSets: ' + self.totalSets.toString(),
      'error: ' + self.error.toString(),
      'title: ' + self.title.toString(),
      'draftId: ' + self.draftId.toString(),
    ];
    return 'WorkoutSummaryState(' + values.join(', ') + ')';
  }
}
