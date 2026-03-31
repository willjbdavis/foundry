/// Base reactive contract for state emission.
abstract interface class StateEmitter<S> {
  /// Current state of the emitter.
  S get state;

  /// Stream of state changes.
  Stream<S> get states;
}
