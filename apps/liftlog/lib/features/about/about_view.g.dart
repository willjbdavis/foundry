// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'about_view.dart';

// **************************************************************************
// ViewGenerator
// **************************************************************************

// Generated code for @FoundryView AboutView

extension AboutViewGeneratedExt on AboutView {
  static const String generatedRoute = '/about';
  static const String generatedDeepLink = '/about';
}

/// Typed route for [AboutView]. Use [AboutViewRoute] to navigate.
class AboutViewRoute extends RouteConfig<void> {
  const AboutViewRoute();

  @override
  String? get name => '/about';

  @override
  Route<void> build(BuildContext context) {
    return MaterialPageRoute<void>(builder: (_) => const AboutView());
  }

  /// Returns a [AboutView Route] if [uri] matches the deep link pattern,
  /// otherwise returns null.
  static AboutViewRoute? matchDeepLink(Uri uri) {
    final Uri patternUri = Uri.parse('/about');
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
    return const AboutViewRoute();
  }
}

/// Navigation helpers for [AboutView].
extension AboutViewNavigation on BuildContext {
  Future<void> pushAboutView() =>
      FoundryNavigator.push(const AboutViewRoute(), context: this);
}

// **************************************************************************
// ViewModelGenerator
// **************************************************************************

// Generated helpers for @FoundryViewModel AboutViewModel

mixin _$AboutViewModelHelpers on FoundryViewModel<AboutState> {
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

// Generated code for @FoundryViewState AboutState

const _$AboutStateSentinel = Object();

/// Whether [AboutState] has an `error` field.
const bool $AboutStateHasErrorField = false;

mixin _$AboutStateMixin {
  AboutState copyWith({
    Object? appName = _$AboutStateSentinel,
    Object? appVersion = _$AboutStateSentinel,
  }) {
    final AboutState self = this as AboutState;
    return AboutState(
      appName: identical(appName, _$AboutStateSentinel)
          ? self.appName
          : appName as String,
      appVersion: identical(appVersion, _$AboutStateSentinel)
          ? self.appVersion
          : appVersion as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final AboutState self = this as AboutState;
    return other is AboutState &&
        self.appName == other.appName &&
        self.appVersion == other.appVersion;
  }

  @override
  int get hashCode {
    final AboutState self = this as AboutState;
    return Object.hash(self.appName, self.appVersion);
  }

  @override
  String toString() {
    final AboutState self = this as AboutState;
    final List<String> values = <String>[
      'appName: ' + self.appName.toString(),
      'appVersion: ' + self.appVersion.toString(),
    ];
    return 'AboutState(' + values.join(', ') + ')';
  }
}
