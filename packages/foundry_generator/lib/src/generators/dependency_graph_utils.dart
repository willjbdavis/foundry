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

  final zero =
      inDegree.entries.where((e) => e.value == 0).map((e) => e.key).toList()
        ..sort();

  final result = <String>[];

  while (zero.isNotEmpty) {
    final node = zero.removeAt(0);
    result.add(node);

    for (final neighbor in graph[node]!) {
      inDegree[neighbor] = inDegree[neighbor]! - 1;
      if (inDegree[neighbor] == 0) {
        // keep queue ordered deterministically
        final insertAt = zero.indexWhere((n) => n.compareTo(neighbor) > 0);
        if (insertAt == -1) {
          zero.add(neighbor);
        } else {
          zero.insert(insertAt, neighbor);
        }
      }
    }
  }

  if (result.length != dependencyMap.length) {
    final unresolved =
        dependencyMap.keys.where((k) => !result.contains(k)).toList()..sort();
    throw StateError(
      'Circular dependency detected in @Service graph: ${unresolved.join(', ')}',
    );
  }

  return result;
}
