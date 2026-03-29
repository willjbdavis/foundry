// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_view.dart';

// **************************************************************************
// ViewGenerator
// **************************************************************************

// Generated code for @FoundryView SettingsView

extension SettingsViewGeneratedExt on SettingsView {
  static const String generatedRoute = '/settings';
  static const String generatedDeepLink = '/settings';
}

/// Typed route for [SettingsView]. Use [SettingsViewRoute] to navigate.
class SettingsViewRoute extends RouteConfig<void> {
  const SettingsViewRoute();

  @override
  String? get name => '/settings';

  @override
  Route<void> build(BuildContext context) {
    return MaterialPageRoute<void>(builder: (_) => const SettingsView());
  }

  @override
  Route<void> buildDeepLink(RouteSettings settings) {
    return MaterialPageRoute<void>(
        settings: settings, builder: (_) => const SettingsView());
  }

  /// Returns a [SettingsView Route] if [uri] matches the deep link pattern,
  /// otherwise returns null.
  static SettingsViewRoute? matchDeepLink(Uri uri) {
    final Uri patternUri = Uri.parse('/settings');
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
    return const SettingsViewRoute();
  }
}

/// Navigation helpers for [SettingsView].
extension SettingsViewNavigation on BuildContext {
  Future<void> pushSettingsView() =>
      FoundryNavigator.push(const SettingsViewRoute(), context: this);
}

// **************************************************************************
// ViewModelGenerator
// **************************************************************************

// Generated helpers for @FoundryViewModel SettingsViewModel

mixin _$SettingsViewModelHelpers on FoundryViewModel<SettingsState> {
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
  /// `error` field of [SettingsState].
  void setError(String error) {
    emitNewState(state.copyWith(error: error));
  }

  /// Clears the error field on [SettingsState].
  void clearError() {
    emitNewState(state.copyWith(error: null));
  }
}

// **************************************************************************
// ViewStateGenerator
// **************************************************************************

// ignore_for_file: unused_element, annotate_overrides, prefer_interpolation_to_compose_strings

// Generated code for @FoundryViewState SettingsState

const _$SettingsStateSentinel = Object();

/// Whether [SettingsState] has an `error` field.
const bool $SettingsStateHasErrorField = true;

mixin _$SettingsStateMixin {
  SettingsState copyWith({
    Object? selectedThemeMode = _$SettingsStateSentinel,
    Object? isSaving = _$SettingsStateSentinel,
    Object? error = _$SettingsStateSentinel,
  }) {
    final SettingsState self = this as SettingsState;
    return SettingsState(
      selectedThemeMode: identical(selectedThemeMode, _$SettingsStateSentinel)
          ? self.selectedThemeMode
          : selectedThemeMode as ThemeMode,
      isSaving: identical(isSaving, _$SettingsStateSentinel)
          ? self.isSaving
          : isSaving as bool,
      error: identical(error, _$SettingsStateSentinel)
          ? self.error
          : error as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final SettingsState self = this as SettingsState;
    return other is SettingsState &&
        self.selectedThemeMode == other.selectedThemeMode &&
        self.isSaving == other.isSaving &&
        self.error == other.error;
  }

  @override
  int get hashCode {
    final SettingsState self = this as SettingsState;
    return Object.hash(self.selectedThemeMode, self.isSaving, self.error);
  }

  @override
  String toString() {
    final SettingsState self = this as SettingsState;
    final List<String> values = <String>[
      'selectedThemeMode: ' + self.selectedThemeMode.toString(),
      'isSaving: ' + self.isSaving.toString(),
      'error: ' + self.error.toString(),
    ];
    return 'SettingsState(' + values.join(', ') + ')';
  }
}
