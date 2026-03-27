import '../../domain/exercise_definition.dart';

class ExerciseDefinitionRecord {
  const ExerciseDefinitionRecord({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ExerciseDefinitionRecord.fromMap(Map<dynamic, dynamic> map) {
    return ExerciseDefinitionRecord(
      id: map['id'] as String,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ExerciseDefinition toDomain() {
    return ExerciseDefinition(
      id: id,
      name: name,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static ExerciseDefinitionRecord fromDomain(ExerciseDefinition model) {
    return ExerciseDefinitionRecord(
      id: model.id,
      name: model.name,
      description: model.description,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
}
