/// Annotation to mark a ViewModel class.
///
/// Must be applied to classes that extend `FoundryViewModel<T>`.
class FoundryViewModel {
  const FoundryViewModel({this.name, this.lifetime = 'scoped'});

  /// Optional name for generated code.
  final String? name;

  /// Registration lifetime used by generated DI graph.
  ///
  /// Supported values: `singleton`, `scoped`, `transient`.
  ///
  /// Defaults to `scoped` because ViewModels are typically view-scoped.
  final String lifetime;
}
