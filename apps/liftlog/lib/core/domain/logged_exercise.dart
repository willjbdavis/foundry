import 'logged_set.dart';

class LoggedExercise {
  const LoggedExercise({
    required this.exerciseId,
    required this.displayName,
    required this.notes,
    required this.sortOrder,
    this.sets = const <LoggedSet>[],
  });

  final String exerciseId;
  final String displayName;
  final String notes;
  final int sortOrder;
  final List<LoggedSet> sets;

  LoggedExercise copyWith({
    String? exerciseId,
    String? displayName,
    String? notes,
    int? sortOrder,
    List<LoggedSet>? sets,
  }) {
    return LoggedExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      displayName: displayName ?? this.displayName,
      notes: notes ?? this.notes,
      sortOrder: sortOrder ?? this.sortOrder,
      sets: sets ?? this.sets,
    );
  }
}
