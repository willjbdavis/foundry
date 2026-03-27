/// Annotation to mark a View (Flutter Widget) class.
///
/// Used by code generator to build navigation helpers and route builders.
class FoundryView {
  const FoundryView({
    this.route,
    this.args,
    this.result,
    this.deepLink,
    this.deepLinkArgsFactory,
    this.name,
  });

  /// Internal route path for navigation.
  final String? route;

  /// Type of arguments for navigation.
  final Type? args;

  /// Type of result returned when the route is popped.
  final Type? result;

  /// External deep link pattern for URI matching.
  final String? deepLink;

  /// Factory method to parse deep link URI into arguments.
  final Function(Uri)? deepLinkArgsFactory;

  /// Optional name for generated code.
  final String? name;
}
