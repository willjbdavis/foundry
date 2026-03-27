class LoggedSet {
  const LoggedSet({
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

  LoggedSet copyWith({
    String? id,
    int? reps,
    double? weight,
    String? setType,
    DateTime? loggedAt,
  }) {
    return LoggedSet(
      id: id ?? this.id,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      setType: setType ?? this.setType,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }
}
