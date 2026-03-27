import '../../domain/workout.dart';
import 'workout_record.dart';

class ActiveWorkoutDraftRecord {
  const ActiveWorkoutDraftRecord({
    required this.workout,
    required this.updatedAt,
  });

  final WorkoutRecord workout;
  final DateTime updatedAt;

  factory ActiveWorkoutDraftRecord.fromMap(Map<dynamic, dynamic> map) {
    return ActiveWorkoutDraftRecord(
      workout: WorkoutRecord.fromMap(map['workout'] as Map<dynamic, dynamic>),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'workout': workout.toMap(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Workout toDomain() => workout.toDomain();

  static ActiveWorkoutDraftRecord fromDomain(Workout draft) {
    return ActiveWorkoutDraftRecord(
      workout: WorkoutRecord.fromDomain(draft),
      updatedAt: DateTime.now().toUtc(),
    );
  }
}
