/// Returns the single-quoted Dart string literal for [value],
/// or `'null'` if [value] is null.
String singleQuotedLiteralOrNull(String? value) {
  if (value == null) {
    return 'null';
  }
  return "'${value.replaceAll("'", "\\'")}'";
}

/// Infers a ViewState type name from a ViewModel type name using the
/// naming convention `XxxViewModel` -> `XxxState`.
String resolveViewStateTypeFromViewModelType(String viewModelType) {
  const suffix = 'ViewModel';
  if (viewModelType.endsWith(suffix) && viewModelType.length > suffix.length) {
    return '${viewModelType.substring(0, viewModelType.length - suffix.length)}State';
  }
  return 'ViewModelState';
}

/// Converts a deep link pattern such as `/profile/:userId/tab/:tab` into a
/// Dart [RegExp] source string with named capture groups.
///
/// Path parameters use the `:name` syntax.  Everything else is treated as a
/// literal path segment that must match exactly (special regex characters are
/// escaped).
String deepLinkPatternToRegexSource(String pattern) {
  final segments = pattern.split('/');
  final regexParts = segments.map((seg) {
    if (seg.startsWith(':')) {
      final name = seg.substring(1);
      return '(?<$name>[^/]+)';
    }
    // Escape regex special characters in literal segments.
    return RegExp.escape(seg);
  });
  const sep = r'\/';
  return '^${regexParts.join(sep)}\$';
}

/// Returns the list of path parameter names declared in [pattern].
///
/// For `/profile/:userId/tab/:tab` this returns `['userId', 'tab']`.
List<String> deepLinkPathParamNames(String pattern) {
  final matches = RegExp(r':([A-Za-z_][A-Za-z0-9_]*)').allMatches(pattern);
  return matches.map((m) => m.group(1)!).toList();
}

/// Attempts to match [uri] against the deep link [pattern].
///
/// Returns a map of path parameter names to their string values from the URI
/// if the pattern matches, or `null` if it does not.
///
/// This utility is emitted into generated code by [ViewGenerator]; it is
/// also available as a runtime helper for tests.
Map<String, String>? matchDeepLinkPattern(String pattern, Uri uri) {
  final regexSource = deepLinkPatternToRegexSource(pattern);
  final regex = RegExp(regexSource);
  final path = uri.path;
  final match = regex.firstMatch(path);
  if (match == null) return null;

  final params = <String, String>{};
  for (final name in deepLinkPathParamNames(pattern)) {
    final value = match.namedGroup(name);
    if (value != null) {
      params[name] = value;
    }
  }
  return params;
}

/// Coerces a string [value] to the Dart primitive type denoted by [typeName].
///
/// Supported types: `String`, `int`, `double`, `bool`, `DateTime`.
/// Returns `null` for unsupported types or failed conversions.
Object? coercePrimitive(String typeName, String value) {
  switch (typeName) {
    case 'String':
      return value;
    case 'int':
      return int.tryParse(value);
    case 'double':
      return double.tryParse(value);
    case 'bool':
      if (value == 'true') return true;
      if (value == 'false') return false;
      return null;
    case 'DateTime':
      return DateTime.tryParse(value);
    default:
      return null;
  }
}
