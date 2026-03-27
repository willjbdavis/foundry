# Lift Log

Lift Log is a small workout logging app used to demonstrate the Foundry MVVM stack. The app should feel like a complete vertical slice rather than a loose collection of screens, so the outline needs a coherent navigation model, clear data ownership, and end-to-end user flows.

## Product Goal

The app lets a user:

- start a workout session
- add one or more exercises to that workout
- record sets with reps and weight for each exercise
- use a rest timer while logging sets
- save completed workouts to history
- manage the reusable exercise database
- switch the app theme between light, dark, and system

## Core Data

The outline implicitly requires these entities:

- `Workout`: id, title, date, optional notes, list of logged exercises, created/completed timestamps
- `LoggedExercise`: exercise reference, display name, list of sets, optional notes, sort order
- `LoggedSet`: reps, weight, optional set type, timestamp
- `ExerciseDefinition`: id, name, description
- `ThemePreference`: light, dark, or system

## Navigation Model

The app structure makes the most sense with a persistent shell and focused feature routes.

- Bottom navigation tabs:
    - `Home`
    - `History`
    - `Exercises`
- App drawer or overflow menu:
    - `Settings`
    - `About`
- Global entry actions:
    - Start workout
    - Create exercise

## Required Views

These are the views needed for the current feature set.

### Shell and Top-Level Views

- `AppShellView`
    - Hosts bottom navigation and drawer or overflow navigation.
- `HomeView`
    - Landing screen.
    - Shows a primary call to action to start a workout.
    - Shows recent workouts or an empty state.
    - If a workout is already in progress, shows a resume card instead of starting a duplicate session.
- `WorkoutHistoryView`
    - Full list of previously completed workouts.
    - Replaces the vague `LogView` name with a more explicit history screen.
- `ExercisesDatabaseView`
    - Lists saved exercise definitions.
    - Supports creating and editing exercise definitions.
- `SettingsView`
    - Lets the user switch theme preference.
- `AboutView`
    - Describes the app and the Foundry demo purpose.

### Workout Flow Views

- `WorkoutSessionSetupView`
    - Starts a new workout.
    - Captures workout title and date before exercise logging begins.
    - Can default the date to today and optionally provide a generated title.
- `ExercisePickerView`
    - Lets the user choose an existing exercise from the database.
    - Can also branch into creating a new exercise if the desired exercise does not exist.
- `ExerciseLogView`
    - Main active workout screen.
    - Shows one tab per exercise already added to the current workout.
    - Lets the user add sets for the selected exercise.
    - Includes the rest timer.
    - Supports adding another exercise.
    - Supports editing or removing a set.
    - Supports removing an exercise from the current workout.
    - Provides save, finish, and discard actions.
- `WorkoutSummaryView`
    - Final review screen before completing the workout.
    - Shows workout metadata, exercise list, and set totals.
    - Confirms save or allows returning to editing.
- `WorkoutDetailView`
    - Read-only detail view for a completed workout selected from history.
    - Required if `WorkoutHistoryView` is more than a flat list.

### Exercise Management Views

- `ExerciseEditorView`
    - Create or edit an exercise definition.
    - Fields: name and description.
    - Used from `ExercisesDatabaseView` and optionally from `ExercisePickerView` when the user needs a missing exercise.

## Core Features

### 1. Start and Complete a Workout

- User starts from `HomeView`.
- Tapping the main action opens `WorkoutSessionSetupView`.
- User confirms workout title and date.
- User is taken to `ExercisePickerView` to choose the first exercise.
- After choosing an exercise, the app opens `ExerciseLogView` with the first exercise tab created.
- User adds one or more sets for the current exercise.
- User can add more exercises, which creates additional tabs in `ExerciseLogView`.
- When finished, user opens `WorkoutSummaryView`.
- User saves the workout.
- Saved workout appears in `WorkoutHistoryView` and recent-workout content on `HomeView`.

### 2. Add and Manage Sets During an Active Workout

- `ExerciseLogView` should support:
    - entering reps and weight
    - adding a set to the current exercise
    - editing an existing set
    - deleting an existing set
    - switching exercises through tabs
    - adding another exercise through a top-bar action or FAB
    - removing an exercise tab if added by mistake

### 3. Rest Timer

- The timer belongs inside `ExerciseLogView` because it supports the active workout flow.
- Required timer actions:
    - set minutes and seconds
    - start
    - pause
    - resume
    - reset

### 4. Workout History

- `WorkoutHistoryView` lists completed workouts.
- Tapping a workout opens `WorkoutDetailView`.
- `HomeView` may show only recent workouts, while `WorkoutHistoryView` is the complete log.

### 5. Exercise Database Management

- `ExercisesDatabaseView` lists all exercise definitions.
- FAB opens `ExerciseEditorView` in create mode.
- Selecting an exercise from the list opens `ExerciseEditorView` in edit mode.
- `ExercisePickerView` reuses the same exercise database so users do not create one-off exercise names during logging.

### 6. Theme Preference

- `SettingsView` allows choosing:
    - light
    - dark
    - system

## Primary User Flows

### Flow A: Start a Workout

1. Open `HomeView`.
2. Tap start workout.
3. Fill out `WorkoutSessionSetupView`.
4. Pick the first exercise in `ExercisePickerView`.
5. Land in `ExerciseLogView`.

### Flow B: Add Another Exercise While Logging

1. In `ExerciseLogView`, tap add exercise.
2. Open `ExercisePickerView`.
3. Select an exercise.
4. Return to `ExerciseLogView` with a new exercise tab added and selected.

### Flow C: Create a Missing Exercise Mid-Workout

1. In `ExercisePickerView`, user cannot find the exercise.
2. User taps create exercise.
3. Open `ExerciseEditorView`.
4. Save the new exercise.
5. Return to `ExercisePickerView` or directly back to `ExerciseLogView` with the new exercise selected.

### Flow D: Finish a Workout

1. In `ExerciseLogView`, tap finish workout.
2. Review details in `WorkoutSummaryView`.
3. Confirm save.
4. Navigate to `WorkoutDetailView` or back to `HomeView` with the workout now visible in history.

### Flow E: Browse Past Workouts

1. Open `WorkoutHistoryView` from the bottom navigation.
2. Select a workout.
3. Review it in `WorkoutDetailView`.

### Flow F: Manage Exercises

1. Open `ExercisesDatabaseView` from the bottom navigation.
2. Tap create exercise or select an existing one.
3. Use `ExerciseEditorView` to save changes.

### Flow G: Change Theme

1. Open `SettingsView` from the drawer or overflow menu.
2. Choose light, dark, or system.
3. App theme updates and persists.

## Important UX Rules

- Only one workout should be active at a time.
- If a workout is in progress, `HomeView` should show resume rather than silently starting a second session.
- `HomeView` and `WorkoutHistoryView` must not duplicate the exact same responsibility.
    - `HomeView` is a dashboard.
    - `WorkoutHistoryView` is the full archive.
- `ExerciseLogView` is the center of the app and should own the active-session experience.
- Exercise definitions should come from the database so workout logging stays consistent.
- The app should allow cancelling or discarding a workout draft explicitly.

## Recommended Naming Cleanup

Use these names consistently in the project:

- `WorkoutHistoryView` instead of `LogView`
- `ExercisePickerView` instead of `Excersize Picker View`
- `ExerciseLogView` instead of mixed quoted names
- `ExerciseEditorView` instead of separate unnamed creation screens

## Final Scope Summary

If this outline is implemented as written, the minimum complete set of views is:

- `AppShellView`
- `HomeView`
- `WorkoutHistoryView`
- `ExercisesDatabaseView`
- `WorkoutSessionSetupView`
- `ExercisePickerView`
- `ExerciseLogView`
- `WorkoutSummaryView`
- `WorkoutDetailView`
- `ExerciseEditorView`
- `SettingsView`
- `AboutView`

That set covers all of the features already implied by the app concept without adding unrelated product ideas.

