/// Annotation to mark immutable View state.
///
/// Supports both single classes and sealed hierarchies.
class FoundryViewState {
  const FoundryViewState({this.name});

  /// Optional name for generated code.
  final String? name;
}
