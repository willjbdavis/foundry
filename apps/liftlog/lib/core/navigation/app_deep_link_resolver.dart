import 'package:flutter/material.dart';

import '../../features/about/about_view.dart';
import '../../features/exercises/exercise_editor_view.dart';
import '../../features/exercises/exercises_database_view.dart';
import '../../features/history/workout_detail_view.dart';
import '../../features/history/workout_history_view.dart';
import '../../features/home/home_view.dart';
import '../../features/settings/settings_view.dart';
import '../../features/shell/app_shell_view.dart';

class AppDeepLinkResolver {
  const AppDeepLinkResolver._();

  static Route<dynamic>? resolve(RouteSettings settings) {
    final String rawName = settings.name ?? '/';
    final Uri uri = Uri.parse(rawName);
    final List<String> segments = uri.pathSegments;

    if (uri.path == '/' || segments.isEmpty) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const AppShellView(),
      );
    }

    if (segments.length == 1 && segments[0] == 'home') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const HomeView(),
      );
    }

    if (segments.length == 1 && segments[0] == 'history') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const WorkoutHistoryView(),
      );
    }

    if (segments.length == 2 && segments[0] == 'history') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) =>
            WorkoutDetailView(args: WorkoutDetailArgs(workoutId: segments[1])),
      );
    }

    if (segments.length == 1 && segments[0] == 'exercises') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const ExercisesDatabaseView(),
      );
    }

    if (segments.length == 2 &&
        segments[0] == 'exercises' &&
        segments[1] == 'new') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const ExerciseEditorView(args: ExerciseEditorArgs()),
      );
    }

    if (segments.length == 3 &&
        segments[0] == 'exercises' &&
        segments[2] == 'edit') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => ExerciseEditorView(
          args: ExerciseEditorArgs(exerciseId: segments[1]),
        ),
      );
    }

    if (segments.length == 1 && segments[0] == 'settings') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const SettingsView(),
      );
    }

    if (segments.length == 1 && segments[0] == 'about') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const AboutView(),
      );
    }

    return null;
  }
}
