// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_view.dart';

// **************************************************************************
// ViewGenerator
// **************************************************************************

// Generated code for @FoundryView HomeView

extension HomeViewGeneratedExt on HomeView {
  static const String generatedRoute = '/home';
  static const String generatedDeepLink = '/home';
}

/// Typed route for [HomeView]. Use [HomeViewRoute] to navigate.
class HomeViewRoute extends RouteConfig<void> {
  const HomeViewRoute();

  @override
  String? get name => '/home';

  @override
  Route<void> build(BuildContext context) {
    return MaterialPageRoute<void>(builder: (_) => const HomeView());
  }

  @override
  Route<void> buildDeepLink(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const HomeView(),
    );
  }

  /// Returns a [HomeView Route] if [uri] matches the deep link pattern,
  /// otherwise returns null.
  static HomeViewRoute? matchDeepLink(Uri uri) {
    final Uri patternUri = Uri.parse('/home');
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
    return const HomeViewRoute();
  }
}

/// Navigation helpers for [HomeView].
extension HomeViewNavigation on BuildContext {
  Future<void> pushHomeView() =>
      FoundryNavigator.push(const HomeViewRoute(), context: this);
}

// **************************************************************************
// ViewModelGenerator
// **************************************************************************

// Generated helpers for @FoundryViewModel HomeViewModel

mixin _$HomeViewModelHelpers on FoundryViewModel<HomeState> {
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
  /// `error` field of [HomeState].
  void setError(String error) {
    emitNewState(state.copyWith(error: error));
  }

  /// Clears the error field on [HomeState].
  void clearError() {
    emitNewState(state.copyWith(error: null));
  }
}

// **************************************************************************
// ViewStateGenerator
// **************************************************************************

// ignore_for_file: unused_element, annotate_overrides, prefer_interpolation_to_compose_strings

// Generated code for @FoundryViewState HomeState

const _$HomeStateSentinel = Object();

/// Whether [HomeState] has an `error` field.
const bool $HomeStateHasErrorField = true;

mixin _$HomeStateMixin {
  HomeState copyWith({
    Object? isLoading = _$HomeStateSentinel,
    Object? hasActiveWorkout = _$HomeStateSentinel,
    Object? activeWorkoutTitle = _$HomeStateSentinel,
    Object? recentWorkouts = _$HomeStateSentinel,
    Object? error = _$HomeStateSentinel,
  }) {
    final HomeState self = this as HomeState;
    return HomeState(
      isLoading: identical(isLoading, _$HomeStateSentinel)
          ? self.isLoading
          : isLoading as bool,
      hasActiveWorkout: identical(hasActiveWorkout, _$HomeStateSentinel)
          ? self.hasActiveWorkout
          : hasActiveWorkout as bool,
      activeWorkoutTitle: identical(activeWorkoutTitle, _$HomeStateSentinel)
          ? self.activeWorkoutTitle
          : activeWorkoutTitle as String?,
      recentWorkouts: identical(recentWorkouts, _$HomeStateSentinel)
          ? self.recentWorkouts
          : recentWorkouts as List<Workout>,
      error: identical(error, _$HomeStateSentinel)
          ? self.error
          : error as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final HomeState self = this as HomeState;
    return other is HomeState &&
        self.isLoading == other.isLoading &&
        self.hasActiveWorkout == other.hasActiveWorkout &&
        self.activeWorkoutTitle == other.activeWorkoutTitle &&
        self.recentWorkouts == other.recentWorkouts &&
        self.error == other.error;
  }

  @override
  int get hashCode {
    final HomeState self = this as HomeState;
    return Object.hash(
      self.isLoading,
      self.hasActiveWorkout,
      self.activeWorkoutTitle,
      self.recentWorkouts,
      self.error,
    );
  }

  @override
  String toString() {
    final HomeState self = this as HomeState;
    final List<String> values = <String>[
      'isLoading: ' + self.isLoading.toString(),
      'hasActiveWorkout: ' + self.hasActiveWorkout.toString(),
      'activeWorkoutTitle: ' + self.activeWorkoutTitle.toString(),
      'recentWorkouts: ' + self.recentWorkouts.toString(),
      'error: ' + self.error.toString(),
    ];
    return 'HomeState(' + values.join(', ') + ')';
  }
}
