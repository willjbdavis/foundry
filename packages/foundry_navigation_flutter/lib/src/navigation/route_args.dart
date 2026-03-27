/// Marker base class for generated typed route arguments.
///
/// Generated `@View(args: ...)` helpers expect a single args object, typically
/// extending this class to make the route input contract explicit and discoverable.
abstract class RouteArgs {
  const RouteArgs();
}
