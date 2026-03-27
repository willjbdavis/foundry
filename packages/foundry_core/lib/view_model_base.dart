import 'dart:async';

import 'package:flutter/foundation.dart';
import 'state_emitter.dart';

/// Base class for Foundry ViewModels.
abstract class FoundryViewModel<S> implements StateEmitter<S> {
  S? _state;
  StreamController<S>? _controller;

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
  }

  /// Lifecycle method called when the ViewModel is initialized.
  @protected
  Future<void> onInit() async {}

  /// Lifecycle method called when the app or view is resumed (foregrounded).
  @protected
  Future<void> onResumed() async {}

  /// Lifecycle method called when the app or view is paused (backgrounded).
  @protected
  Future<void> onPaused() async {}

  /// Lifecycle method called when the ViewModel is disposed.
  @protected
  Future<void> onDispose() async {}

  /// Lifecycle method called when a back navigation is attempted.
  ///
  /// Return true to allow back navigation, false to prevent it.
  @protected
  Future<bool> onBackPressed() async => true;

  /// Lifecycle method called when an error occurs in the ViewModel.
  @protected
  Future<void> onError(Object error, StackTrace stackTrace) async {}

  /// Framework-facing lifecycle entrypoint.
  Future<void> invokeOnInit() => onInit();

  /// Framework-facing lifecycle entrypoint.
  Future<void> invokeOnResumed() => onResumed();

  /// Framework-facing lifecycle entrypoint.
  Future<void> invokeOnPaused() => onPaused();

  /// Framework-facing lifecycle entrypoint.
  Future<void> invokeOnDispose() => onDispose();

  /// Framework-facing lifecycle entrypoint.
  Future<bool> invokeOnBackPressed() => onBackPressed();

  /// Framework-facing error entrypoint.
  Future<void> invokeOnError(Object error, StackTrace stackTrace) =>
      onError(error, stackTrace);

  /// Called by the framework during disposal to close the stream.
  Future<void> disposeStream() async {
    await _controller?.close();
    _controller = null;
  }
}
