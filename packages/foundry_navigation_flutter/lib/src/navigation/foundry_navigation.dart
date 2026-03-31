import 'package:flutter/widgets.dart';
import 'package:foundry_core/foundry_core.dart';

import 'adapter.dart';
import 'flutter_adapter.dart';
import 'route_config.dart';

/// Describes the type of navigation target used by [FoundryNavigation].
enum NavTargetType {
  /// The default (root) navigator.
  defaultTarget,

  /// A navigator derived from a [BuildContext].
  context,

  /// A named channel navigator.
  channel,

  /// An explicitly provided [NavigatorAdapter].
  navigator,
}

/// Explicit-target navigation service for Foundry.
///
/// Provides push, pop, canPop, and popToRoot operations scoped to five target
/// types: default, context, channel, navigator, and last.
///
/// Each method family resolves only its own target — there is no implicit
/// fallback between target types.
///
/// Push result typing is inferred from `RouteConfig<T>`. Pop value validation
/// is delegated to the underlying [NavigatorAdapter] implementation.
class FoundryNavigation {
  FoundryNavigation({required NavigatorAdapter defaultAdapter})
    : _defaultAdapter = defaultAdapter;

  // ---------------------------------------------------------------------------
  // Static accessor
  // ---------------------------------------------------------------------------

  static FoundryNavigation? _instance;

  /// The configured [FoundryNavigation] instance.
  ///
  /// Throws [StateError] if [configure] has not been called.
  static FoundryNavigation get instance {
    final FoundryNavigation? nav = _instance;
    if (nav == null) {
      Foundry.log(
        const LogEvent(
          level: LogLevel.error,
          tag: 'nav.service',
          message: 'FoundryNavigation.instance requested before configure.',
        ),
      );
      throw StateError(
        'FoundryNavigation not configured. '
        'Call FoundryNavigation.configure(...) at startup.',
      );
    }
    return nav;
  }

  /// Sets the app-wide [FoundryNavigation] instance.
  static void configure(FoundryNavigation navigation) {
    _instance = navigation;
    Foundry.log(
      const LogEvent(
        level: LogLevel.info,
        tag: 'nav.service',
        message: 'Configured FoundryNavigation instance.',
      ),
    );
  }

  /// Clears the app-wide instance. Primarily useful in tests.
  static void reset() {
    _instance = null;
    Foundry.log(
      const LogEvent(
        level: LogLevel.debug,
        tag: 'nav.service',
        message: 'Reset FoundryNavigation instance.',
      ),
    );
  }

  final NavigatorAdapter _defaultAdapter;
  final Map<String, NavigatorAdapter> _channels = {};

  // Last-target tracking
  NavTargetType? _lastTargetType;
  BuildContext? _lastContext;
  String? _lastChannelKey;
  NavigatorAdapter? _lastNavigatorAdapter;

  // ---------------------------------------------------------------------------
  // Channel registration
  // ---------------------------------------------------------------------------

  /// Registers a named channel with a [NavigatorAdapter].
  ///
  /// Registering with the same [key] replaces the previous adapter.
  void registerChannel(String key, NavigatorAdapter adapter) {
    _channels[key] = adapter;
    Foundry.log(
      LogEvent(
        level: LogLevel.info,
        tag: 'nav.channel',
        message: 'Registered channel "$key".',
      ),
    );
  }

  /// Unregisters a named channel.
  ///
  /// If the last target was this channel, the last target is cleared.
  void unregisterChannel(String key) {
    _channels.remove(key);
    Foundry.log(
      LogEvent(
        level: LogLevel.info,
        tag: 'nav.channel',
        message: 'Unregistered channel "$key".',
      ),
    );

    if (_lastTargetType == NavTargetType.channel && _lastChannelKey == key) {
      _clearLastTarget();
    }
  }

  // ---------------------------------------------------------------------------
  // Last-target introspection
  // ---------------------------------------------------------------------------

  /// Whether a previous navigation target has been recorded.
  bool get hasLastTarget => _lastTargetType != null;

  /// Clears the last target tracking state.
  void clearLastTarget() => _clearLastTarget();

  // ---------------------------------------------------------------------------
  // Push
  // ---------------------------------------------------------------------------

  /// Pushes [config] onto the default (root) navigator.
  ///
  /// The returned future resolves with the route's declared result type [T].
  Future<T> pushDefault<T>(RouteConfig<T> config) {
    _recordLastDefault();
    Foundry.log(
      LogEvent(
        level: LogLevel.debug,
        tag: 'nav.push',
        message: 'pushDefault route ${config.runtimeType}.',
      ),
    );

    return _defaultAdapter.push<T>(config);
  }

  /// Pushes [config] onto the navigator nearest to [context].
  Future<T> pushInContext<T>(BuildContext context, RouteConfig<T> config) {
    _recordLastContext(context);
    Foundry.log(
      LogEvent(
        level: LogLevel.debug,
        tag: 'nav.push',
        message: 'pushInContext route ${config.runtimeType}.',
      ),
    );

    return FlutterNavigatorAdapter.fromContext(context).push<T>(config);
  }

  /// Pushes [config] onto the navigator registered for [channelKey].
  ///
  /// Throws [StateError] when [channelKey] is not registered.
  Future<T> pushInChannel<T>(String channelKey, RouteConfig<T> config) {
    final NavigatorAdapter adapter = _resolveChannel(channelKey);
    _recordLastChannel(channelKey);
    Foundry.log(
      LogEvent(
        level: LogLevel.debug,
        tag: 'nav.push',
        message: 'pushInChannel "$channelKey" route ${config.runtimeType}.',
      ),
    );

    return adapter.push<T>(config);
  }

  /// Pushes [config] using an explicitly provided [navigator] adapter.
  Future<T> pushInNavigator<T>(
    NavigatorAdapter navigator,
    RouteConfig<T> config,
  ) {
    _recordLastNavigator(navigator);
    Foundry.log(
      LogEvent(
        level: LogLevel.debug,
        tag: 'nav.push',
        message: 'pushInNavigator route ${config.runtimeType}.',
      ),
    );

    return navigator.push<T>(config);
  }

  /// Pushes [config] onto the most recently used navigation target.
  ///
  /// Throws [StateError] if no previous target exists.
  Future<T> pushInLast<T>(RouteConfig<T> config) {
    Foundry.log(
      LogEvent(
        level: LogLevel.debug,
        tag: 'nav.push',
        message: 'pushInLast route ${config.runtimeType}.',
      ),
    );

    return _resolveLastAdapter().push<T>(config);
  }

  // ---------------------------------------------------------------------------
  // Pop
  // ---------------------------------------------------------------------------

  /// Pops the top route from the default navigator.
  ///
  /// Throws [StateError] when [result] violates the current route contract.
  void popDefault([Object? result]) {
    _recordLastDefault();
    Foundry.log(
      const LogEvent(
        level: LogLevel.debug,
        tag: 'nav.pop',
        message: 'popDefault called.',
      ),
    );

    _defaultAdapter.pop(result);
  }

  /// Pops the top route from the navigator nearest to [context].
  ///
  /// Throws [StateError] when [result] violates the current route contract.
  void popInContext(BuildContext context, [Object? result]) {
    _recordLastContext(context);
    Foundry.log(
      const LogEvent(
        level: LogLevel.debug,
        tag: 'nav.pop',
        message: 'popInContext called.',
      ),
    );

    FlutterNavigatorAdapter.fromContext(context).pop(result);
  }

  /// Pops the top route from the navigator registered for [channelKey].
  ///
  /// Throws [StateError] when [channelKey] is not registered or [result]
  /// violates the current route contract.
  void popInChannel(String channelKey, [Object? result]) {
    final NavigatorAdapter adapter = _resolveChannel(channelKey);
    _recordLastChannel(channelKey);
    Foundry.log(
      LogEvent(
        level: LogLevel.debug,
        tag: 'nav.pop',
        message: 'popInChannel "$channelKey" called.',
      ),
    );

    adapter.pop(result);
  }

  /// Pops the top route using an explicitly provided [navigator] adapter.
  ///
  /// Throws [StateError] when [result] violates the current route contract.
  void popInNavigator(NavigatorAdapter navigator, [Object? result]) {
    _recordLastNavigator(navigator);
    Foundry.log(
      const LogEvent(
        level: LogLevel.debug,
        tag: 'nav.pop',
        message: 'popInNavigator called.',
      ),
    );

    navigator.pop(result);
  }

  /// Pops the top route from the most recently used navigation target.
  ///
  /// Throws [StateError] if no previous target exists.
  void popInLast([Object? result]) {
    Foundry.log(
      const LogEvent(
        level: LogLevel.debug,
        tag: 'nav.pop',
        message: 'popInLast called.',
      ),
    );

    _resolveLastAdapter().pop(result);
  }

  // ---------------------------------------------------------------------------
  // canPop
  // ---------------------------------------------------------------------------

  /// Whether the default navigator can pop.
  bool canPopDefault() => _defaultAdapter.canPop();

  /// Whether the navigator nearest to [context] can pop.
  bool canPopInContext(BuildContext context) =>
      FlutterNavigatorAdapter.fromContext(context).canPop();

  /// Whether the navigator for [channelKey] can pop.
  bool canPopInChannel(String channelKey) =>
      _resolveChannel(channelKey).canPop();

  /// Whether [navigator] can pop.
  bool canPopInNavigator(NavigatorAdapter navigator) => navigator.canPop();

  /// Whether the most recently used target can pop.
  ///
  /// Returns `false` if no previous target exists or the target is stale.
  bool canPopInLast() {
    if (_lastTargetType == null) return false;
    try {
      return _resolveLastAdapter().canPop();
    } on StateError {
      Foundry.log(
        const LogEvent(
          level: LogLevel.warning,
          tag: 'nav.pop',
          message: 'canPopInLast failed because last target is stale.',
        ),
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // popToRoot
  // ---------------------------------------------------------------------------

  /// Pops all routes on the default navigator until only the root remains.
  void popToRootDefault() {
    _recordLastDefault();
    _defaultAdapter.popToRoot();
  }

  /// Pops all routes on the navigator nearest to [context] until only the root
  /// remains.
  void popToRootInContext(BuildContext context) {
    _recordLastContext(context);
    FlutterNavigatorAdapter.fromContext(context).popToRoot();
  }

  /// Pops all routes on the navigator for [channelKey] until only the root
  /// remains.
  void popToRootInChannel(String channelKey) {
    final NavigatorAdapter adapter = _resolveChannel(channelKey);
    _recordLastChannel(channelKey);
    adapter.popToRoot();
  }

  /// Pops all routes on [navigator] until only the root remains.
  void popToRootInNavigator(NavigatorAdapter navigator) {
    _recordLastNavigator(navigator);
    navigator.popToRoot();
  }

  /// Pops all routes on the most recently used target until only the root
  /// remains.
  ///
  /// Throws [StateError] if no previous target exists.
  void popToRootInLast() {
    _resolveLastAdapter().popToRoot();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  NavigatorAdapter _resolveChannel(String channelKey) {
    final NavigatorAdapter? adapter = _channels[channelKey];
    if (adapter == null) {
      Foundry.log(
        LogEvent(
          level: LogLevel.error,
          tag: 'nav.channel',
          message: 'Unknown channel "$channelKey".',
        ),
      );
      throw StateError(
        'No channel registered with key "$channelKey". '
        'Call registerChannel("$channelKey", adapter) first.',
      );
    }
    return adapter;
  }

  NavigatorAdapter _resolveLastAdapter() {
    switch (_lastTargetType) {
      case NavTargetType.defaultTarget:
        return _defaultAdapter;
      case NavTargetType.context:
        return FlutterNavigatorAdapter.fromContext(_lastContext!);
      case NavTargetType.channel:
        return _resolveChannel(_lastChannelKey!);
      case NavTargetType.navigator:
        return _lastNavigatorAdapter!;
      case null:
        Foundry.log(
          const LogEvent(
            level: LogLevel.error,
            tag: 'nav.service',
            message: 'No previous target for *InLast operation.',
          ),
        );
        throw StateError(
          'No previous navigation target. '
          'Use an explicit push/pop method before calling *InLast variants.',
        );
    }
  }

  void _recordLastDefault() {
    _lastTargetType = NavTargetType.defaultTarget;
    _lastContext = null;
    _lastChannelKey = null;
    _lastNavigatorAdapter = null;
  }

  void _recordLastContext(BuildContext context) {
    _lastTargetType = NavTargetType.context;
    _lastContext = context;
    _lastChannelKey = null;
    _lastNavigatorAdapter = null;
  }

  void _recordLastChannel(String channelKey) {
    _lastTargetType = NavTargetType.channel;
    _lastContext = null;
    _lastChannelKey = channelKey;
    _lastNavigatorAdapter = null;
  }

  void _recordLastNavigator(NavigatorAdapter adapter) {
    _lastTargetType = NavTargetType.navigator;
    _lastContext = null;
    _lastChannelKey = null;
    _lastNavigatorAdapter = adapter;
  }

  void _clearLastTarget() {
    _lastTargetType = null;
    _lastContext = null;
    _lastChannelKey = null;
    _lastNavigatorAdapter = null;
  }
}
