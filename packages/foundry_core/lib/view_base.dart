import 'package:flutter/material.dart';
import 'view_model_base.dart';

/// Base class for Foundry Views.
///
/// Views must extend this class and provide ViewModel and state type
/// parameters.
abstract class FoundryView<TViewModel extends FoundryViewModel<TState>, TState>
    extends StatefulWidget {
  /// Creates a Foundry view.
  const FoundryView({super.key});

  /// Builds the widget with current state and previous state.
  ///
  /// This method should be overridden to implement the view's UI.
  /// The [oldState] parameter is null on first build, otherwise contains
  /// the previous state value for comparison.
  ///
  Widget buildWithState(
    BuildContext context,
    TState? oldState,
    TState newState,
  );
}
