import 'package:flutter/material.dart';
import 'package:foundry_annotations/foundry_annotations.dart' as foundry;
import 'package:foundry_core/foundry_core.dart';

import 'settings_repository.dart';

part 'app_theme_model.g.dart';

@foundry.FoundryModel()
class AppThemeModel extends ChangeNotifier implements AsyncInitializable {
  AppThemeModel(this._settingsRepository);

  final SettingsRepository _settingsRepository;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  @override
  Future<void> initialize() async {
    _themeMode = _settingsRepository.loadThemeMode();
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (_themeMode == themeMode) {
      return;
    }

    _themeMode = themeMode;
    notifyListeners();
    await _settingsRepository.saveThemeMode(themeMode);
  }
}
