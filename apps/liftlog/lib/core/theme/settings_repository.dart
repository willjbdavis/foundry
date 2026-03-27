import 'package:flutter/material.dart';
import 'package:foundry_annotations/foundry_annotations.dart' as foundry;

import '../persistence/hive_database_service.dart';

part 'settings_repository.g.dart';

@foundry.FoundryModel()
class SettingsRepository {
  SettingsRepository(this._databaseService);

  static const String _themePreferenceKey = 'theme_preference';

  final HiveDatabaseService _databaseService;

  ThemeMode loadThemeMode() {
    final String? storedValue =
        _databaseService.settingsBox.get(_themePreferenceKey) as String?;

    switch (storedValue) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final String serialized = switch (themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

    await _databaseService.settingsBox.put(_themePreferenceKey, serialized);
  }
}
