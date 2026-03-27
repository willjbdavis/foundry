import 'package:flutter/material.dart';
import 'package:foundry_annotations/foundry_annotations.dart' as foundry;
import 'package:foundry_flutter/foundry_flutter.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

import '../../core/theme/app_theme_model.dart';

part 'settings_view.g.dart';

@foundry.FoundryViewState()
class SettingsState with _$SettingsStateMixin {
  final ThemeMode selectedThemeMode;
  final bool isSaving;
  final String? error;

  const SettingsState({
    this.selectedThemeMode = ThemeMode.system,
    this.isSaving = false,
    this.error,
  });
}

@foundry.FoundryViewModel()
class SettingsViewModel extends FoundryViewModel<SettingsState> {
  SettingsViewModel(this._appThemeModel) {
    emitNewState(SettingsState(selectedThemeMode: _appThemeModel.themeMode));
  }

  final AppThemeModel _appThemeModel;

  void _syncFromThemeModel() {
    emitNewState(SettingsState(selectedThemeMode: _appThemeModel.themeMode));
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    if (state.selectedThemeMode == themeMode) {
      return;
    }

    emitNewState(
      SettingsState(selectedThemeMode: state.selectedThemeMode, isSaving: true),
    );

    try {
      await _appThemeModel.setThemeMode(themeMode);
      emitNewState(SettingsState(selectedThemeMode: _appThemeModel.themeMode));
    } catch (_) {
      emitNewState(
        SettingsState(
          selectedThemeMode: state.selectedThemeMode,
          error: 'Could not save theme preference. Please try again.',
        ),
      );
    }
  }

  @override
  Future<void> onInit() async {
    _appThemeModel.addListener(_syncFromThemeModel);
    _syncFromThemeModel();
  }

  @override
  Future<void> onDispose() async {
    _appThemeModel.removeListener(_syncFromThemeModel);
  }
}

@foundry.FoundryView(route: '/settings', deepLink: '/settings')
class SettingsView extends FoundryView<SettingsViewModel, SettingsState> {
  const SettingsView({super.key});

  @override
  Widget buildWithState(
    BuildContext context,
    SettingsState? oldState,
    SettingsState state,
  ) {
    final SettingsViewModel viewModel = FoundryScope.of(
      context,
    ).resolve<SettingsViewModel>();

    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: scheme.primaryContainer.withValues(alpha: 0.8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.palette_outlined,
                    color: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Make Lift Log match your training mood.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Theme', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Choose how Lift Log should look.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const <ButtonSegment<ThemeMode>>[
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        label: Text('System'),
                        icon: Icon(Icons.auto_mode_outlined),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: <ThemeMode>{state.selectedThemeMode},
                    onSelectionChanged: state.isSaving
                        ? null
                        : (Set<ThemeMode> selection) {
                            if (selection.isEmpty) {
                              return;
                            }
                            viewModel.updateThemeMode(selection.first);
                          },
                    showSelectedIcon: false,
                  ),
                ],
              ),
            ),
          ),
          if (state.isSaving) ...<Widget>[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (state.error != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              state.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
