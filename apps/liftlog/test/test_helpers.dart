import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lift_log/core/persistence/hive_database_service.dart';

const Duration kPumpAndSettleTimeout = Duration(seconds: 12);

extension WidgetTesterPumpSafety on WidgetTester {
  Future<void> pumpAndSettleSafe({
    Duration step = const Duration(milliseconds: 100),
    Duration timeout = kPumpAndSettleTimeout,
  }) async {
    await pumpAndSettle(step, EnginePhase.sendSemanticsUpdate, timeout);
  }

  Future<void> pumpAndSettleTwice({
    Duration firstStep = const Duration(milliseconds: 100),
    Duration secondStep = const Duration(milliseconds: 100),
    Duration timeout = kPumpAndSettleTimeout,
  }) async {
    await pumpAndSettle(firstStep, EnginePhase.sendSemanticsUpdate, timeout);
    await pumpAndSettle(secondStep, EnginePhase.sendSemanticsUpdate, timeout);
  }
}

class TestHiveDatabaseService extends HiveDatabaseService {
  TestHiveDatabaseService(this._rootDirectory);

  final Directory _rootDirectory;
  final String _suffix = DateTime.now().microsecondsSinceEpoch.toString();

  late final Box<dynamic> _settingsBox;
  late final Box<dynamic> _exerciseDefinitionsBox;
  late final Box<dynamic> _workoutsBox;
  late final Box<dynamic> _activeWorkoutBox;

  @override
  Future<void> initialize() async {
    Hive.init(_rootDirectory.path);

    _settingsBox = await Hive.openBox<dynamic>('settingsBox_$_suffix');
    _exerciseDefinitionsBox = await Hive.openBox<dynamic>(
      'exerciseDefinitionsBox_$_suffix',
    );
    _workoutsBox = await Hive.openBox<dynamic>('workoutsBox_$_suffix');
    _activeWorkoutBox = await Hive.openBox<dynamic>(
      'activeWorkoutBox_$_suffix',
    );
  }

  @override
  Box<dynamic> get settingsBox => _settingsBox;

  @override
  Box<dynamic> get exerciseDefinitionsBox => _exerciseDefinitionsBox;

  @override
  Box<dynamic> get workoutsBox => _workoutsBox;

  @override
  Box<dynamic> get activeWorkoutBox => _activeWorkoutBox;

  Future<void> dispose() async {
    await _settingsBox.close();
    await _exerciseDefinitionsBox.close();
    await _workoutsBox.close();
    await _activeWorkoutBox.close();
    await Hive.close();
    if (_rootDirectory.existsSync()) {
      await _rootDirectory.delete(recursive: true);
    }
  }
}
