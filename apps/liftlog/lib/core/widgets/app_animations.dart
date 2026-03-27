import 'package:flutter/material.dart';

/// Fades and slides a list item up with a stagger delay based on [index].
/// Cap the index so items beyond position 7 appear immediately.
class StaggeredFadeSlide extends StatefulWidget {
  const StaggeredFadeSlide({
    required this.index,
    required this.child,
    super.key,
  });

  final int index;
  final Widget child;

  @override
  State<StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: 55 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.07),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
        child: widget.child,
      ),
    );
  }
}

/// Fades a widget in on first mount — ideal for pushed route screens.
class ScreenFadeIn extends StatefulWidget {
  const ScreenFadeIn({required this.child, super.key});

  final Widget child;

  @override
  State<ScreenFadeIn> createState() => _ScreenFadeInState();
}

class _ScreenFadeInState extends State<ScreenFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeIn),
      child: widget.child,
    );
  }
}

/// A search text field that owns its [TextEditingController] and [FocusNode]
/// so focus is not lost when a parent widget rebuilds on each keystroke.
class SearchField extends StatefulWidget {
  const SearchField({
    required this.hintText,
    required this.onChanged,
    super.key,
  });

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: widget.hintText,
      ),
      onChanged: widget.onChanged,
    );
  }
}

/// A general-purpose text field that owns its [TextEditingController] and
/// [FocusNode] so focus and cursor position survive parent rebuilds driven by
/// state changes. When an externally-supplied [initialValue] changes while the
/// field is *not* focused (e.g. an async load populates an edit form), the
/// controller is updated automatically.
class ControlledField extends StatefulWidget {
  const ControlledField({
    required this.onChanged,
    this.initialValue = '',
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.minLines,
    this.maxLines = 1,
    super.key,
  });

  final String initialValue;
  final InputDecoration decoration;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final int? minLines;
  final int? maxLines;

  @override
  State<ControlledField> createState() => _ControlledFieldState();
}

class _ControlledFieldState extends State<ControlledField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(ControlledField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only sync when the value changed externally and the user is not typing.
    if (widget.initialValue != oldWidget.initialValue && !_focusNode.hasFocus) {
      _controller.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: widget.decoration,
      keyboardType: widget.keyboardType,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      onChanged: widget.onChanged,
    );
  }
}

/// Shared empty-state widget used across list screens.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 56,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
