/// Annotation to mark immutable Service state.
///
/// Similar to ViewState but for domain services.
class FoundryServiceState {
  /// Creates service-state generation metadata.
  const FoundryServiceState({this.persistent = false, this.name});

  /// Whether generated tooling should treat this state as persistence-enabled.
  ///
  /// Current Foundry runtime support for persistence is optional and
  /// application-defined, so this flag primarily communicates intent to
  /// generators and future integration points.
  final bool persistent;

  /// Optional name for generated code.
  final String? name;
}
