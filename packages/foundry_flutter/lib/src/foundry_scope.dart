import 'package:flutter/widgets.dart';
import 'package:foundry_core/foundry_core.dart';

/// Injects a [Scope] into the widget tree.
///
/// Use [childScope] to create an auto-disposed child scope subtree.
class FoundryScope extends InheritedWidget {
  const FoundryScope({required this.scope, required super.child, super.key});

  final Scope scope;

  static Scope of(final BuildContext context) {
    final FoundryScope? inherited = context
        .dependOnInheritedWidgetOfExactType<FoundryScope>();
    if (inherited == null) {
      throw StateError('No FoundryScope found above this BuildContext.');
    }
    return inherited.scope;
  }

  /// Creates a widget subtree with an automatically managed child scope.
  static Widget childScope({required final Widget child, final Key? key}) {
    return _FoundryAutoChildScope(key: key, child: child);
  }

  @override
  bool updateShouldNotify(final FoundryScope oldWidget) {
    return oldWidget.scope != scope;
  }
}

class _FoundryAutoChildScope extends StatefulWidget {
  const _FoundryAutoChildScope({required this.child, super.key});

  final Widget child;

  @override
  State<_FoundryAutoChildScope> createState() => _FoundryAutoChildScopeState();
}

class _FoundryAutoChildScopeState extends State<_FoundryAutoChildScope> {
  Scope? _scope;
  Scope? _parentScope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final Scope parentScope = FoundryScope.of(context);
    if (_scope == null || !identical(parentScope, _parentScope)) {
      _scope?.dispose();
      _parentScope = parentScope;
      _scope = parentScope.createChild();
    }
  }

  @override
  void dispose() {
    _scope?.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final Scope? scope = _scope;
    if (scope == null) {
      return const SizedBox.shrink();
    }

    return FoundryScope(scope: scope, child: widget.child);
  }
}
