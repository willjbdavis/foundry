// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:foundry_core/foundry_core.dart';
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

/// Registers all generated services and view models in [scope].
///
/// Call this once at app startup after creating your [GlobalScope].
void registerGeneratedGraph(Scope scope) {
  scope.register<HiveDatabaseService>((_) => HiveDatabaseService(), lifetime: Lifetime.singleton);
  scope.register<ExerciseRepository>((s) => ExerciseRepository(s.resolve<HiveDatabaseService>()), lifetime: Lifetime.singleton);
  scope.register<RestTimerService>((_) => RestTimerService(), lifetime: Lifetime.singleton);
  scope.register<SettingsRepository>((s) => SettingsRepository(s.resolve<HiveDatabaseService>()), lifetime: Lifetime.singleton);
  scope.register<AppThemeModel>((s) => AppThemeModel(s.resolve<SettingsRepository>()), lifetime: Lifetime.singleton);
  scope.register<WorkoutRepository>((s) => WorkoutRepository(s.resolve<HiveDatabaseService>()), lifetime: Lifetime.singleton);
  scope.register<WorkoutSessionModel>((s) => WorkoutSessionModel(s.resolve<WorkoutRepository>()), lifetime: Lifetime.singleton);
  scope.register<AboutViewModel>((_) => AboutViewModel(), lifetime: Lifetime.scoped);
  scope.register<ExerciseEditorViewModel>((s) => ExerciseEditorViewModel(s.resolve<ExerciseRepository>()), lifetime: Lifetime.scoped);
  scope.register<ExercisesDatabaseViewModel>((s) => ExercisesDatabaseViewModel(s.resolve<ExerciseRepository>()), lifetime: Lifetime.scoped);
  scope.register<WorkoutDetailViewModel>((s) => WorkoutDetailViewModel(s.resolve<WorkoutRepository>()), lifetime: Lifetime.scoped);
  scope.register<WorkoutHistoryViewModel>((s) => WorkoutHistoryViewModel(s.resolve<WorkoutRepository>()), lifetime: Lifetime.scoped);
  scope.register<HomeViewModel>((s) => HomeViewModel(s.resolve<WorkoutSessionModel>(), s.resolve<WorkoutRepository>()), lifetime: Lifetime.scoped);
  scope.register<SettingsViewModel>((s) => SettingsViewModel(s.resolve<AppThemeModel>()), lifetime: Lifetime.scoped);
  scope.register<AppShellViewModel>((_) => AppShellViewModel(), lifetime: Lifetime.scoped);
  scope.register<ExerciseLogViewModel>((s) => ExerciseLogViewModel(s.resolve<WorkoutSessionModel>(), s.resolve<RestTimerService>()), lifetime: Lifetime.scoped);
  scope.register<ExercisePickerViewModel>((s) => ExercisePickerViewModel(s.resolve<WorkoutSessionModel>(), s.resolve<ExerciseRepository>()), lifetime: Lifetime.scoped);
  scope.register<WorkoutSessionSetupViewModel>((s) => WorkoutSessionSetupViewModel(s.resolve<WorkoutSessionModel>()), lifetime: Lifetime.scoped);
  scope.register<WorkoutSummaryViewModel>((s) => WorkoutSummaryViewModel(s.resolve<WorkoutSessionModel>()), lifetime: Lifetime.scoped);
}

/// Resolves generated singleton services and runs async initialization.
///
/// Call this after [registerGeneratedGraph] during app startup.
Future<void> initializeGeneratedGraph(Scope scope) async {
  final Object _HiveDatabaseService = scope.resolve<HiveDatabaseService>();
  if (_HiveDatabaseService is AsyncInitializable) {
    await _HiveDatabaseService.initialize();
  }
  final Object _ExerciseRepository = scope.resolve<ExerciseRepository>();
  if (_ExerciseRepository is AsyncInitializable) {
    await _ExerciseRepository.initialize();
  }
  final Object _RestTimerService = scope.resolve<RestTimerService>();
  if (_RestTimerService is AsyncInitializable) {
    await _RestTimerService.initialize();
  }
  final Object _SettingsRepository = scope.resolve<SettingsRepository>();
  if (_SettingsRepository is AsyncInitializable) {
    await _SettingsRepository.initialize();
  }
  final Object _AppThemeModel = scope.resolve<AppThemeModel>();
  if (_AppThemeModel is AsyncInitializable) {
    await _AppThemeModel.initialize();
  }
  final Object _WorkoutRepository = scope.resolve<WorkoutRepository>();
  if (_WorkoutRepository is AsyncInitializable) {
    await _WorkoutRepository.initialize();
  }
  final Object _WorkoutSessionModel = scope.resolve<WorkoutSessionModel>();
  if (_WorkoutSessionModel is AsyncInitializable) {
    await _WorkoutSessionModel.initialize();
  }
}

/// Test helper: creates an isolated scope with optional dependency overrides.
/// Usage:
///   final scope = FoundryTestScope.create(overrides: {
///     MyRepo: (s) => FakeMyRepo(),
///   });
abstract final class FoundryTestScope {
  static Scope create({
    Map<Type, Object Function(Scope)> overrides = const {},
  }) {
    final globalScope = GlobalScope.create();
    registerGeneratedGraph(globalScope);
    final testScope = globalScope.createChild();
    _applyOverrides(testScope, overrides);
    return testScope;
  }

  static void _applyOverrides(
    Scope scope,
    Map<Type, Object Function(Scope)> overrides,
  ) {
    // Type-keyed overrides are applied via runtime dispatch.
    // For compile-time safety, prefer explicit register<T>() calls on
    // a child scope instead.
    overrides.forEach((type, factory) {
      _registerByType(scope, type, factory);
    });
  }

  // ignore: prefer_function_declarations_over_variables
  static final Map<Type, void Function(Scope, Object Function(Scope))>
      _typeRegistry = {
    HiveDatabaseService: (s, f) => s.register<HiveDatabaseService>((inner) => f(inner) as HiveDatabaseService, lifetime: Lifetime.singleton),
    ExerciseRepository: (s, f) => s.register<ExerciseRepository>((inner) => f(inner) as ExerciseRepository, lifetime: Lifetime.singleton),
    RestTimerService: (s, f) => s.register<RestTimerService>((inner) => f(inner) as RestTimerService, lifetime: Lifetime.singleton),
    SettingsRepository: (s, f) => s.register<SettingsRepository>((inner) => f(inner) as SettingsRepository, lifetime: Lifetime.singleton),
    AppThemeModel: (s, f) => s.register<AppThemeModel>((inner) => f(inner) as AppThemeModel, lifetime: Lifetime.singleton),
    WorkoutRepository: (s, f) => s.register<WorkoutRepository>((inner) => f(inner) as WorkoutRepository, lifetime: Lifetime.singleton),
    WorkoutSessionModel: (s, f) => s.register<WorkoutSessionModel>((inner) => f(inner) as WorkoutSessionModel, lifetime: Lifetime.singleton),
    AboutViewModel: (s, f) => s.register<AboutViewModel>((inner) => f(inner) as AboutViewModel, lifetime: Lifetime.scoped),
    ExerciseEditorViewModel: (s, f) => s.register<ExerciseEditorViewModel>((inner) => f(inner) as ExerciseEditorViewModel, lifetime: Lifetime.scoped),
    ExercisesDatabaseViewModel: (s, f) => s.register<ExercisesDatabaseViewModel>((inner) => f(inner) as ExercisesDatabaseViewModel, lifetime: Lifetime.scoped),
    WorkoutDetailViewModel: (s, f) => s.register<WorkoutDetailViewModel>((inner) => f(inner) as WorkoutDetailViewModel, lifetime: Lifetime.scoped),
    WorkoutHistoryViewModel: (s, f) => s.register<WorkoutHistoryViewModel>((inner) => f(inner) as WorkoutHistoryViewModel, lifetime: Lifetime.scoped),
    HomeViewModel: (s, f) => s.register<HomeViewModel>((inner) => f(inner) as HomeViewModel, lifetime: Lifetime.scoped),
    SettingsViewModel: (s, f) => s.register<SettingsViewModel>((inner) => f(inner) as SettingsViewModel, lifetime: Lifetime.scoped),
    AppShellViewModel: (s, f) => s.register<AppShellViewModel>((inner) => f(inner) as AppShellViewModel, lifetime: Lifetime.scoped),
    ExerciseLogViewModel: (s, f) => s.register<ExerciseLogViewModel>((inner) => f(inner) as ExerciseLogViewModel, lifetime: Lifetime.scoped),
    ExercisePickerViewModel: (s, f) => s.register<ExercisePickerViewModel>((inner) => f(inner) as ExercisePickerViewModel, lifetime: Lifetime.scoped),
    WorkoutSessionSetupViewModel: (s, f) => s.register<WorkoutSessionSetupViewModel>((inner) => f(inner) as WorkoutSessionSetupViewModel, lifetime: Lifetime.scoped),
    WorkoutSummaryViewModel: (s, f) => s.register<WorkoutSummaryViewModel>((inner) => f(inner) as WorkoutSummaryViewModel, lifetime: Lifetime.scoped),
  };

  static void _registerByType(
    Scope scope,
    Type type,
    Object Function(Scope) factory,
  ) {
    final registrar = _typeRegistry[type];
    if (registrar != null) {
      registrar(scope, factory);
    }
  }
}
