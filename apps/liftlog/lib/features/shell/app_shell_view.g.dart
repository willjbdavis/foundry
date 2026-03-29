// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_shell_view.dart';

// **************************************************************************
// ViewGenerator
// **************************************************************************

// Generated code for @FoundryView AppShellView

extension AppShellViewGeneratedExt on AppShellView {
  static const String generatedRoute = '/';
  static const String generatedDeepLink = '/';
}

/// Typed route for [AppShellView]. Use [AppShellViewRoute] to navigate.
class AppShellViewRoute extends RouteConfig<void> {
  const AppShellViewRoute();

  @override
  String? get name => '/';

  @override
  Route<void> build(BuildContext context) {
    return MaterialPageRoute<void>(builder: (_) => const AppShellView());
  }

  @override
  Route<void> buildDeepLink(RouteSettings settings) {
    return MaterialPageRoute<void>(
        settings: settings, builder: (_) => const AppShellView());
  }

  /// Returns a [AppShellView Route] if [uri] matches the deep link pattern,
  /// otherwise returns null.
  static AppShellViewRoute? matchDeepLink(Uri uri) {
    final Uri patternUri = Uri.parse('/');
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
    return const AppShellViewRoute();
  }
}

/// Navigation helpers for [AppShellView].
extension AppShellViewNavigation on BuildContext {
  Future<void> pushAppShellView() =>
      FoundryNavigator.push(const AppShellViewRoute(), context: this);
}

// **************************************************************************
// ViewModelGenerator
// **************************************************************************

// Generated helpers for @FoundryViewModel AppShellViewModel

mixin _$AppShellViewModelHelpers on FoundryViewModel<AppShellState> {
  /// Runs [action] inside a try/catch, forwarding any
  /// error to [invokeOnError] automatically.
  Future<void> safeAsync(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      await invokeOnError(error, stackTrace);
    }
  }
}

// **************************************************************************
// ViewStateGenerator
// **************************************************************************

// ignore_for_file: unused_element, annotate_overrides, prefer_interpolation_to_compose_strings

// Generated code for @FoundryViewState AppShellState

const _$AppShellStateSentinel = Object();

/// Whether [AppShellState] has an `error` field.
const bool $AppShellStateHasErrorField = false;

mixin _$AppShellStateMixin {
  AppShellState copyWith({
    Object? selectedTabIndex = _$AppShellStateSentinel,
    Object? hasActiveWorkout = _$AppShellStateSentinel,
    Object? historyRefreshVersion = _$AppShellStateSentinel,
  }) {
    final AppShellState self = this as AppShellState;
    return AppShellState(
      selectedTabIndex: identical(selectedTabIndex, _$AppShellStateSentinel)
          ? self.selectedTabIndex
          : selectedTabIndex as int,
      hasActiveWorkout: identical(hasActiveWorkout, _$AppShellStateSentinel)
          ? self.hasActiveWorkout
          : hasActiveWorkout as bool,
      historyRefreshVersion:
          identical(historyRefreshVersion, _$AppShellStateSentinel)
              ? self.historyRefreshVersion
              : historyRefreshVersion as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final AppShellState self = this as AppShellState;
    return other is AppShellState &&
        self.selectedTabIndex == other.selectedTabIndex &&
        self.hasActiveWorkout == other.hasActiveWorkout &&
        self.historyRefreshVersion == other.historyRefreshVersion;
  }

  @override
  int get hashCode {
    final AppShellState self = this as AppShellState;
    return Object.hash(self.selectedTabIndex, self.hasActiveWorkout,
        self.historyRefreshVersion);
  }

  @override
  String toString() {
    final AppShellState self = this as AppShellState;
    final List<String> values = <String>[
      'selectedTabIndex: ' + self.selectedTabIndex.toString(),
      'hasActiveWorkout: ' + self.hasActiveWorkout.toString(),
      'historyRefreshVersion: ' + self.historyRefreshVersion.toString(),
    ];
    return 'AppShellState(' + values.join(', ') + ')';
  }
}
