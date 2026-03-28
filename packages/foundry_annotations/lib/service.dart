/// Annotation to mark a Service class.
///
/// Can be stateless or stateful. Stateful services can depend on other services.
class FoundryService {
  const FoundryService({
    this.stateful = false,
    this.dependsOn,
    this.name,
    this.lifetime = 'singleton',
  });

  /// Whether this is a stateful service (with `StatefulService<T>` base class).
  final bool stateful;

  /// List of other services that this service depends on.
  final List<Type>? dependsOn;

  /// Optional name for generated code.
  final String? name;

  /// Registration lifetime used by generated DI graph.
  ///
  /// Supported values: `singleton`, `scoped`, `transient`.
  final String lifetime;
}
