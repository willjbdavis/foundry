import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:foundry_annotations/foundry_annotations.dart';

/// Aggregating generator that reads all @Service and @ViewModel annotations
/// from the library pointed to by `lib/app_module.dart` and emits:
///
/// - `lib/app_container.g.dart`  — `registerGeneratedGraph(Scope)`
/// - This generator also emits a `FoundryTestScope` helper.
///
/// Usage:
/// 1. Create `lib/app_module.dart` that exports all feature libraries.
/// 2. Run `dart run build_runner build`.
class ContainerGenerator extends GeneratorForAnnotation<FoundryService> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    // Per-element generation just collects; the combining builder aggregates.
    // Emit a structured comment that the LibraryCombiningBuilder can parse.
    if (element is! ClassElement) return '';

    final className = element.displayName;
    final isStateful = annotation.read('stateful').boolValue;

    final dependsOnList = annotation.read('dependsOn');
    final deps = <String>[];
    if (!dependsOnList.isNull) {
      for (final dep in dependsOnList.listValue) {
        final typeName = dep.toTypeValue()?.getDisplayString(
          withNullability: false,
        );
        if (typeName != null) deps.add(typeName);
      }
    }

    // Detect constructor parameters for injection.
    final ctor =
        element.unnamedConstructor ??
        (element.constructors.isNotEmpty ? element.constructors.first : null);
    final ctorParams = ctor?.parameters ?? [];

    final buffer = StringBuffer();
    buffer.writeln('// [FOUNDRY:SERVICE] $className');
    buffer.writeln('// stateful=$isStateful');
    buffer.writeln('// dependsOn=${deps.join(",")}');
    buffer.writeln(
      '// ctorParams=${ctorParams.map((p) => '${p.type.getDisplayString(withNullability: false)}:${p.name}').join(",")}',
    );

    return buffer.toString();
  }
}

/// Aggregating generator for ViewModels — emits registration tag comments.
class ViewModelContainerGenerator
    extends GeneratorForAnnotation<FoundryViewModel> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) return '';

    final className = element.displayName;
    final ctor =
        element.unnamedConstructor ??
        (element.constructors.isNotEmpty ? element.constructors.first : null);
    final ctorParams = ctor?.parameters ?? [];

    final buffer = StringBuffer();
    buffer.writeln('// [FOUNDRY:VIEWMODEL] $className');
    buffer.writeln(
      '// ctorParams=${ctorParams.map((p) => '${p.type.getDisplayString(withNullability: false)}:${p.name}').join(",")}',
    );

    return buffer.toString();
  }
}

/// Top-level builder that post-processes the combined part to emit a clean
/// `registerGeneratedGraph()` function.
///
/// This is wired in `build.yaml` as a `LibraryCombiningBuilder` targeting
/// `lib/app_module.dart`.
class AppContainerBuilder implements Builder {
  @override
  final Map<String, List<String>> buildExtensions = const {
    'lib/app_module.dart': ['lib/app_container.g.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    // Collect all @Service and @ViewModel annotations across the library.
    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(buildStep.inputId)) return;
    final library = await resolver.libraryFor(buildStep.inputId);
    final readers = _collectReaders(library);
    final importUris = _collectImportUris(
      root: library,
      packageName: buildStep.inputId.package,
    );
    final servicesByName = <String, _ServiceEntry>{};
    for (final reader in readers) {
      for (final annotatedElement in reader.annotatedWith(
        TypeChecker.fromRuntime(FoundryService),
      )) {
        final element = annotatedElement.element;
        if (element is! ClassElement) continue;

        final annotation = annotatedElement.annotation;
        final isStateful = annotation.read('stateful').boolValue;
        final depsReader = annotation.read('dependsOn');
        final deps = <String>[];
        if (!depsReader.isNull) {
          for (final dep in depsReader.listValue) {
            final name = dep.toTypeValue()?.getDisplayString(
              withNullability: false,
            );
            if (name != null) deps.add(name);
          }
        }

        final ctor =
            element.unnamedConstructor ??
            (element.constructors.isNotEmpty
                ? element.constructors.first
                : null);
        final ctorParams = ctor?.parameters ?? [];
        final paramTypes = ctorParams
            .map((p) => p.type.getDisplayString(withNullability: false))
            .toList();
        final lifetime = _normalizeLifetime(
          annotation.peek('lifetime')?.stringValue,
          defaultValue: 'singleton',
        );

        servicesByName[element.displayName] = _ServiceEntry(
          name: element.displayName,
          isStateful: isStateful,
          dependsOn: deps,
          ctorParamTypes: paramTypes,
          lifetime: lifetime,
        );
      }
    }
    final rawServices = servicesByName.values.toList();
    final knownServiceNames = rawServices.map((m) => m.name).toSet();
    final services = rawServices
        .map(
          (m) => m.copyWith(
            constructorDependencies: inferConstructorServiceDependencies(
              m.ctorParamTypes,
              knownServiceNames,
            ),
          ),
        )
        .map(
          (m) => m.copyWith(
            mergedDependencies: mergeServiceDependencies(
              constructorDependencies: m.constructorDependencies,
              explicitDependsOn: m.dependsOn,
            ),
          ),
        )
        .toList();

    // ---- Collect @ViewModel entries ----
    final viewModelsByName = <String, _ViewModelEntry>{};
    for (final reader in readers) {
      for (final annotatedElement in reader.annotatedWith(
        TypeChecker.fromRuntime(FoundryViewModel),
      )) {
        final element = annotatedElement.element;
        if (element is! ClassElement) continue;

        final annotation = annotatedElement.annotation;
        final ctor =
            element.unnamedConstructor ??
            (element.constructors.isNotEmpty
                ? element.constructors.first
                : null);
        final ctorParams = ctor?.parameters ?? [];
        final paramTypes = ctorParams
            .map((p) => p.type.getDisplayString(withNullability: false))
            .toList();
        final lifetime = _normalizeLifetime(
          annotation.peek('lifetime')?.stringValue,
          defaultValue: 'scoped',
        );

        viewModelsByName[element.displayName] = _ViewModelEntry(
          name: element.displayName,
          ctorParamTypes: paramTypes,
          lifetime: lifetime,
        );
      }
    }
    final viewModels = viewModelsByName.values.toList();

    // ---- Topological sort of services ----
    final sortedServices = _topologicalSort(services);

    // ---- Collect @View entries for deep link coordinator ----
    final viewsWithDeepLinks = <_ViewDeepLinkEntry>[];
    final deepLinksByView = <String, _ViewDeepLinkEntry>{};
    for (final reader in readers) {
      for (final annotatedElement in reader.annotatedWith(
        TypeChecker.fromRuntime(FoundryView),
      )) {
        final element = annotatedElement.element;
        if (element is! ClassElement) continue;
        final annotation = annotatedElement.annotation;
        final deepLink = annotation.peek('deepLink')?.stringValue;
        if (deepLink != null) {
          deepLinksByView[element.displayName] = _ViewDeepLinkEntry(
            name: element.displayName,
            deepLink: deepLink,
          );
        }
      }
    }
    viewsWithDeepLinks.addAll(deepLinksByView.values);

    // ---- Generate app_container.g.dart ----
    await _writeContainerFile(
      buildStep,
      sortedServices,
      viewModels,
      viewsWithDeepLinks,
      importUris,
    );
  }

  Future<void> _writeContainerFile(
    BuildStep buildStep,
    List<_ServiceEntry> services,
    List<_ViewModelEntry> viewModels,
    List<_ViewDeepLinkEntry> viewsWithDeepLinks,
    Set<String> importUris,
  ) async {
    final outputId = AssetId(
      buildStep.inputId.package,
      'lib/app_container.g.dart',
    );

    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// ignore_for_file: type=lint, unused_import');
    buffer.writeln('');
    buffer.writeln("import 'package:foundry_core/foundry_core.dart';");
    if (viewsWithDeepLinks.isNotEmpty) {
      buffer.writeln(
        "import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';",
      );
    }
    for (final uri in importUris) {
      buffer.writeln("import '$uri';");
    }
    buffer.writeln('');
    buffer.writeln(
      '/// Registers all generated services and view models in [scope].',
    );
    buffer.writeln('///');
    buffer.writeln(
      '/// Call this once at app startup after creating your [GlobalScope].',
    );
    buffer.writeln('void registerGeneratedGraph(Scope scope) {');

    for (final service in services) {
      final String lifetime = 'Lifetime.${service.lifetime}';
      if (service.ctorParamTypes.isEmpty) {
        buffer.writeln(
          '  scope.register<${service.name}>((_) => ${service.name}(), lifetime: $lifetime);',
        );
      } else {
        final args = service.ctorParamTypes
            .map((t) => 's.resolve<$t>()')
            .join(', ');
        buffer.writeln(
          '  scope.register<${service.name}>((s) => ${service.name}($args), lifetime: $lifetime);',
        );
      }
    }

    for (final vm in viewModels) {
      final String lifetime = 'Lifetime.${vm.lifetime}';
      if (vm.ctorParamTypes.isEmpty) {
        buffer.writeln(
          '  scope.register<${vm.name}>((_) => ${vm.name}(), lifetime: $lifetime);',
        );
      } else {
        final args = vm.ctorParamTypes.map((t) => 's.resolve<$t>()').join(', ');
        buffer.writeln(
          '  scope.register<${vm.name}>((s) => ${vm.name}($args), lifetime: $lifetime);',
        );
      }
    }

    buffer.writeln('}');
    buffer.writeln('');
    buffer.writeln(
      '/// Resolves generated singleton services and runs async initialization.',
    );
    buffer.writeln('///');
    buffer.writeln(
      '/// Call this after [registerGeneratedGraph] during app startup.',
    );
    buffer.writeln(
      'Future<void> initializeGeneratedGraph(Scope scope) async {',
    );
    for (final service in services) {
      if (service.lifetime == 'singleton') {
        buffer.writeln(
          '  final Object _${service.name} = scope.resolve<${service.name}>();',
        );
        buffer.writeln('  if (_${service.name} is AsyncInitializable) {');
        buffer.writeln('    await _${service.name}.initialize();');
        buffer.writeln('  }');
      }
    }
    buffer.writeln('}');
    buffer.writeln('');

    // FoundryTestScope helper
    buffer.writeln(
      '/// Test helper: creates an isolated scope with optional dependency overrides.',
    );
    buffer.writeln('/// Usage:');
    buffer.writeln('///   final scope = FoundryTestScope.create(overrides: {');
    buffer.writeln("///     MyRepo: (s) => FakeMyRepo(),");
    buffer.writeln('///   });');
    buffer.writeln('abstract final class FoundryTestScope {');
    buffer.writeln('  static Scope create({');
    buffer.writeln(
      '    Map<Type, Object Function(Scope)> overrides = const {},',
    );
    buffer.writeln('  }) {');
    buffer.writeln('    final globalScope = GlobalScope.create();');
    buffer.writeln('    registerGeneratedGraph(globalScope);');
    buffer.writeln('    final testScope = globalScope.createChild();');
    buffer.writeln('    _applyOverrides(testScope, overrides);');
    buffer.writeln('    return testScope;');
    buffer.writeln('  }');
    buffer.writeln('');
    buffer.writeln('  static void _applyOverrides(');
    buffer.writeln('    Scope scope,');
    buffer.writeln('    Map<Type, Object Function(Scope)> overrides,');
    buffer.writeln('  ) {');
    buffer.writeln(
      '    // Type-keyed overrides are applied via runtime dispatch.',
    );
    buffer.writeln(
      '    // For compile-time safety, prefer explicit register<T>() calls on',
    );
    buffer.writeln('    // a child scope instead.');
    buffer.writeln('    overrides.forEach((type, factory) {');
    buffer.writeln('      _registerByType(scope, type, factory);');
    buffer.writeln('    });');
    buffer.writeln('  }');
    buffer.writeln('');
    buffer.writeln('  // ignore: prefer_function_declarations_over_variables');
    buffer.writeln(
      '  static final Map<Type, void Function(Scope, Object Function(Scope))>',
    );
    buffer.writeln('      _typeRegistry = {');
    for (final service in services) {
      buffer.writeln(
        '    ${service.name}: (s, f) => s.register<${service.name}>((inner) => f(inner) as ${service.name}, lifetime: Lifetime.${service.lifetime}),',
      );
    }
    for (final vm in viewModels) {
      buffer.writeln(
        '    ${vm.name}: (s, f) => s.register<${vm.name}>((inner) => f(inner) as ${vm.name}, lifetime: Lifetime.${vm.lifetime}),',
      );
    }
    buffer.writeln('  };');
    buffer.writeln('');
    buffer.writeln('  static void _registerByType(');
    buffer.writeln('    Scope scope,');
    buffer.writeln('    Type type,');
    buffer.writeln('    Object Function(Scope) factory,');
    buffer.writeln('  ) {');
    buffer.writeln('    final registrar = _typeRegistry[type];');
    buffer.writeln('    if (registrar != null) {');
    buffer.writeln('      registrar(scope, factory);');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln('}');

    // DeepLinkCoordinator
    if (viewsWithDeepLinks.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln(
        '/// Centralized deep link coordinator generated from @View(deepLink:...) annotations.',
      );
      buffer.writeln('abstract final class DeepLinkCoordinator {');
      buffer.writeln(
        '  /// Returns the first [RouteConfig] that matches [uri], or null.',
      );
      buffer.writeln('  static RouteConfig? match(Uri uri) {');
      buffer.writeln('    for (final matcher in _matchers) {');
      buffer.writeln('      final route = matcher(uri);');
      buffer.writeln('      if (route != null) return route;');
      buffer.writeln('    }');
      buffer.writeln('    return null;');
      buffer.writeln('  }');
      buffer.writeln('');
      buffer.writeln(
        '  static final List<RouteConfig? Function(Uri)> _matchers = [',
      );
      for (final view in viewsWithDeepLinks) {
        buffer.writeln('    ${view.name}Route.matchDeepLink,');
      }
      buffer.writeln('  ];');
      buffer.writeln('}');
    }

    await buildStep.writeAsString(outputId, buffer.toString());
  }
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

String _normalizeLifetime(String? value, {required String defaultValue}) {
  final String candidate = (value ?? '').trim().toLowerCase();
  final String normalized = candidate.isEmpty ? defaultValue : candidate;
  const Set<String> allowed = <String>{'singleton', 'scoped', 'transient'};
  if (!allowed.contains(normalized)) {
    throw StateError(
      'Unsupported lifetime "$normalized". '
      'Supported values: singleton, scoped, transient.',
    );
  }
  return normalized;
}

// ---------------------------------------------------------------------------
// Data services
// ---------------------------------------------------------------------------

class _ServiceEntry {
  _ServiceEntry({
    required this.name,
    required this.isStateful,
    required this.dependsOn,
    required this.ctorParamTypes,
    required this.lifetime,
    this.constructorDependencies = const <String>[],
    this.mergedDependencies = const <String>[],
  });

  final String name;
  final bool isStateful;
  final List<String> dependsOn;
  final List<String> ctorParamTypes;
  final String lifetime;
  final List<String> constructorDependencies;
  final List<String> mergedDependencies;

  _ServiceEntry copyWith({
    List<String>? constructorDependencies,
    List<String>? mergedDependencies,
  }) {
    return _ServiceEntry(
      name: name,
      isStateful: isStateful,
      dependsOn: dependsOn,
      ctorParamTypes: ctorParamTypes,
      lifetime: lifetime,
      constructorDependencies:
          constructorDependencies ?? this.constructorDependencies,
      mergedDependencies: mergedDependencies ?? this.mergedDependencies,
    );
  }
}

class _ViewModelEntry {
  _ViewModelEntry({
    required this.name,
    required this.ctorParamTypes,
    required this.lifetime,
  });
  final String name;
  final List<String> ctorParamTypes;
  final String lifetime;
}

class _ViewDeepLinkEntry {
  _ViewDeepLinkEntry({required this.name, required this.deepLink});
  final String name;
  final String deepLink;
}

/// Kahn's algorithm topological sort.  Throws [InvalidGenerationSourceError]
/// on cycles (since we're inside a builder we throw [StateError] instead —
/// build_runner will report it cleanly).
List<_ServiceEntry> _topologicalSort(List<_ServiceEntry> services) {
  final nameToEntry = {for (final m in services) m.name: m};
  final dependencyMap = <String, List<String>>{
    for (final m in services) m.name: m.mergedDependencies,
  };
  final sortedNames = topologicallySortDependencyGraph(dependencyMap);

  return sortedNames.map((name) => nameToEntry[name]!).toList();
}

/// Returns constructor parameter types that also exist as generated @Service names.
///
/// This keeps constructor wiring and dependency ordering aligned so dependency
/// declarations do not drift.
List<String> inferConstructorServiceDependencies(
  List<String> ctorParamTypes,
  Set<String> knownServiceNames,
) {
  final inferred = <String>[];
  for (final paramType in ctorParamTypes) {
    if (knownServiceNames.contains(paramType) &&
        !inferred.contains(paramType)) {
      inferred.add(paramType);
    }
  }
  return inferred;
}

/// Merges inferred constructor dependencies with explicit `dependsOn` metadata.
///
/// Constructor dependencies are primary and explicit dependencies are appended
/// only when they add extra ordering constraints.
List<String> mergeServiceDependencies({
  required List<String> constructorDependencies,
  required List<String> explicitDependsOn,
}) {
  final merged = <String>[...constructorDependencies];
  for (final dep in explicitDependsOn) {
    if (!merged.contains(dep)) {
      merged.add(dep);
    }
  }
  return merged;
}

/// Kahn's algorithm topological sort for a dependency map.
///
/// Input is `node -> dependencies`. The output is deterministic and
/// lexicographically ordered for ties.
List<String> topologicallySortDependencyGraph(
  Map<String, List<String>> dependencyMap,
) {
  final graph = <String, List<String>>{
    for (final node in dependencyMap.keys) node: <String>[],
  };

  final inDegree = {for (final node in dependencyMap.keys) node: 0};

  for (final entry in dependencyMap.entries) {
    final serviceName = entry.key;
    for (final dep in entry.value) {
      if (dependencyMap.containsKey(dep)) {
        graph[dep]!.add(serviceName);
        inDegree[serviceName] = (inDegree[serviceName] ?? 0) + 1;
      }
    }
  }

  for (final neighbors in graph.values) {
    neighbors.sort();
  }

  final queue = <String>[
    ...inDegree.entries.where((e) => e.value == 0).map((e) => e.key),
  ];
  queue.sort();
  final sorted = <String>[];

  while (queue.isNotEmpty) {
    final node = queue.removeAt(0);
    sorted.add(node);
    for (final neighbor in graph[node] ?? []) {
      inDegree[neighbor] = inDegree[neighbor]! - 1;
      if (inDegree[neighbor] == 0) {
        queue.add(neighbor);
      }
    }
    queue.sort();
  }

  if (sorted.length != dependencyMap.length) {
    final cycle = dependencyMap.keys
        .where((name) => !sorted.contains(name))
        .join(', ');
    throw StateError(
      'Circular dependency detected in @Service graph: $cycle. '
      'Check constructor dependencies and `dependsOn` fields for cycles.',
    );
  }

  return sorted;
}
