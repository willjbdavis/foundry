import 'package:flutter/widgets.dart';
import 'package:foundry_core/foundry_core.dart' as core;

import 'foundry_state.dart';

/// Flutter-first Foundry view base with automatic state wiring.
abstract class FoundryView<
  TViewModel extends core.FoundryViewModel<TState>,
  TState
>
    extends core.FoundryView<TViewModel, TState> {
  /// Creates a Foundry Flutter view bound to [TViewModel].
  const FoundryView({super.key});

  /// Creates the default lifecycle-aware [State] implementation.
  @override
  State<FoundryView<TViewModel, TState>> createState() =>
      _DefaultFoundryState<TViewModel, TState>();
}

class _DefaultFoundryState<
  TViewModel extends core.FoundryViewModel<TState>,
  TState
>
    extends FoundryState<FoundryView<TViewModel, TState>, TViewModel, TState> {}
