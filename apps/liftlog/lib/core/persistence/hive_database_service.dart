import 'package:hive_flutter/hive_flutter.dart';
import 'package:foundry_core/foundry_core.dart';
import 'package:foundry_annotations/foundry_annotations.dart' as foundry;

part 'hive_database_service.g.dart';

@foundry.FoundryService()
class HiveDatabaseService implements AsyncInitializable {
  static const String settingsBoxName = 'settingsBox';
  static const String exerciseDefinitionsBoxName = 'exerciseDefinitionsBox';
  static const String workoutsBoxName = 'workoutsBox';
  static const String activeWorkoutBoxName = 'activeWorkoutBox';

  bool _initialized = false;

  late final Box<dynamic> _settingsBox;
  late final Box<dynamic> _exerciseDefinitionsBox;
  late final Box<dynamic> _workoutsBox;
  late final Box<dynamic> _activeWorkoutBox;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await Hive.initFlutter();

    _settingsBox = await Hive.openBox<dynamic>(settingsBoxName);
    _exerciseDefinitionsBox = await Hive.openBox<dynamic>(
      exerciseDefinitionsBoxName,
    );
    _workoutsBox = await Hive.openBox<dynamic>(workoutsBoxName);
    _activeWorkoutBox = await Hive.openBox<dynamic>(activeWorkoutBoxName);

    _initialized = true;
  }

  Box<dynamic> get settingsBox => _settingsBox;
  Box<dynamic> get exerciseDefinitionsBox => _exerciseDefinitionsBox;
  Box<dynamic> get workoutsBox => _workoutsBox;
  Box<dynamic> get activeWorkoutBox => _activeWorkoutBox;
}
