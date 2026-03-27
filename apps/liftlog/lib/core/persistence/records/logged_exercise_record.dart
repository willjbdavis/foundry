import '../../domain/logged_exercise.dart';
import 'logged_set_record.dart';

class LoggedExerciseRecord {
  const LoggedExerciseRecord({
    required this.exerciseId,
    required this.displayName,
    required this.notes,
    required this.sortOrder,
    required this.sets,
  });

  final String exerciseId;
  final String displayName;
  final String notes;
  final int sortOrder;
  final List<LoggedSetRecord> sets;

  factory LoggedExerciseRecord.fromMap(Map<dynamic, dynamic> map) {
    return LoggedExerciseRecord(
      exerciseId: map['exerciseId'] as String,
      displayName: map['displayName'] as String,
      notes: (map['notes'] as String?) ?? '',
      sortOrder: map['sortOrder'] as int,
      sets: ((map['sets'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<dynamic, dynamic>>()
          .map(LoggedSetRecord.fromMap)
          .toList()),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'exerciseId': exerciseId,
      'displayName': displayName,
      'notes': notes,
      'sortOrder': sortOrder,
      'sets': sets.map((LoggedSetRecord s) => s.toMap()).toList(),
    };
  }

  LoggedExercise toDomain() {
    return LoggedExercise(
      exerciseId: exerciseId,
      displayName: displayName,
      notes: notes,
      sortOrder: sortOrder,
      sets: sets.map((LoggedSetRecord s) => s.toDomain()).toList(),
    );
  }

  static LoggedExerciseRecord fromDomain(LoggedExercise model) {
    return LoggedExerciseRecord(
      exerciseId: model.exerciseId,
      displayName: model.displayName,
      notes: model.notes,
      sortOrder: model.sortOrder,
      sets: model.sets.map(LoggedSetRecord.fromDomain).toList(),
    );
  }
}
