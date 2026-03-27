# Lift Log Implementation Plan

## Goal

Deliver Lift Log as a complete Foundry MVVM sample app with:

- Hive persistence
- Material 3 light and dark themes with electric brand colors
- typed routes and deep links
- full workout logging flow
- exercise database management
- settings and about screens

## Delivery Strategy

- Build vertically in phases so the app is always runnable.
- Lock infrastructure first, then implement features in user-facing slices.
- Finish each phase with validation before moving to the next.

## Current Status (2026-03-23)

- Phase 0 complete
- Phase 1 complete
- Phase 2 complete
- Phase 3 complete
- Phase 4 complete
- Phase 5 complete
- Phase 6 complete
- Phase 7 complete
- Phase 8 in progress (test hardening + docs alignment)

## Phase 0: Project Setup and Guardrails

### Scope

- create app scaffold under apps/liftlog/lib
- wire Foundry package dependencies
- configure build_runner workflow
- create app_module exports for generation

### Deliverables

- baseline folder structure from tech spec
- placeholder views and states for all planned features
- successful generation of initial .g.dart files

### Exit Criteria

- app builds and launches
- dart analyze passes
- build_runner completes without generation errors

## Phase 1: Generated DI Infrastructure and Bootstrap

### Scope

- implement app bootstrap
- configure FoundryScope and FoundryNavigator
- add HiveDatabaseService
- wire generated registration + startup initialization sequence

### Deliverables

- main.dart bootstrap flow complete
- app root renders AppShellView
- `registerGeneratedGraph(scope)` and `initializeGeneratedGraph(scope)` run before UI routes are used

### Dependencies

- Phase 0 complete

### Exit Criteria

- cold start works on emulator and desktop target
- no runtime DI resolution failures on launch
- startup singletons initialize in dependency-safe order and repositories can use opened boxes

## Phase 2: Theme System and Settings Persistence

### Scope

- implement electric brand palette and Material 3 themes
- implement AppThemeModel and SettingsRepository
- implement SettingsView flow for theme mode selection

### Deliverables

- light and dark ThemeData with mapped brand accents
- persisted theme mode (light, dark, system)
- settings screen with working theme selector

### Dependencies

- Phase 1 complete

### Exit Criteria

- theme updates live without restart
- selected theme mode restores across app restart
- contrast checks pass for key text and button surfaces

## Phase 3: Exercise Database Feature

### Scope

- implement ExerciseDefinition domain and persistence records
- implement ExerciseRepository
- implement ExercisesDatabaseView and ExerciseEditorView

### Deliverables

- list exercises
- create new exercise
- edit existing exercise
- basic validation (required name, name uniqueness)

### Dependencies

- Phase 1 complete
- Phase 2 complete (shared shell/settings behavior)

### Exit Criteria

- exercise CRUD (create, read, update) works end-to-end
- data persists after restart
- navigation between list and editor is typed and stable

## Phase 4: Workout Draft Session Engine

### Scope

- implement workout domain and persistence records
- implement WorkoutRepository and WorkoutSessionModel
- enforce single active draft behavior

### Deliverables

- create, load, update, discard draft APIs
- autosave draft after meaningful updates
- finalize draft to completed workout API

### Dependencies

- Phase 1 complete

### Exit Criteria

- active draft survives app restart
- only one active draft can exist at a time
- finalize moves draft to completed workouts and clears active draft

## Phase 5: Workout Logging User Flow

### Scope

- implement WorkoutSessionSetupView
- implement ExercisePickerView
- implement ExerciseLogView with tabbed exercises
- implement WorkoutSummaryView

### Deliverables

- start workout flow from Home
- add exercise to draft
- add, edit, remove sets
- remove exercises from draft
- finish workout via summary confirmation

### Dependencies

- Phase 3 complete
- Phase 4 complete

### Exit Criteria

- full Flow A-D from project outline works end-to-end
- draft autosave and resume behavior validated
- finish workflow writes completed workout and returns to stable destination

## Phase 6: Home and History Experience

### Scope

- implement HomeView dashboard behavior
- implement WorkoutHistoryView
- implement WorkoutDetailView

### Deliverables

- home recent workouts and resume card
- full history list
- workout detail read-only rendering

### Dependencies

- Phase 4 complete
- Phase 5 complete

### Exit Criteria

- home and history responsibilities are clearly separated
- tapping history item opens detail route with args
- newly completed workouts appear in home and history lists

## Phase 7: Deep Links and Route Hardening

### Scope

- define and verify stable public deep links
- implement deep-link resolver for args-based paths
- keep draft-dependent routes internal-only

### Deliverables

- working deep links:
  - /
  - /home
  - /history
  - /history/:workoutId
  - /exercises
  - /exercises/new
  - /exercises/:exerciseId/edit
  - /settings
  - /about
- unknown-link fallback behavior

### Dependencies

- Phase 6 complete

### Exit Criteria

- app opens correct screen for each supported deep link
- args parsing works for workout and exercise ids
- invalid links fail safely without crash

## Phase 8: Quality, Testing, and Stabilization

### Scope

- add unit tests for repositories and models
- add widget tests for major view flows
- run static analysis and cleanup
- finalize docs alignment

### Deliverables

- test suite for core business logic and routing contracts
- smoke tests for start workout, finish workout, and create exercise flows
- updated project docs cross-linked with outline and tech spec

### Dependencies

- Phases 0-7 complete

### Exit Criteria

- dart analyze passes
- tests pass in CI or local equivalent
- no P0 or P1 known defects remain

## Cross-Cutting Standards

- Keep all navigation typed via Foundry route generation.
- Emit initial ViewState in every ViewModel constructor.
- Avoid direct Hive access from views and view models; use repositories or models.
- Persist active workout updates incrementally to prevent data loss.
- Keep deep links for stable routes only.

## Milestone Checklist

- Milestone 1: App boots with Foundry + Hive + theme persistence (Phases 0-2)
- Milestone 2: Exercise management complete (Phase 3)
- Milestone 3: Workout draft engine + logging flow complete (Phases 4-5)
- Milestone 4: Home/history polish + deep links complete (Phases 6-7)
- Milestone 5: Test hardening and release-ready sample (Phase 8)

## Suggested Implementation Order Inside Each Phase

1. Define domain models and state contracts.
2. Implement repositories and model logic.
3. Implement ViewModels.
4. Implement Views.
5. Wire navigation and deep links.
6. Add tests and run analyze.

## Risk Watchlist

- Deep-link args generation gaps for some routes in current generator behavior.
- Theme contrast regressions when applying electric accents broadly.
- Draft consistency bugs if autosave is not triggered on every mutation path.
- Navigation edge cases when creating exercises from inside workout flow.

## Definition of Done

The implementation is complete when:

- all views in the outline and tech spec are implemented
- all core flows A-G are functional
- persistence and deep links behave as specified
- app theme behavior is correct in light, dark, and system modes
- tests and analysis pass with no critical issues