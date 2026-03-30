import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:foundry_core/foundry_core.dart';

/// Runs side effects when a [StateEmitter] emits a new state.
class FoundryListener<S> extends StatefulWidget {
  const FoundryListener({
    required this.emitter,
    required this.listener,
    required this.child,
    super.key,
  });

  final StateEmitter<S> emitter;
  final void Function(BuildContext context, S? oldState, S newState) listener;
  final Widget child;

  @override
  State<FoundryListener<S>> createState() => _FoundryListenerState<S>();
}

class _FoundryListenerState<S> extends State<FoundryListener<S>> {
  StreamSubscription<S>? _subscription;
  late S _currentState;

  @override
  void initState() {
    super.initState();
    _bind(widget.emitter);
  }

  @override
  void didUpdateWidget(covariant final FoundryListener<S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.emitter, widget.emitter)) {
      _subscription?.cancel();
      _bind(widget.emitter);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return widget.child;
  }

  void _bind(final StateEmitter<S> emitter) {
    _currentState = emitter.state;
    _subscription = emitter.states.listen((final S newState) {
      if (!mounted) {
        return;
      }

      final S prevState = _currentState;
      _currentState = newState;
      widget.listener(context, prevState, newState);
    });
  }
}
