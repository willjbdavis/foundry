import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:foundry_core/foundry_core.dart';

/// Rebuilds when a [StateEmitter] emits a new state.
class FoundryBuilder<S> extends StatefulWidget {
  const FoundryBuilder({
    required this.emitter,
    required this.builder,
    super.key,
  });

  final StateEmitter<S> emitter;
  final Widget Function(BuildContext context, S? oldState, S newState) builder;

  @override
  State<FoundryBuilder<S>> createState() => _FoundryBuilderState<S>();
}

class _FoundryBuilderState<S> extends State<FoundryBuilder<S>> {
  StreamSubscription<S>? _subscription;
  S? _oldState;
  late S _currentState;

  @override
  void initState() {
    super.initState();
    _bind(widget.emitter);
  }

  @override
  void didUpdateWidget(covariant final FoundryBuilder<S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.emitter, widget.emitter)) {
      _subscription?.cancel();
      _oldState = null;
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
    return widget.builder(context, _oldState, _currentState);
  }

  void _bind(final StateEmitter<S> emitter) {
    _currentState = emitter.state;
    _subscription = emitter.states.listen((final S newState) {
      if (!mounted) {
        return;
      }
      setState(() {
        _oldState = _currentState;
        _currentState = newState;
      });
    });
  }
}
