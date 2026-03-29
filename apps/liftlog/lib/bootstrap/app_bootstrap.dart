import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:foundry_flutter/foundry_flutter.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

import '../app_container.g.dart';
import '../core/persistence/hive_database_service.dart';
import '../core/theme/app_theme_model.dart';

class AppBootstrap {
  AppBootstrap._({
    required this.scope,
    required this.navigatorKey,
    required this.databaseService,
    required this.appThemeModel,
  });

  final Scope scope;
  final GlobalKey<NavigatorState> navigatorKey;
  final HiveDatabaseService databaseService;
  final AppThemeModel appThemeModel;

  static Future<AppBootstrap> create() async {
    WidgetsFlutterBinding.ensureInitialized();
    _configureLogging();

    final GlobalScope scope = GlobalScope.create();
    registerGeneratedGraph(scope);
    await initializeGeneratedGraph(scope);

    final HiveDatabaseService databaseService = scope
        .resolve<HiveDatabaseService>();
    final AppThemeModel appThemeModel = scope.resolve<AppThemeModel>();

    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    final FlutterNavigatorAdapter defaultAdapter =
        FlutterNavigatorAdapter.fromKey(navigatorKey);

    FoundryNavigator.configure(defaultAdapter);
    FoundryNavigation.configure(
      FoundryNavigation(defaultAdapter: defaultAdapter),
    );

    return AppBootstrap._(
      scope: scope,
      navigatorKey: navigatorKey,
      databaseService: databaseService,
      appThemeModel: appThemeModel,
    );
  }

  static void _configureLogging() {
    if (kReleaseMode) {
      return;
    }

    Foundry.configureLoggerFn((LogEvent event) {
      final String tag = event.tag ?? 'foundry';
      debugPrint('[${event.level.name}] $tag: ${event.message}');
      if (event.error != null) {
        debugPrint('[${event.level.name}] $tag error: ${event.error}');
      }
      if (event.stackTrace != null) {
        debugPrint(event.stackTrace.toString());
      }
    });
  }
}
