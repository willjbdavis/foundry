import 'package:foundry_annotations/foundry_annotations.dart' as foundry;

import '../domain/exercise_definition.dart';
import '../persistence/hive_database_service.dart';
import '../persistence/records/exercise_definition_record.dart';

part 'exercise_repository.g.dart';

class ExerciseValidationException implements Exception {
  ExerciseValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

@foundry.FoundryService()
class ExerciseRepository {
  ExerciseRepository(this._databaseService);

  final HiveDatabaseService _databaseService;

  Future<List<ExerciseDefinition>> listExercises() async {
    final Iterable<dynamic> rawValues =
        _databaseService.exerciseDefinitionsBox.values;

    final List<ExerciseDefinition> exercises = rawValues
        .whereType<Map<dynamic, dynamic>>()
        .map(ExerciseDefinitionRecord.fromMap)
        .map((ExerciseDefinitionRecord rec) => rec.toDomain())
        .toList();

    exercises.sort((ExerciseDefinition a, ExerciseDefinition b) {
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return exercises;
  }

  Future<ExerciseDefinition?> getExerciseById(String exerciseId) async {
    final dynamic raw = _databaseService.exerciseDefinitionsBox.get(exerciseId);
    if (raw is! Map<dynamic, dynamic>) {
      return null;
    }
    return ExerciseDefinitionRecord.fromMap(raw).toDomain();
  }

  Future<ExerciseDefinition> createExercise({
    required String name,
    required String description,
  }) async {
    final String normalizedName = _normalizeName(name);
    if (normalizedName.isEmpty) {
      throw ExerciseValidationException('Exercise name is required.');
    }

    await _assertNameUnique(normalizedName: normalizedName);

    final DateTime now = DateTime.now().toUtc();
    final ExerciseDefinition created = ExerciseDefinition(
      id: now.microsecondsSinceEpoch.toString(),
      name: normalizedName,
      description: description.trim(),
      createdAt: now,
      updatedAt: now,
    );

    await _databaseService.exerciseDefinitionsBox.put(
      created.id,
      ExerciseDefinitionRecord.fromDomain(created).toMap(),
    );

    return created;
  }

  Future<ExerciseDefinition> updateExercise({
    required String id,
    required String name,
    required String description,
  }) async {
    final ExerciseDefinition? existing = await getExerciseById(id);
    if (existing == null) {
      throw ExerciseValidationException('Exercise not found.');
    }

    final String normalizedName = _normalizeName(name);
    if (normalizedName.isEmpty) {
      throw ExerciseValidationException('Exercise name is required.');
    }

    await _assertNameUnique(normalizedName: normalizedName, excludingId: id);

    final ExerciseDefinition updated = existing.copyWith(
      name: normalizedName,
      description: description.trim(),
      updatedAt: DateTime.now().toUtc(),
    );

    await _databaseService.exerciseDefinitionsBox.put(
      updated.id,
      ExerciseDefinitionRecord.fromDomain(updated).toMap(),
    );

    return updated;
  }

  Future<void> _assertNameUnique({
    required String normalizedName,
    String? excludingId,
  }) async {
    final List<ExerciseDefinition> all = await listExercises();
    final bool exists = all.any((ExerciseDefinition e) {
      final bool sameName =
          e.name.toLowerCase() == normalizedName.toLowerCase();
      final bool differentEntity = excludingId == null || e.id != excludingId;
      return sameName && differentEntity;
    });

    if (exists) {
      throw ExerciseValidationException(
        'An exercise with this name already exists.',
      );
    }
  }

  String _normalizeName(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed.replaceAll(RegExp(r'\s+'), ' ');
  }
}
