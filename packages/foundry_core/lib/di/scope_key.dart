/// Builds deterministic registration keys for type + optional name.
String buildScopeKey<T>(final String? named) {
  final String typeKey = '$T';
  return named == null ? typeKey : '$typeKey::$named';
}
