/// Annotation to mark a Model class.
///
/// Can be stateless or stateful. Stateful models can depend on other models.
class FoundryModel {
  const FoundryModel({
    this.stateful = false,
    this.dependsOn,
    this.name,
    this.lifetime = 'singleton',
  });

  /// Whether this is a stateful model (with `StatefulModel<T>` base class).
  final bool stateful;

  /// List of other models that this model depends on.
  final List<Type>? dependsOn;

  /// Optional name for generated code.
  final String? name;

  /// Registration lifetime used by generated DI graph.
  ///
  /// Supported values: `singleton`, `scoped`, `transient`.
  final String lifetime;
}
