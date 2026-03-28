# Lift Log Technical Specification

## Purpose

Lift Log is a Foundry MVVM demo application for logging weightlifting workouts. The app is intentionally small, but it should still demonstrate a production-shaped architecture:

- local persistence with Hive
- screen state managed with the Foundry MVVM framework
- typed routing through Foundry navigation
- Material theming with a distinct Lift Log brand

## Technology Stack

- Flutter
- Material 3 UI
- Foundry MVVM packages from this workspace
  - `foundry_annotations`
  - `foundry_flutter`
  - `foundry_navigation_flutter`
  - `foundry_generator`
- Hive for local persistence
- `build_runner` for generated state, ViewModel helpers, routes, and DI graph

## Architectural Rules

- Every screen is a Foundry `@FoundryView()` with a matching `@FoundryViewModel()` and `@FoundryViewState()` unless the screen is truly static.
- Persistent app data lives in Hive.
- Transient screen state lives in Foundry ViewState classes.
- Shared business logic and persistence coordination live in `@FoundryService()` classes and repository or service classes.
- Only one active workout draft may exist at a time.
- Theme preference is persisted and applied app-wide.

## App Bootstrap

### Required app setup

- create the root Foundry `Scope`
- register the generated dependency graph from `app_container.g.dart`
- run generated startup initialization before UI mounts
- wrap the app in `FoundryScope`
- configure `FoundryNavigator` with a `FlutterNavigatorAdapter`
- configure `FoundryNavigation` with the same default adapter
- ensure startup singletons are initialized before rendering the first view

### Root composition

- `main.dart`
  - initializes Flutter bindings
  - configures Foundry DI and navigation
  - calls `registerGeneratedGraph(scope)`
  - awaits `initializeGeneratedGraph(scope)`
  - runs `LiftLogApp`
- `LiftLogApp`
  - creates the Material theme
  - reads persisted theme preference
  - sets `home` to `AppShellView`

### Startup sequence

1. Create root `GlobalScope`
2. Call `registerGeneratedGraph(scope)`
3. Call `await initializeGeneratedGraph(scope)`
4. Configure navigator (`FoundryNavigator` + `FoundryNavigation`) and mount app widgets

`HiveDatabaseService` initialization is part of generated startup through
`AsyncInitializable`, so Hive setup participates in dependency-safe ordering.

## Theming

### UI framework

- Use Material 3.
- Build a complete `ThemeData` for both light and dark modes.
- Persist the selected `ThemeMode` through settings.

### Brand direction

The visual brand should use electric colors with restraint. They should feel vivid without destroying contrast or legibility.

#### Brand palette

- Electric Blue: `#00C2FF`
- Electric Green: `#39FF88`
- Electric Yellow: `#FFE44D`
- Electric Purple: `#B05CFF`

#### Light theme guidance

- Primary: Electric Blue
- Secondary: Electric Green
- Tertiary: Electric Purple
- Highlight or chart accent: Electric Yellow
- Backgrounds and surfaces should stay neutral and bright so electric colors remain accents rather than full-page fills.
- Avoid yellow for long-form text or primary buttons on white surfaces.

#### Dark theme guidance

- Primary: Electric Green or Electric Blue depending on contrast tests
- Secondary: Electric Purple
- Tertiary and callout accent: Electric Yellow used sparingly
- Surfaces should be dark charcoal or near-black rather than pure black.
- Electric colors can be used more aggressively in dark mode because they retain contrast better on dark surfaces.

### Theme service contract

- `AppThemeModel` stores the active theme preference.
- `SettingsViewModel` updates theme preference.
- App startup loads the persisted theme mode before `MaterialApp` is built.

## Persistence Design

## Hive Strategy

Use Hive as the local database. Keep the storage model explicit and versionable.

### Hive boxes

- `settingsBox`
  - stores app-level preferences
- `exerciseDefinitionsBox`
  - stores exercise definitions keyed by exercise id
- `workoutsBox`
  - stores completed workouts keyed by workout id
- `activeWorkoutBox`
  - stores the single in-progress workout draft

### Hive records

These records can be direct Hive objects or DTO-like persistence classes. The important part is to separate persistence shape from view state.

- `AppSettingsRecord`
- `ExerciseDefinitionRecord`
- `LoggedSetRecord`
- `LoggedExerciseRecord`
- `WorkoutRecord`
- `ActiveWorkoutDraftRecord`

### Persistence notes

- Persist the active workout draft after each meaningful mutation so the user can resume after app termination.
- Completed workouts should be immutable once saved, unless editing completed workouts is added later.
- Use ISO-8601 strings or epoch milliseconds consistently for timestamps.
- Use string ids for all records to keep route args and Hive keys simple.

## Core Models and Services

## Domain services

These are the logical app models that business logic works with:

- `Workout`
  - `id`
  - `title`
  - `date`
  - `notes`
  - `exercises`
  - `createdAt`
  - `completedAt`
- `LoggedExercise`
  - `exerciseId`
  - `displayName`
  - `notes`
  - `sortOrder`
  - `sets`
- `LoggedSet`
  - `id`
  - `reps`
  - `weight`
  - `setType`
  - `loggedAt`
- `ExerciseDefinition`
  - `id`
  - `name`
  - `description`
  - `createdAt`
  - `updatedAt`

## Foundry models and service classes

### `HiveDatabaseService`

Central infrastructure service for Hive setup and box access.

Suggested responsibilities:

- initialize Hive
- register adapters
- open boxes
- expose typed box handles
- coordinate schema version migrations if added later

Suggested API outline:

```dart
class HiveDatabaseService {
  Future<void> initialize();

  Box<AppSettingsRecord> get settingsBox;
  Box<ExerciseDefinitionRecord> get exerciseDefinitionsBox;
  Box<WorkoutRecord> get workoutsBox;
  Box<ActiveWorkoutDraftRecord> get activeWorkoutBox;
}
```

### `WorkoutRepository`

Responsibilities:

- create a new active workout draft
- load active workout draft
- save draft updates
- discard draft
- finalize draft into completed workout
- list completed workouts
- fetch completed workout by id

### `ExerciseRepository`

Responsibilities:

- list exercises
- get exercise by id
- create exercise
- update exercise
- optionally delete exercise if later allowed

### `SettingsRepository`

Responsibilities:

- load theme preference
- persist theme preference

### `WorkoutSessionModel`

Foundry `@FoundryService(stateful: true)` candidate for the active workout session.

Responsibilities:

- hold the current active draft in memory
- expose mutations for title, notes, exercises, and sets
- persist changes via `WorkoutRepository`
- provide the current draft to `ExerciseLogViewModel` and `WorkoutSummaryViewModel`

### `AppThemeModel`

Foundry `@FoundryService(stateful: true)` candidate for the app theme state.

Responsibilities:

- load persisted theme preference on startup
- emit theme changes
- persist updates through `SettingsRepository`

## View Inventory

Each view below includes route, deep-link policy, args, state, and primary ViewModel responsibilities.

## Routing and deep-link policy

- Internal route paths should be declared on every `@FoundryView(route: ...)`.
- Public deep links should only target stable screens.
- Active workout flow screens are primarily internal routes because they depend on local draft state.
- Foundry currently generates working deep-link matching cleanly for no-args routes.
- For args-based deep links, use `deepLinkArgsFactory` and an app-level deep-link resolver until generated args-based matcher support is fully complete.

## Views

### `AppShellView`

- Route: `/`
- Deep link: `/`
- View args: none
- ViewModel: `AppShellViewModel`
- State: `AppShellState`

#### `AppShellState`

- `selectedTabIndex`
- `hasActiveWorkout`

#### Responsibilities

- host bottom navigation
- route between Home, History, and Exercises tabs
- expose shell-level entry points to Settings and About
- surface whether an active workout exists

### `HomeView`

- Route: `/home`
- Deep link: `/home`
- View args: none
- ViewModel: `HomeViewModel`
- State: `HomeState`

#### `HomeState`

- `isLoading`
- `hasActiveWorkout`
- `activeWorkoutTitle`
- `recentWorkouts`
- `error`

#### Responsibilities

- display dashboard content
- show start-workout CTA
- show resume-workout CTA if draft exists
- show recent completed workouts

### `WorkoutHistoryView`

- Route: `/history`
- Deep link: `/history`
- View args: none
- ViewModel: `WorkoutHistoryViewModel`
- State: `WorkoutHistoryState`

#### `WorkoutHistoryState`

- `isLoading`
- `workouts`
- `searchQuery`
- `error`

#### Responsibilities

- list all completed workouts
- support search or basic filtering later
- open workout detail

### `WorkoutDetailView`

- Route: `/history/detail`
- Deep link: `/history/:workoutId`
- View args: `WorkoutDetailArgs`
- ViewModel: `WorkoutDetailViewModel`
- State: `WorkoutDetailState`

#### `WorkoutDetailArgs`

- `workoutId`

#### `WorkoutDetailState`

- `isLoading`
- `workout`
- `error`

#### Responsibilities

- load one completed workout
- render all exercises and sets read-only

### `ExercisesDatabaseView`

- Route: `/exercises`
- Deep link: `/exercises`
- View args: none
- ViewModel: `ExercisesDatabaseViewModel`
- State: `ExercisesDatabaseState`

#### `ExercisesDatabaseState`

- `isLoading`
- `exercises`
- `searchQuery`
- `error`

#### Responsibilities

- list exercise definitions
- filter or search exercises
- open create and edit flows

### `ExerciseEditorView`

- Route: `/exercises/editor`
- Deep link: `/exercises/new`
- Alternate deep link: `/exercises/:exerciseId/edit`
- View args: `ExerciseEditorArgs`
- ViewModel: `ExerciseEditorViewModel`
- State: `ExerciseEditorState`

#### `ExerciseEditorArgs`

- `exerciseId`
- `returnToWorkoutDraftId`
- `selectAfterSave`

#### `ExerciseEditorState`

- `isLoading`
- `isSaving`
- `isEditMode`
- `name`
- `description`
- `validationErrors`
- `error`

#### Responsibilities

- create or edit an exercise definition
- validate name uniqueness and required name input
- optionally return the newly created exercise to the workout flow

### `WorkoutSessionSetupView`

- Route: `/workout/setup`
- Deep link: internal only
- View args: `WorkoutSessionSetupArgs`
- ViewModel: `WorkoutSessionSetupViewModel`
- State: `WorkoutSessionSetupState`

#### `WorkoutSessionSetupArgs`

- `draftId`
- `isResume`

#### `WorkoutSessionSetupState`

- `isLoading`
- `isSaving`
- `title`
- `date`
- `notes`
- `hasExistingDraft`
- `error`

#### Responsibilities

- create a draft or resume an existing draft
- capture workout metadata before detailed logging starts

### `ExercisePickerView`

- Route: `/workout/pick-exercise`
- Deep link: internal only
- View args: `ExercisePickerArgs`
- ViewModel: `ExercisePickerViewModel`
- State: `ExercisePickerState`

#### `ExercisePickerArgs`

- `draftId`
- `excludeExerciseIds`
- `selectOnReturn`

#### `ExercisePickerState`

- `isLoading`
- `availableExercises`
- `searchQuery`
- `selectedExerciseId`
- `error`

#### Responsibilities

- list reusable exercise definitions
- allow selecting one to add to the active workout
- branch to exercise creation when needed

### `ExerciseLogView`

- Route: `/workout/log`
- Deep link: internal only
- View args: `ExerciseLogArgs`
- ViewModel: `ExerciseLogViewModel`
- State: `ExerciseLogState`

#### `ExerciseLogArgs`

- `draftId`
- `initialExerciseIndex`

#### `ExerciseLogState`

- `isLoading`
- `isSaving`
- `draftTitle`
- `exerciseTabs`
- `selectedExerciseIndex`
- `currentSetReps`
- `currentSetWeight`
- `timerMinutes`
- `timerSeconds`
- `timerStatus`
- `error`

#### Responsibilities

- show one tab per exercise in the active draft
- add, edit, and remove sets
- add or remove exercises from the draft
- control the rest timer
- navigate to workout summary
- discard or save draft progress

### `WorkoutSummaryView`

- Route: `/workout/summary`
- Deep link: internal only
- View args: `WorkoutSummaryArgs`
- ViewModel: `WorkoutSummaryViewModel`
- State: `WorkoutSummaryState`

#### `WorkoutSummaryArgs`

- `draftId`

#### `WorkoutSummaryState`

- `isLoading`
- `isSaving`
- `draft`
- `totalExercises`
- `totalSets`
- `estimatedVolume`
- `error`

#### Responsibilities

- review draft before completion
- finalize and save the workout
- navigate to detail or home on success

### `SettingsView`

- Route: `/settings`
- Deep link: `/settings`
- View args: none
- ViewModel: `SettingsViewModel`
- State: `SettingsState`

#### `SettingsState`

- `selectedThemeMode`
- `availableThemeModes`
- `isSaving`
- `error`

#### Responsibilities

- display and persist theme choice

### `AboutView`

- Route: `/about`
- Deep link: `/about`
- View args: none
- ViewModel: `AboutViewModel`
- State: `AboutState`

#### `AboutState`

- `appName`
- `appVersion`
- `frameworkSummary`

#### Responsibilities

- display app metadata
- explain that Lift Log is a Foundry MVVM sample

## Route args definitions

All routed views with parameters should use Foundry `RouteArgs` classes.

Suggested args classes:

```dart
class WorkoutDetailArgs extends RouteArgs {
  const WorkoutDetailArgs({required this.workoutId});
  final String workoutId;
}

class ExerciseEditorArgs extends RouteArgs {
  const ExerciseEditorArgs({
    this.exerciseId,
    this.returnToWorkoutDraftId,
    this.selectAfterSave = false,
  });

  final String? exerciseId;
  final String? returnToWorkoutDraftId;
  final bool selectAfterSave;
}

class ExerciseLogArgs extends RouteArgs {
  const ExerciseLogArgs({
    required this.draftId,
    this.initialExerciseIndex = 0,
  });

  final String draftId;
  final int initialExerciseIndex;
}
```

## Navigation map

All page-level navigation uses `FoundryNavigation.instance.pushDefault(route)` for pushing and `popDefault()` / `popToRootDefault()` for popping. Dialog dismissals use Flutter's `Navigator.of(context).pop()` directly.

### Primary navigation

- `AppShellView` hosts:
  - `HomeView`
  - `WorkoutHistoryView`
  - `ExercisesDatabaseView`

### Shell-level secondary navigation

- `AppShellView` opens:
  - `SettingsView`
  - `AboutView`

### Workout flow navigation

- `HomeView` -> `WorkoutSessionSetupView`
- `WorkoutSessionSetupView` -> `ExercisePickerView`
- `ExercisePickerView` -> `ExerciseLogView`
- `ExerciseLogView` -> `ExercisePickerView` for add-exercise
- `ExercisePickerView` -> `ExerciseEditorView` when an exercise must be created
- `ExerciseLogView` -> `WorkoutSummaryView`
- `WorkoutSummaryView` -> `WorkoutDetailView` or `HomeView`

### Exercise management navigation

- `ExercisesDatabaseView` -> `ExerciseEditorView`

### History navigation

- `WorkoutHistoryView` -> `WorkoutDetailView`

## Deep-link map

These deep links are stable and worth exposing externally:

- `/`
- `/home`
- `/history`
- `/history/:workoutId`
- `/exercises`
- `/exercises/new`
- `/exercises/:exerciseId/edit`
- `/settings`
- `/about`

These routes should remain internal-only:

- `/workout/setup`
- `/workout/pick-exercise`
- `/workout/log`
- `/workout/summary`

Reason:

- they depend on an active local draft
- they are not stable entry points from outside the app
- they are better restored from persisted local session state than from public URIs

## Suggested feature folders

```text
lib/
  app.dart
  app_module.dart
  app_container.g.dart
  app_deep_links.g.dart
  bootstrap/
    app_bootstrap.dart
  core/
    theme/
      app_theme.dart
      theme_palette.dart
    persistence/
      hive_database_service.dart
      hive_adapters.dart
  features/
    shell/
      app_shell_view.dart
      app_shell_view_model.dart
      app_shell_state.dart
    home/
      home_view.dart
      home_view_model.dart
      home_state.dart
    history/
      workout_history_view.dart
      workout_history_view_model.dart
      workout_history_state.dart
      workout_detail_view.dart
      workout_detail_view_model.dart
      workout_detail_state.dart
      workout_detail_args.dart
    exercises/
      exercises_database_view.dart
      exercises_database_view_model.dart
      exercises_database_state.dart
      exercise_editor_view.dart
      exercise_editor_view_model.dart
      exercise_editor_state.dart
      exercise_editor_args.dart
    workout/
      workout_session_setup_view.dart
      workout_session_setup_view_model.dart
      workout_session_setup_state.dart
      workout_session_setup_args.dart
      exercise_picker_view.dart
      exercise_picker_view_model.dart
      exercise_picker_state.dart
      exercise_picker_args.dart
      exercise_log_view.dart
      exercise_log_view_model.dart
      exercise_log_state.dart
      exercise_log_args.dart
      workout_summary_view.dart
      workout_summary_view_model.dart
      workout_summary_state.dart
      workout_summary_args.dart
    settings/
      settings_view.dart
      settings_view_model.dart
      settings_state.dart
    about/
      about_view.dart
      about_view_model.dart
      about_state.dart
  models/
    app_theme_model.dart
    workout_session_model.dart
  repositories/
    workout_repository.dart
    exercise_repository.dart
    settings_repository.dart
  domain/
    workout.dart
    logged_exercise.dart
    logged_set.dart
    exercise_definition.dart
  persistence/
    records/
      app_settings_record.dart
      active_workout_draft_record.dart
      workout_record.dart
      logged_exercise_record.dart
      logged_set_record.dart
      exercise_definition_record.dart
```

## State management notes

- Every `FoundryViewModel` should emit an initial state in its constructor before `onInit()` runs.
- Error handling should use Foundry generated `safeAsync()` helpers where appropriate.
- Long-running updates should use explicit `isLoading` or `isSaving` flags in state.
- Input-heavy screens like `ExerciseEditorView` and `WorkoutSessionSetupView` should keep current form values in ViewState rather than relying only on controllers.

## Open implementation notes

- Args-bearing deep-link resolution should be implemented with `deepLinkArgsFactory` plus an app bootstrap resolver until generated matching is fully complete for those routes.
- If completed workout editing is added later, it should be implemented as a separate feature and not overload the active draft flow.
- Rest timer state can remain view-level state unless background timer persistence becomes a requirement.

## Minimum complete implementation set

The minimum implementation that satisfies the product outline is:

- Hive persistence bootstrapped and wired through a database service
- Foundry-generated state, ViewModel, route, and DI artifacts
- Material 3 light and dark themes using the Lift Log electric palette
- complete screen set for shell, history, exercise management, workout session flow, settings, and about
- typed route args for every non-trivial route
- public deep links only for stable screens