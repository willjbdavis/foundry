// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unnecessary_cast, unused_import

import 'package:flutter/material.dart';
import 'package:foundry_core/foundry_core.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';
import 'package:lift_log/core/persistence/hive_database_service.dart';
import 'package:lift_log/core/theme/app_theme_model.dart';
import 'package:lift_log/core/theme/settings_repository.dart';
import 'package:lift_log/core/domain/exercise_definition.dart';
import 'package:lift_log/core/domain/logged_exercise.dart';
import 'package:lift_log/core/domain/logged_set.dart';
import 'package:lift_log/core/domain/workout.dart';
import 'package:lift_log/core/models/rest_timer_service.dart';
import 'package:lift_log/core/models/workout_session_model.dart';
import 'package:lift_log/core/persistence/records/exercise_definition_record.dart';
import 'package:lift_log/core/persistence/records/active_workout_draft_record.dart';
import 'package:lift_log/core/persistence/records/logged_exercise_record.dart';
import 'package:lift_log/core/persistence/records/logged_set_record.dart';
import 'package:lift_log/core/persistence/records/workout_record.dart';
import 'package:lift_log/core/repositories/exercise_repository.dart';
import 'package:lift_log/core/repositories/workout_repository.dart';
import 'package:lift_log/features/about/about_view.dart';
import 'package:lift_log/features/exercises/exercise_editor_view.dart';
import 'package:lift_log/features/exercises/exercises_database_view.dart';
import 'package:lift_log/features/history/workout_detail_view.dart';
import 'package:lift_log/features/history/workout_history_view.dart';
import 'package:lift_log/features/home/home_view.dart';
import 'package:lift_log/features/settings/settings_view.dart';
import 'package:lift_log/features/shell/app_shell_view.dart';
import 'package:lift_log/features/workout/exercise_log_view.dart';
import 'package:lift_log/features/workout/exercise_picker_view.dart';
import 'package:lift_log/features/workout/workout_session_setup_view.dart';
import 'package:lift_log/features/workout/workout_summary_view.dart';

/// Generated deep-link resolver and matcher tree.
abstract final class GeneratedDeepLinkResolver {
  static final List<_DeepLinkMatcherEntry> _entries = <_DeepLinkMatcherEntry>[
    _DeepLinkMatcherEntry(pattern: '/about', label: 'AboutViewRoute', matcher: AboutViewRoute.matchDeepLink),
    _DeepLinkMatcherEntry(pattern: '/', label: 'AppShellViewRoute', matcher: AppShellViewRoute.matchDeepLink),
    _DeepLinkMatcherEntry(pattern: '/exercises/:exerciseId/edit', label: 'ExerciseEditorViewRoute', matcher: ExerciseEditorViewRoute.matchDeepLink),
    _DeepLinkMatcherEntry(pattern: '/exercises', label: 'ExercisesDatabaseViewRoute', matcher: ExercisesDatabaseViewRoute.matchDeepLink),
    _DeepLinkMatcherEntry(pattern: '/home', label: 'HomeViewRoute', matcher: HomeViewRoute.matchDeepLink),
    _DeepLinkMatcherEntry(pattern: '/settings', label: 'SettingsViewRoute', matcher: SettingsViewRoute.matchDeepLink),
    _DeepLinkMatcherEntry(pattern: '/history/:workoutId', label: 'WorkoutDetailViewRoute', matcher: WorkoutDetailViewRoute.matchDeepLink),
    _DeepLinkMatcherEntry(pattern: '/history', label: 'WorkoutHistoryViewRoute', matcher: WorkoutHistoryViewRoute.matchDeepLink),
  ];

  static final _DeepLinkTreeNode _root = _buildTree(_entries);

  static RouteConfig? match(Uri uri) {
    return _matchWithFallback(uri, allowFallback: true);
  }

  static Route<dynamic>? resolve(RouteSettings settings) {
    final String rawName = settings.name ?? '/';
    final Uri uri = Uri.parse(rawName);
    final RouteConfig? route = match(uri);
    if (route == null) return null;
    return _buildRoute(route, settings);
  }

  static String debugDescribeTree() {
    final StringBuffer out = StringBuffer();
    out.writeln('DeepLinkTree');
    _describeNode(_root, out, prefix: '', edge: '/');
    return out.toString();
  }

  static _DeepLinkTreeNode _buildTree(
    List<_DeepLinkMatcherEntry> entries,
  ) {
    final _DeepLinkTreeNode root = _DeepLinkTreeNode();
    for (int matcherIndex = 0; matcherIndex < entries.length; matcherIndex++) {
      final _DeepLinkMatcherEntry entry = entries[matcherIndex];
      _insertPattern(root, entry.pattern, matcherIndex);
    }
    return root;
  }

  static void _insertPattern(
    _DeepLinkTreeNode root,
    String pattern,
    int matcherIndex,
  ) {
    final List<String> segments = Uri.parse(pattern).pathSegments;
    _DeepLinkTreeNode node = root;
    for (final String segment in segments) {
      final bool isVariable = segment.startsWith(':');
      if (isVariable) {
        node.variableChild ??= _DeepLinkTreeNode();
        node = node.variableChild!;
      } else {
        node = node.literalChildren.putIfAbsent(
          segment,
          () => _DeepLinkTreeNode(),
        );
      }
    }
    node.terminalMatcherIndex = matcherIndex;
  }

  static RouteConfig? _matchWithFallback(
    Uri uri, {
    required bool allowFallback,
  }) {
    final RouteConfig? route = _matchExact(uri);
    if (route != null) {
      Foundry.log(
        LogEvent(
          level: LogLevel.debug,
          tag: 'nav.deeplink.match',
          message: 'Matched deep link ${uri.toString()}.',
        ),
      );
      return route;
    }

    Foundry.log(
      LogEvent(
        level: LogLevel.error,
        tag: 'nav.deeplink.miss',
        message: 'No deep-link route matched URI ${uri.toString()}.',
      ),
    );

    if (!allowFallback) {
      return null;
    }

    final String? fallbackPath = Foundry.deepLinkFallbackPath;
    if (fallbackPath == null || fallbackPath.isEmpty) {
      return null;
    }

    final Uri fallbackUri = Uri.parse(fallbackPath);
    if (fallbackUri.path == uri.path) {
      return null;
    }

    Foundry.log(
      LogEvent(
        level: LogLevel.warning,
        tag: 'nav.deeplink.fallback',
        message: 'Attempting deep-link fallback to ${fallbackUri.toString()}.',
      ),
    );

    return _matchWithFallback(fallbackUri, allowFallback: false);
  }

  static RouteConfig? _matchExact(Uri uri) {
    _DeepLinkTreeNode node = _root;
    for (final String segment in uri.pathSegments) {
      final _DeepLinkTreeNode? literal = node.literalChildren[segment];
      if (literal != null) {
        node = literal;
        continue;
      }
      final _DeepLinkTreeNode? variable = node.variableChild;
      if (variable != null) {
        node = variable;
        continue;
      }
      return null;
    }

    final int? matcherIndex = node.terminalMatcherIndex;
    if (matcherIndex == null) {
      return null;
    }

    final _DeepLinkMatcherEntry entry = _entries[matcherIndex];
    return entry.matcher(uri);
  }

  static Route<dynamic>? _buildRoute(
    RouteConfig route,
    RouteSettings settings,
  ) {
    try {
      return route.buildDeepLink(settings);
    } catch (e) {
      Foundry.log(
        LogEvent(
          level: LogLevel.error,
          tag: 'nav.deeplink.resolve',
          message: 'Failed to build deep-link route ${route.runtimeType}: $e.',
        ),
      );
      return null;
    }
  }

  static void _describeNode(
    _DeepLinkTreeNode node,
    StringBuffer out, {
    required String prefix,
    required String edge,
  }) {
    final int? matcherIndex = node.terminalMatcherIndex;
    final String terminal = matcherIndex == null
        ? ''
        : ' -> ${_entries[matcherIndex].label}';
    out.writeln('${prefix}${edge}${terminal}');

    final List<String> literalKeys = node.literalChildren.keys.toList()..sort();
    for (final String key in literalKeys) {
      _describeNode(
        node.literalChildren[key]!,
        out,
        prefix: '${prefix}  ',
        edge: key,
      );
    }

    if (node.variableChild != null) {
      _describeNode(
        node.variableChild!,
        out,
        prefix: '${prefix}  ',
        edge: ':param',
      );
    }
  }
}

class _DeepLinkMatcherEntry {
  const _DeepLinkMatcherEntry({
    required this.pattern,
    required this.label,
    required this.matcher,
  });

  final String pattern;
  final String label;
  final RouteConfig? Function(Uri) matcher;
}

class _DeepLinkTreeNode {
  final Map<String, _DeepLinkTreeNode> literalChildren =
      <String, _DeepLinkTreeNode>{};
  _DeepLinkTreeNode? variableChild;
  int? terminalMatcherIndex;
}
