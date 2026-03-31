import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:foundry_core/foundry_core.dart' show FoundryViewModel, Scope;

import 'foundry_scope.dart';
import 'foundry_view.dart';

/// Base State implementation that wires a View to its ViewModel lifecycle.
abstract class FoundryState<
  TWidget extends FoundryView<TViewModel, TState>,
  TViewModel extends FoundryViewModel<TState>,
  TState
>
    extends State<TWidget>
    with WidgetsBindingObserver {
  Scope? _parentScope;
  Scope? _viewScope;
  TViewModel? _viewModel;
  StreamSubscription<TState>? _subscription;

  TState? _oldState;
  TState? _currentState;
  bool _hasCurrentState = false;

  /// Whether this state object is currently bound to a resolved ViewModel.
  bool get isBound => _viewModel != null;

  /// Currently bound view model instance.
  ///
  /// Throws [StateError] before initial binding completes.
  TViewModel get viewModel {
    final TViewModel? vm = _viewModel;
    if (vm == null) {
      throw StateError('ViewModel has not been bound yet.');
    }
    return vm;
  }

  /// Previously rendered state value.
  ///
  /// Returns null until at least one update has been received after binding.
  TState? get oldState => _oldState;

  /// Most recent state value received from the bound view model.
  ///
  /// Throws [StateError] until initial state is available.
  TState get currentState {
    if (!_hasCurrentState) {
      throw StateError('Current state is not available yet.');
    }
    return _currentState as TState;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final Scope parentScope = FoundryScope.of(context);
    if (!identical(parentScope, _parentScope) || _viewModel == null) {
      _unbind();
      _bind(parentScope);
    }
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (!isBound) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        _safeLifecycleCall(() => viewModel.invokeOnResumed());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _safeLifecycleCall(() => viewModel.invokeOnPaused());
      case AppLifecycleState.detached:
        // No-op.
        break;
    }
  }

  @override
  Widget build(final BuildContext context) {
    if (!isBound || !_hasCurrentState || _viewScope == null) {
      return const SizedBox.shrink();
    }

    final Scope viewScope = _viewScope as Scope;
    return FoundryScope(
      scope: viewScope,
      child: Builder(
        builder: (final BuildContext scopedContext) {
          return widget.buildWithState(
            scopedContext,
            _oldState,
            _currentState as TState,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unbind();
    super.dispose();
  }

  void _bind(final Scope parentScope) {
    _parentScope = parentScope;
    _viewScope = parentScope.createChild();

    try {
      final Scope scoped = _viewScope!;
      _viewModel = scoped.resolve<TViewModel>();
      _currentState = _viewModel!.state;
      _hasCurrentState = true;

      _subscription = _viewModel!.states.listen(
        (final TState state) {
          if (!mounted) {
            return;
          }
          setState(() {
            _oldState = _currentState;
            _currentState = state;
          });
        },
        onError: (final Object error, final StackTrace stackTrace) async {
          await _viewModel?.invokeOnError(error, stackTrace);
        },
      );

      _safeLifecycleCall(() => _viewModel!.invokeOnInit());
    } catch (error, stackTrace) {
      _safeLifecycleCall(() => _viewModel?.invokeOnError(error, stackTrace));
      rethrow;
    }
  }

  void _unbind() {
    _subscription?.cancel();
    _subscription = null;

    final TViewModel? vm = _viewModel;
    _viewModel = null;

    _oldState = null;
    _currentState = null;
    _hasCurrentState = false;

    if (vm != null) {
      _safeLifecycleCall(() => vm.invokeOnDispose());
    }

    _viewScope?.dispose();
    _viewScope = null;
    _parentScope = null;
  }

  void _safeLifecycleCall(final Future<void>? Function() call) {
    Future<void>.microtask(() async {
      try {
        await call();
      } catch (error, stackTrace) {
        final TViewModel? vm = _viewModel;
        if (vm != null) {
          await vm.invokeOnError(error, stackTrace);
        }
      }
    });
  }
}
