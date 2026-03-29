// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercises_database_view.dart';

// **************************************************************************
// ViewGenerator
// **************************************************************************

// Generated code for @FoundryView ExercisesDatabaseView

extension ExercisesDatabaseViewGeneratedExt on ExercisesDatabaseView {
  static const String generatedRoute = '/exercises';
  static const String generatedDeepLink = '/exercises';
}

/// Typed route for [ExercisesDatabaseView]. Use [ExercisesDatabaseViewRoute] to navigate.
class ExercisesDatabaseViewRoute extends RouteConfig<void> {
  const ExercisesDatabaseViewRoute();

  @override
  String? get name => '/exercises';

  @override
  Route<void> build(BuildContext context) {
    return MaterialPageRoute<void>(
        builder: (_) => const ExercisesDatabaseView());
  }

  @override
  Route<void> buildDeepLink(RouteSettings settings) {
    return MaterialPageRoute<void>(
        settings: settings, builder: (_) => const ExercisesDatabaseView());
  }

  /// Returns a [ExercisesDatabaseView Route] if [uri] matches the deep link pattern,
  /// otherwise returns null.
  static ExercisesDatabaseViewRoute? matchDeepLink(Uri uri) {
    final Uri patternUri = Uri.parse('/exercises');
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
    return const ExercisesDatabaseViewRoute();
  }
}

/// Navigation helpers for [ExercisesDatabaseView].
extension ExercisesDatabaseViewNavigation on BuildContext {
  Future<void> pushExercisesDatabaseView() =>
      FoundryNavigator.push(const ExercisesDatabaseViewRoute(), context: this);
}

// **************************************************************************
// ViewModelGenerator
// **************************************************************************

// Generated helpers for @FoundryViewModel ExercisesDatabaseViewModel

mixin _$ExercisesDatabaseViewModelHelpers
    on FoundryViewModel<ExercisesDatabaseState> {
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
  /// `error` field of [ExercisesDatabaseState].
  void setError(String error) {
    emitNewState(state.copyWith(error: error));
  }

  /// Clears the error field on [ExercisesDatabaseState].
  void clearError() {
    emitNewState(state.copyWith(error: null));
  }
}

// **************************************************************************
// ViewStateGenerator
// **************************************************************************

// ignore_for_file: unused_element, annotate_overrides, prefer_interpolation_to_compose_strings

// Generated code for @FoundryViewState ExercisesDatabaseState

const _$ExercisesDatabaseStateSentinel = Object();

/// Whether [ExercisesDatabaseState] has an `error` field.
const bool $ExercisesDatabaseStateHasErrorField = true;

mixin _$ExercisesDatabaseStateMixin {
  ExercisesDatabaseState copyWith({
    Object? isLoading = _$ExercisesDatabaseStateSentinel,
    Object? searchQuery = _$ExercisesDatabaseStateSentinel,
    Object? exercises = _$ExercisesDatabaseStateSentinel,
    Object? error = _$ExercisesDatabaseStateSentinel,
  }) {
    final ExercisesDatabaseState self = this as ExercisesDatabaseState;
    return ExercisesDatabaseState(
      isLoading: identical(isLoading, _$ExercisesDatabaseStateSentinel)
          ? self.isLoading
          : isLoading as bool,
      searchQuery: identical(searchQuery, _$ExercisesDatabaseStateSentinel)
          ? self.searchQuery
          : searchQuery as String,
      exercises: identical(exercises, _$ExercisesDatabaseStateSentinel)
          ? self.exercises
          : exercises as List<ExerciseDefinition>,
      error: identical(error, _$ExercisesDatabaseStateSentinel)
          ? self.error
          : error as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final ExercisesDatabaseState self = this as ExercisesDatabaseState;
    return other is ExercisesDatabaseState &&
        self.isLoading == other.isLoading &&
        self.searchQuery == other.searchQuery &&
        self.exercises == other.exercises &&
        self.error == other.error;
  }

  @override
  int get hashCode {
    final ExercisesDatabaseState self = this as ExercisesDatabaseState;
    return Object.hash(
        self.isLoading, self.searchQuery, self.exercises, self.error);
  }

  @override
  String toString() {
    final ExercisesDatabaseState self = this as ExercisesDatabaseState;
    final List<String> values = <String>[
      'isLoading: ' + self.isLoading.toString(),
      'searchQuery: ' + self.searchQuery.toString(),
      'exercises: ' + self.exercises.toString(),
      'error: ' + self.error.toString(),
    ];
    return 'ExercisesDatabaseState(' + values.join(', ') + ')';
  }
}
