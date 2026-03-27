import 'package:flutter/material.dart';
import 'package:foundry_annotations/foundry_annotations.dart' as foundry;
import 'package:foundry_flutter/foundry_flutter.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

import '../exercises/exercises_database_view.dart';
import '../history/workout_history_view.dart';
import '../home/home_view.dart';
import '../settings/settings_view.dart';

part 'app_shell_view.g.dart';

@foundry.FoundryViewState()
class AppShellState with _$AppShellStateMixin {
  final int selectedTabIndex;
  final bool hasActiveWorkout;
  final int historyRefreshVersion;

  const AppShellState({
    this.selectedTabIndex = 0,
    this.hasActiveWorkout = false,
    this.historyRefreshVersion = 0,
  });
}

@foundry.FoundryViewModel()
class AppShellViewModel extends FoundryViewModel<AppShellState> {
  AppShellViewModel() {
    emitNewState(const AppShellState());
  }

  void selectTab(int index) {
    final int nextHistoryRefreshVersion = index == 1
        ? state.historyRefreshVersion + 1
        : state.historyRefreshVersion;
    emitNewState(
      state.copyWith(
        selectedTabIndex: index,
        historyRefreshVersion: nextHistoryRefreshVersion,
      ),
    );
  }
}

@foundry.FoundryView(route: '/', deepLink: '/')
class AppShellView extends FoundryView<AppShellViewModel, AppShellState> {
  const AppShellView({super.key});

  @override
  Widget buildWithState(
    BuildContext context,
    AppShellState? oldState,
    AppShellState state,
  ) {
    final AppShellViewModel viewModel = FoundryScope.of(
      context,
    ).resolve<AppShellViewModel>();

    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              scheme.primaryContainer.withValues(alpha: 0.35),
              scheme.surface,
              scheme.surface,
            ],
          ),
        ),
        child: IndexedStack(
          index: state.selectedTabIndex,
          children: <Widget>[
            const HomeView(),
            KeyedSubtree(
              key: ValueKey<int>(state.historyRefreshVersion),
              child: const WorkoutHistoryView(),
            ),
            const ExercisesDatabaseView(),
            const SettingsView(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.selectedTabIndex,
        onDestinationSelected: viewModel.selectTab,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            label: 'Exercises',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
