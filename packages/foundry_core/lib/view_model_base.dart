import 'dart:async';

import 'package:flutter/foundation.dart';
import 'foundry.dart';
import 'logging.dart';
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
      Foundry.log(
        LogEvent(
          level: LogLevel.error,
          tag: 'vm.state',
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
        tag: 'vm.state',
        message: 'Emitted new state from ${runtimeType.toString()}.',
      ),
    );

    if (!_streamController.isClosed) {
      _streamController.add(newState);
    }
  }

  /// Lifecycle method called when the ViewModel is initialized.
  @protected
  Future<void> onInit() async {}

  /// Lifecycle method called when the app  is resumed (foregrounded).
  @protected
  Future<void> onResumed() async {}

  /// Lifecycle method called when the app is paused (backgrounded).
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
  Future<void> invokeOnInit() {
    Foundry.log(
      LogEvent(
        level: LogLevel.debug,
        tag: 'vm.lifecycle',
        message: 'invokeOnInit on ${runtimeType.toString()}.',
      ),
    );

    return onInit();
  }

  /// Framework-facing lifecycle entrypoint.
  Future<void> invokeOnResumed() {
    Foundry.log(
      LogEvent(
        level: LogLevel.debug,
        tag: 'vm.lifecycle',
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
        tag: 'vm.lifecycle',
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
        tag: 'vm.lifecycle',
        message: 'invokeOnDispose on ${runtimeType.toString()}.',
      ),
    );

    return onDispose();
  }

  /// Framework-facing lifecycle entrypoint.
  Future<bool> invokeOnBackPressed() {
    Foundry.log(
      LogEvent(
        level: LogLevel.debug,
        tag: 'vm.lifecycle',
        message: 'invokeOnBackPressed on ${runtimeType.toString()}.',
      ),
    );

    return onBackPressed();
  }

  /// Framework-facing error entrypoint.
  Future<void> invokeOnError(Object error, StackTrace stackTrace) {
    Foundry.log(
      LogEvent(
        level: LogLevel.error,
        tag: 'vm.error',
        message: 'invokeOnError on ${runtimeType.toString()}.',
        error: error,
        stackTrace: stackTrace,
      ),
    );
    return onError(error, stackTrace);
  }

  /// Called by the framework during disposal to close the stream.
  Future<void> disposeStream() async {
    Foundry.log(
      LogEvent(
        level: LogLevel.debug,
        tag: 'vm.lifecycle',
        message: 'disposeStream on ${runtimeType.toString()}.',
      ),
    );

    await _controller?.close();
    _controller = null;
  }
}
