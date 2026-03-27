import '../../domain/workout.dart';
import 'logged_exercise_record.dart';

class WorkoutRecord {
  const WorkoutRecord({
    required this.id,
    required this.title,
    required this.date,
    required this.notes,
    required this.exercises,
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String title;
  final DateTime date;
  final String notes;
  final List<LoggedExerciseRecord> exercises;
  final DateTime createdAt;
  final DateTime? completedAt;

  factory WorkoutRecord.fromMap(Map<dynamic, dynamic> map) {
    return WorkoutRecord(
      id: map['id'] as String,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      notes: (map['notes'] as String?) ?? '',
      exercises: ((map['exercises'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<dynamic, dynamic>>()
          .map(LoggedExerciseRecord.fromMap)
          .toList()),
      createdAt: DateTime.parse(map['createdAt'] as String),
      completedAt: (map['completedAt'] as String?) == null
          ? null
          : DateTime.parse(map['completedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'notes': notes,
      'exercises': exercises
          .map((LoggedExerciseRecord e) => e.toMap())
          .toList(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  Workout toDomain() {
    return Workout(
      id: id,
      title: title,
      date: date,
      notes: notes,
      exercises: exercises
          .map((LoggedExerciseRecord e) => e.toDomain())
          .toList(),
      createdAt: createdAt,
      completedAt: completedAt,
    );
  }

  static WorkoutRecord fromDomain(Workout model) {
    return WorkoutRecord(
      id: model.id,
      title: model.title,
      date: model.date,
      notes: model.notes,
      exercises: model.exercises.map(LoggedExerciseRecord.fromDomain).toList(),
      createdAt: model.createdAt,
      completedAt: model.completedAt,
    );
  }
}
