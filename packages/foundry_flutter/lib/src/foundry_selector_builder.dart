import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:foundry_core/foundry_core.dart';

/// Rebuilds only when [selector] returns true for old/new states.
class FoundrySelectorBuilder<S> extends StatefulWidget {
  const FoundrySelectorBuilder({
    required this.emitter,
    required this.selector,
    required this.builder,
    super.key,
  });

  final StateEmitter<S> emitter;
  final bool Function(S? oldState, S newState) selector;
  final Widget Function(BuildContext context, S state) builder;

  @override
  State<FoundrySelectorBuilder<S>> createState() =>
      _FoundrySelectorBuilderState<S>();
}

class _FoundrySelectorBuilderState<S> extends State<FoundrySelectorBuilder<S>> {
  StreamSubscription<S>? _subscription;
  late S _currentState;
  Widget? _cached;

  @override
  void initState() {
    super.initState();
    _bind(widget.emitter);
  }

  @override
  void didUpdateWidget(covariant final FoundrySelectorBuilder<S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.emitter, widget.emitter)) {
      _subscription?.cancel();
      _cached = null;
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
    return _cached ??= widget.builder(context, _currentState);
  }

  void _bind(final StateEmitter<S> emitter) {
    _currentState = emitter.state;
    _subscription = emitter.states.listen((final S newState) {
      if (!mounted) {
        return;
      }

      final S previousState = _currentState;
      final bool shouldRebuild = widget.selector(previousState, newState);
      _currentState = newState;

      if (shouldRebuild) {
        setState(() {
          _cached = widget.builder(context, _currentState);
        });
      }
    });
  }
}
