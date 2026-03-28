/// Annotation to mark immutable Service state.
///
/// Similar to ViewState but for domain services.
class FoundryServiceState {
  const FoundryServiceState({this.persistent = false, this.name});

  /// Whether this state should be automatically persisted.
  final bool persistent;

  /// Optional name for generated code.
  final String? name;
}
