/// Annotation to mark immutable Model state.
///
/// Similar to ViewState but for domain models.
class FoundryModelState {
  const FoundryModelState({this.persistent = false, this.name});

  /// Whether this state should be automatically persisted.
  final bool persistent;

  /// Optional name for generated code.
  final String? name;
}
