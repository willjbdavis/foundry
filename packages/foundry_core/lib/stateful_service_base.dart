import 'dart:async';

import 'package:flutter/foundation.dart';
import 'foundry.dart';
import 'initializable.dart';
import 'logging.dart';
import 'state_emitter.dart';

/// Base class for stateful services.
abstract class StatefulService<S>
    implements StateEmitter<S>, AsyncInitializable {
  S? _state;
  StreamController<S>? _controller;
  final List<void Function(S)> _listeners = <void Function(S)>[];

  /// Lazily-initialised broadcast stream controller.
  StreamController<S> get _streamController {
    _controller ??= StreamController<S>.broadcast();
    return _controller!;
  }

  @override
  S get state {
    final S? s = _state;
    if (s == null) {
      Foundry.log(
        LogEvent(
          level: LogLevel.error,
          tag: 'service.state',
          message:
              'State read before initialization in ${runtimeType.toString()}.',
        ),
      );
      throw StateError(
        'State has not been initialised. Call emitNewState() in onInit() '
        'before reading state.',
      );
    }
    return s;
  }

  @override
  Stream<S> get states => _streamController.stream;

  /// Emits a new state to observers.
  ///
  /// This method should be called by subclasses to emit new state values.
  @protected
  void emitNewState(S newState) {
    _state = newState;
    Foundry.log(
      LogEvent(
        level: LogLevel.debug,
        tag: 'service.state',
        message: 'Emitted new state from ${runtimeType.toString()}.',
      ),
    );

    if (!_streamController.isClosed) {
      _streamController.add(newState);
    }
    for (final void Function(S) listener in List<void Function(S)>.from(
      _listeners,
    )) {
      listener(newState);
    }
  }

  /// Registers [listener] to receive future state emissions.
  ///
  /// The listener is invoked whenever [emitNewState] publishes a new value.
  /// Existing state is not replayed automatically; subscribe before relying on
  /// updates.
  ///
  /// Duplicate registrations of the same function are ignored.
  void subscribe(void Function(S state) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
      Foundry.log(
        LogEvent(
          level: LogLevel.debug,
          tag: 'service.subscription',
          message: 'Added listener in ${runtimeType.toString()}.',
        ),
      );
    }
  }

  /// Removes a previously registered [listener].
  ///
  /// Passing null is a no-op, which allows safe cleanup paths where the
  /// callback may be conditionally assigned.
  void unsubscribe(void Function(S state)? listener) {
    if (listener != null) {
      _listeners.remove(listener);
      Foundry.log(
        LogEvent(
          level: LogLevel.debug,
          tag: 'service.subscription',
          message: 'Removed listener in ${runtimeType.toString()}.',
        ),
      );
    }
  }

  /// Lifecycle method called when the service is initialized.
  @protected
  Future<void> onInit() async {}

  /// Lifecycle method called when the app or view is resumed (foregrounded).
  @protected
  Future<void> onResumed() async {}

  /// Lifecycle method called when the app or view is paused (backgrounded).
  @protected
  Future<void> onPaused() async {}

  /// Lifecycle method called when the service is disposed.
  @protected
  Future<void> onDispose() async {}

  /// Framework-facing lifecycle entrypoint.
  Future<void> invokeOnInit() {
    Foundry.log(
      LogEvent(
        level: LogLevel.debug,
        tag: 'service.lifecycle',
        message: 'invokeOnInit on ${runtimeType.toString()}.',
      ),
    );

    return onInit();
  }

  @override
  Future<void> initialize() {
    Foundry.log(
      LogEvent(
        level: LogLevel.info,
        tag: 'service.lifecycle',
        message: 'initialize on ${runtimeType.toString()}.',
      ),
    );

    return invokeOnInit();
  }

  /// Framework-facing lifecycle entrypoint.
  Future<void> invokeOnResumed() {
    Foundry.log(
      LogEvent(
        level: LogLevel.debug,
        tag: 'service.lifecycle',
        message: 'invokeOnResumed on ${runtimeType.toString()}.',
      ),
    );

    return onResumed();
  }

  /// Framework-facing lifecycle entrypoint.
  Future<void> invokeOnPaused() {
    Foundry.log(
      LogEvent(
        level: LogLevel.debug,
        tag: 'service.lifecycle',
        message: 'invokeOnPaused on ${runtimeType.toString()}.',
      ),
    );

    return onPaused();
  }

  /// Framework-facing lifecycle entrypoint.
  Future<void> invokeOnDispose() {
    Foundry.log(
      LogEvent(
        level: LogLevel.info,
        tag: 'service.lifecycle',
        message: 'invokeOnDispose on ${runtimeType.toString()}.',
      ),
    );

    return onDispose();
  }

  /// Called by the framework during disposal to close the stream.
  Future<void> disposeStream() async {
    Foundry.log(
      LogEvent(
        level: LogLevel.debug,
        tag: 'service.lifecycle',
        message: 'disposeStream on ${runtimeType.toString()}.',
      ),
    );

    _listeners.clear();
    await _controller?.close();
    _controller = null;
  }
}
