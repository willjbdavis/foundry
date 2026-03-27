import 'logged_exercise.dart';

class Workout {
  const Workout({
    required this.id,
    required this.title,
    required this.date,
    required this.notes,
    this.exercises = const <LoggedExercise>[],
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String title;
  final DateTime date;
  final String notes;
  final List<LoggedExercise> exercises;
  final DateTime createdAt;
  final DateTime? completedAt;

  Workout copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? notes,
    List<LoggedExercise>? exercises,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Workout(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
