import 'dart:async';

import 'package:flutter/foundation.dart';
import 'initializable.dart';
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
    if (!_streamController.isClosed) {
      _streamController.add(newState);
    }
    for (final void Function(S) listener in List<void Function(S)>.from(
      _listeners,
    )) {
      listener(newState);
    }
  }

  /// Subscribe to state changes from this service.
  ///
  /// Call in dependent service's onInit().
  void subscribe(void Function(S state) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  /// Unsubscribe listener.
  ///
  /// Call in dependent service's onDispose().
  void unsubscribe(void Function(S state)? listener) {
    if (listener != null) {
      _listeners.remove(listener);
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
  Future<void> invokeOnInit() => onInit();

  @override
  Future<void> initialize() => invokeOnInit();

  /// Framework-facing lifecycle entrypoint.
  Future<void> invokeOnResumed() => onResumed();

  /// Framework-facing lifecycle entrypoint.
  Future<void> invokeOnPaused() => onPaused();

  /// Framework-facing lifecycle entrypoint.
  Future<void> invokeOnDispose() => onDispose();

  /// Called by the framework during disposal to close the stream.
  Future<void> disposeStream() async {
    _listeners.clear();
    await _controller?.close();
    _controller = null;
  }
}
