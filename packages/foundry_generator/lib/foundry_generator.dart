import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:foundry_annotations/foundry_annotations.dart';

import 'src/generators/view_state_generator.dart';
import 'src/generators/service_state_generator.dart';
import 'src/generators/view_model_generator.dart';
import 'src/generators/service_generator.dart';
import 'src/generators/view_generator.dart';
import 'src/generators/container_generator.dart';

export 'src/generators/view_state_generator.dart';
export 'src/generators/service_state_generator.dart';
export 'src/generators/view_model_generator.dart';
export 'src/generators/service_generator.dart';
export 'src/generators/view_generator.dart';
export 'src/generators/container_generator.dart';
export 'src/generators/generator_utils.dart';

Builder viewStateBuilderFactory(BuilderOptions options) =>
    SharedPartBuilder([ViewStateGenerator()], 'view_state_builder');

Builder serviceStateBuilderFactory(BuilderOptions options) =>
    SharedPartBuilder([ServiceStateGenerator()], 'service_state_builder');

Builder viewModelBuilderFactory(BuilderOptions options) =>
    SharedPartBuilder([ViewModelGenerator()], 'view_model_builder');

Builder serviceBuilderFactory(BuilderOptions options) =>
    SharedPartBuilder([ServiceGenerator()], 'service_builder');

Builder viewBuilderFactory(BuilderOptions options) =>
    SharedPartBuilder([ViewGenerator()], 'view_builder');

Builder containerBuilderFactory(BuilderOptions options) =>
    AppContainerBuilder();

Builder deepLinksBuilderFactory(BuilderOptions options) =>
    AppDeepLinksBuilder();

class AppDeepLinksBuilder implements Builder {
  @override
  final Map<String, List<String>> buildExtensions = const {
    'lib/app_module.dart': ['lib/app_deep_links.g.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(buildStep.inputId)) {
      return;
    }
    final LibraryElement library = await resolver.libraryFor(buildStep.inputId);
    final List<LibraryReader> readers = _collectReaders(library);
    final Set<String> importUris = _collectImportUris(
      root: library,
      packageName: buildStep.inputId.package,
    );

    final Map<String, _GeneratedDeepLinkEntry> entriesByViewName =
        <String, _GeneratedDeepLinkEntry>{};
    for (final LibraryReader reader in readers) {
      for (final annotated in reader.annotatedWith(
        TypeChecker.fromRuntime(FoundryView),
      )) {
        final Element element = annotated.element;
        if (element is! ClassElement) {
          continue;
        }
        final ConstantReader annotation = annotated.annotation;
        final String? deepLink = annotation.peek('deepLink')?.stringValue;
        if (deepLink == null) {
          continue;
        }

        final bool hasArgs = _resolveArgsType(annotation) != null;
        entriesByViewName[element.displayName] = _GeneratedDeepLinkEntry(
          viewName: element.displayName,
          deepLink: deepLink,
          hasArgs: hasArgs,
        );
      }
    }

    final List<_GeneratedDeepLinkEntry> entries =
        entriesByViewName.values.toList()
          ..sort((a, b) => a.viewName.compareTo(b.viewName));

    _validateDeepLinkConflicts(entries);

    final AssetId output = AssetId(
      buildStep.inputId.package,
      'lib/app_deep_links.g.dart',
    );

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln(
      '// ignore_for_file: type=lint, unnecessary_cast, unused_import',
    );
    buffer.writeln('');
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln("import 'package:foundry_core/foundry_core.dart';");
    buffer.writeln(
      "import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';",
    );
    for (final String uri in importUris) {
      buffer.writeln("import '$uri';");
    }
    buffer.writeln('');
    buffer.writeln('/// Generated deep-link resolver and matcher tree.');
    buffer.writeln('abstract final class GeneratedDeepLinkResolver {');

    buffer.writeln(
      '  static final List<_DeepLinkMatcherEntry> _entries = <_DeepLinkMatcherEntry>[',
    );
    for (int i = 0; i < entries.length; i++) {
      final _GeneratedDeepLinkEntry entry = entries[i];
      buffer.writeln(
        "    _DeepLinkMatcherEntry(pattern: '${_escapeSingle(entry.deepLink)}', label: '${entry.viewName}Route', matcher: ${entry.viewName}Route.matchDeepLink),",
      );
    }
    buffer.writeln('  ];');
    buffer.writeln('');

    buffer.writeln(
      '  static final _DeepLinkTreeNode _root = _buildTree(_entries);',
    );
    buffer.writeln('');

    buffer.writeln('  static RouteConfig? match(Uri uri) {');
    buffer.writeln('    return _matchWithFallback(uri, allowFallback: true);');
    buffer.writeln('  }');
    buffer.writeln('');

    buffer.writeln(
      '  static Route<dynamic>? resolve(RouteSettings settings) {',
    );
    buffer.writeln("    final String rawName = settings.name ?? '/';");
    buffer.writeln('    final Uri uri = Uri.parse(rawName);');
    buffer.writeln('    final RouteConfig? route = match(uri);');
    buffer.writeln('    if (route == null) return null;');
    buffer.writeln('    return _buildRoute(route, settings);');
    buffer.writeln('  }');
    buffer.writeln('');

    buffer.writeln('  static String debugDescribeTree() {');
    buffer.writeln('    final StringBuffer out = StringBuffer();');
    buffer.writeln("    out.writeln('DeepLinkTree');");
    buffer.writeln("    _describeNode(_root, out, prefix: '', edge: '/');");
    buffer.writeln('    return out.toString();');
    buffer.writeln('  }');
    buffer.writeln('');

    buffer.writeln('  static _DeepLinkTreeNode _buildTree(');
    buffer.writeln('    List<_DeepLinkMatcherEntry> entries,');
    buffer.writeln('  ) {');
    buffer.writeln('    final _DeepLinkTreeNode root = _DeepLinkTreeNode();');
    buffer.writeln(
      '    for (int matcherIndex = 0; matcherIndex < entries.length; matcherIndex++) {',
    );
    buffer.writeln(
      '      final _DeepLinkMatcherEntry entry = entries[matcherIndex];',
    );
    buffer.writeln('      _insertPattern(root, entry.pattern, matcherIndex);');
    buffer.writeln('    }');
    buffer.writeln('    return root;');
    buffer.writeln('  }');
    buffer.writeln('');

    buffer.writeln('  static void _insertPattern(');
    buffer.writeln('    _DeepLinkTreeNode root,');
    buffer.writeln('    String pattern,');
    buffer.writeln('    int matcherIndex,');
    buffer.writeln('  ) {');
    buffer.writeln(
      '    final List<String> segments = Uri.parse(pattern).pathSegments;',
    );
    buffer.writeln('    _DeepLinkTreeNode node = root;');
    buffer.writeln('    for (final String segment in segments) {');
    buffer.writeln("      final bool isVariable = segment.startsWith(':');");
    buffer.writeln('      if (isVariable) {');
    buffer.writeln('        node.variableChild ??= _DeepLinkTreeNode();');
    buffer.writeln('        node = node.variableChild!;');
    buffer.writeln('      } else {');
    buffer.writeln('        node = node.literalChildren.putIfAbsent(');
    buffer.writeln('          segment,');
    buffer.writeln('          () => _DeepLinkTreeNode(),');
    buffer.writeln('        );');
    buffer.writeln('      }');
    buffer.writeln('    }');
    buffer.writeln('    node.terminalMatcherIndex = matcherIndex;');
    buffer.writeln('  }');
    buffer.writeln('');

    buffer.writeln('  static RouteConfig? _matchWithFallback(');
    buffer.writeln('    Uri uri, {');
    buffer.writeln('    required bool allowFallback,');
    buffer.writeln('  }) {');
    buffer.writeln('    final RouteConfig? route = _matchExact(uri);');
    buffer.writeln('    if (route != null) {');
    buffer.writeln('      Foundry.log(');
    buffer.writeln('        LogEvent(');
    buffer.writeln('          level: LogLevel.debug,');
    buffer.writeln("          tag: 'nav.deeplink.match',");
    buffer.writeln(
      "          message: 'Matched deep link \${uri.toString()}.',",
    );
    buffer.writeln('        ),');
    buffer.writeln('      );');
    buffer.writeln('      return route;');
    buffer.writeln('    }');
    buffer.writeln('');
    buffer.writeln('    Foundry.log(');
    buffer.writeln('      LogEvent(');
    buffer.writeln('        level: LogLevel.error,');
    buffer.writeln("        tag: 'nav.deeplink.miss',");
    buffer.writeln(
      "        message: 'No deep-link route matched URI \${uri.toString()}.',",
    );
    buffer.writeln('      ),');
    buffer.writeln('    );');
    buffer.writeln('');
    buffer.writeln('    if (!allowFallback) {');
    buffer.writeln('      return null;');
    buffer.writeln('    }');
    buffer.writeln('');
    buffer.writeln(
      '    final String? fallbackPath = Foundry.deepLinkFallbackPath;',
    );
    buffer.writeln('    if (fallbackPath == null || fallbackPath.isEmpty) {');
    buffer.writeln('      return null;');
    buffer.writeln('    }');
    buffer.writeln('');
    buffer.writeln('    final Uri fallbackUri = Uri.parse(fallbackPath);');
    buffer.writeln('    if (fallbackUri.path == uri.path) {');
    buffer.writeln('      return null;');
    buffer.writeln('    }');
    buffer.writeln('');
    buffer.writeln('    Foundry.log(');
    buffer.writeln('      LogEvent(');
    buffer.writeln('        level: LogLevel.warning,');
    buffer.writeln("        tag: 'nav.deeplink.fallback',");
    buffer.writeln(
      "        message: 'Attempting deep-link fallback to \${fallbackUri.toString()}.',",
    );
    buffer.writeln('      ),');
    buffer.writeln('    );');
    buffer.writeln('');
    buffer.writeln(
      '    return _matchWithFallback(fallbackUri, allowFallback: false);',
    );
    buffer.writeln('  }');
    buffer.writeln('');

    buffer.writeln('  static RouteConfig? _matchExact(Uri uri) {');
    buffer.writeln('    _DeepLinkTreeNode node = _root;');
    buffer.writeln('    for (final String segment in uri.pathSegments) {');
    buffer.writeln(
      '      final _DeepLinkTreeNode? literal = node.literalChildren[segment];',
    );
    buffer.writeln('      if (literal != null) {');
    buffer.writeln('        node = literal;');
    buffer.writeln('        continue;');
    buffer.writeln('      }');
    buffer.writeln(
      '      final _DeepLinkTreeNode? variable = node.variableChild;',
    );
    buffer.writeln('      if (variable != null) {');
    buffer.writeln('        node = variable;');
    buffer.writeln('        continue;');
    buffer.writeln('      }');
    buffer.writeln('      return null;');
    buffer.writeln('    }');
    buffer.writeln('');
    buffer.writeln('    final int? matcherIndex = node.terminalMatcherIndex;');
    buffer.writeln('    if (matcherIndex == null) {');
    buffer.writeln('      return null;');
    buffer.writeln('    }');
    buffer.writeln('');
    buffer.writeln(
      '    final _DeepLinkMatcherEntry entry = _entries[matcherIndex];',
    );
    buffer.writeln('    return entry.matcher(uri);');
    buffer.writeln('  }');
    buffer.writeln('');

    buffer.writeln('  static Route<dynamic>? _buildRoute(');
    buffer.writeln('    RouteConfig route,');
    buffer.writeln('    RouteSettings settings,');
    buffer.writeln('  ) {');
    buffer.writeln('    try {');
    buffer.writeln('      return route.buildDeepLink(settings);');
    buffer.writeln('    } catch (e) {');
    buffer.writeln('      Foundry.log(');
    buffer.writeln('        LogEvent(');
    buffer.writeln('          level: LogLevel.error,');
    buffer.writeln("          tag: 'nav.deeplink.resolve',");
    buffer.writeln(
      "          message: 'Failed to build deep-link route \${route.runtimeType}: \$e.',",
    );
    buffer.writeln('        ),');
    buffer.writeln('      );');
    buffer.writeln('      return null;');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln('');

    buffer.writeln('  static void _describeNode(');
    buffer.writeln('    _DeepLinkTreeNode node,');
    buffer.writeln('    StringBuffer out, {');
    buffer.writeln('    required String prefix,');
    buffer.writeln('    required String edge,');
    buffer.writeln('  }) {');
    buffer.writeln('    final int? matcherIndex = node.terminalMatcherIndex;');
    buffer.writeln('    final String terminal = matcherIndex == null');
    buffer.writeln("        ? ''");
    buffer.writeln("        : ' -> \${_entries[matcherIndex].label}';");
    buffer.writeln("    out.writeln('\${prefix}\${edge}\${terminal}');");
    buffer.writeln('');
    buffer.writeln(
      "    final List<String> literalKeys = node.literalChildren.keys.toList()..sort();",
    );
    buffer.writeln('    for (final String key in literalKeys) {');
    buffer.writeln('      _describeNode(');
    buffer.writeln('        node.literalChildren[key]!,');
    buffer.writeln('        out,');
    buffer.writeln("        prefix: '\${prefix}  ',");
    buffer.writeln('        edge: key,');
    buffer.writeln('      );');
    buffer.writeln('    }');
    buffer.writeln('');
    buffer.writeln('    if (node.variableChild != null) {');
    buffer.writeln('      _describeNode(');
    buffer.writeln('        node.variableChild!,');
    buffer.writeln('        out,');
    buffer.writeln("        prefix: '\${prefix}  ',");
    buffer.writeln("        edge: ':param',");
    buffer.writeln('      );');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln('');

    buffer.writeln('class _DeepLinkMatcherEntry {');
    buffer.writeln('  const _DeepLinkMatcherEntry({');
    buffer.writeln('    required this.pattern,');
    buffer.writeln('    required this.label,');
    buffer.writeln('    required this.matcher,');
    buffer.writeln('  });');
    buffer.writeln('');
    buffer.writeln('  final String pattern;');
    buffer.writeln('  final String label;');
    buffer.writeln('  final RouteConfig? Function(Uri) matcher;');
    buffer.writeln('}');
    buffer.writeln('');

    buffer.writeln('class _DeepLinkTreeNode {');
    buffer.writeln('  final Map<String, _DeepLinkTreeNode> literalChildren =');
    buffer.writeln('      <String, _DeepLinkTreeNode>{};');
    buffer.writeln('  _DeepLinkTreeNode? variableChild;');
    buffer.writeln('  int? terminalMatcherIndex;');
    buffer.writeln('}');

    await buildStep.writeAsString(output, buffer.toString());
  }
}

String _escapeSingle(String input) => input.replaceAll("'", "\\'");

String? _resolveArgsType(ConstantReader annotation) {
  final ConstantReader? peek = annotation.peek('args');
  if (peek == null || peek.isNull) {
    return null;
  }
  final String typeStr = peek.typeValue.getDisplayString(
    withNullability: false,
  );
  return typeStr == 'dynamic' || typeStr == 'Null' ? null : typeStr;
}

List<LibraryReader> _collectReaders(LibraryElement root) {
  final List<LibraryReader> readers = <LibraryReader>[];
  final Set<String> seen = <String>{};

  void visit(LibraryElement library) {
    final String key = library.source.uri.toString();
    if (!seen.add(key)) {
      return;
    }
    readers.add(LibraryReader(library));
    for (final LibraryElement exported in library.exportedLibraries) {
      visit(exported);
    }
  }

  visit(root);
  return readers;
}

Set<String> _collectImportUris({
  required LibraryElement root,
  required String packageName,
}) {
  final Set<String> uris = <String>{};
  final Set<String> seen = <String>{};

  void visit(LibraryElement library) {
    final Uri uri = library.source.uri;
    final String key = uri.toString();
    if (!seen.add(key)) {
      return;
    }

    if (uri.scheme == 'package' &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == packageName &&
        !uri.path.endsWith('app_module.dart')) {
      uris.add(uri.toString());
    }

    for (final LibraryElement exported in library.exportedLibraries) {
      visit(exported);
    }
  }

  visit(root);
  return uris;
}

void _validateDeepLinkConflicts(List<_GeneratedDeepLinkEntry> entries) {
  final Map<String, List<_GeneratedDeepLinkEntry>> byCanonical =
      <String, List<_GeneratedDeepLinkEntry>>{};

  for (final _GeneratedDeepLinkEntry entry in entries) {
    final String canonical = _canonicalPattern(entry.deepLink);
    byCanonical
        .putIfAbsent(canonical, () => <_GeneratedDeepLinkEntry>[])
        .add(entry);
  }

  final List<String> conflictMessages = <String>[];
  for (final MapEntry<String, List<_GeneratedDeepLinkEntry>> item
      in byCanonical.entries) {
    if (item.value.length <= 1) {
      continue;
    }
    final String routes = item.value
        .map((e) => '\n  - ${e.viewName}: ${e.deepLink}')
        .join();
    conflictMessages.add(
      'Ambiguous deep-link signature "${item.key}" is shared by:$routes',
    );
  }

  if (conflictMessages.isNotEmpty) {
    throw InvalidGenerationSourceError(
      'Deep-link generation failed due to ambiguous routes.\n'
      '${conflictMessages.join('\n')}',
    );
  }
}

String _canonicalPattern(String pattern) {
  final List<String> segments = Uri.parse(pattern).pathSegments;
  if (segments.isEmpty) {
    return '/';
  }
  final List<String> canonicalSegments = segments
      .map((segment) => segment.startsWith(':') ? ':' : segment)
      .toList();
  return '/${canonicalSegments.join('/')}';
}

class _GeneratedDeepLinkEntry {
  _GeneratedDeepLinkEntry({
    required this.viewName,
    required this.deepLink,
    required this.hasArgs,
  });

  final String viewName;
  final String deepLink;
  final bool hasArgs;
}
