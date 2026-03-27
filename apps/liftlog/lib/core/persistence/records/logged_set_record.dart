import '../../domain/logged_set.dart';

class LoggedSetRecord {
  const LoggedSetRecord({
    required this.id,
    required this.reps,
    required this.weight,
    this.setType,
    required this.loggedAt,
  });

  final String id;
  final int reps;
  final double weight;
  final String? setType;
  final DateTime loggedAt;

  factory LoggedSetRecord.fromMap(Map<dynamic, dynamic> map) {
    return LoggedSetRecord(
      id: map['id'] as String,
      reps: map['reps'] as int,
      weight: (map['weight'] as num).toDouble(),
      setType: map['setType'] as String?,
      loggedAt: DateTime.parse(map['loggedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'reps': reps,
      'weight': weight,
      'setType': setType,
      'loggedAt': loggedAt.toIso8601String(),
    };
  }

  LoggedSet toDomain() {
    return LoggedSet(
      id: id,
      reps: reps,
      weight: weight,
      setType: setType,
      loggedAt: loggedAt,
    );
  }

  static LoggedSetRecord fromDomain(LoggedSet model) {
    return LoggedSetRecord(
      id: model.id,
      reps: model.reps,
      weight: model.weight,
      setType: model.setType,
      loggedAt: model.loggedAt,
    );
  }
}
