import 'package:flutter/material.dart';
import 'package:foundry_flutter/foundry_flutter.dart';

import 'core/navigation/app_deep_link_resolver.dart';
import 'core/theme/app_theme_data.dart';
import 'core/theme/app_theme_model.dart';
import 'features/shell/app_shell_view.dart';

class LiftLogApp extends StatelessWidget {
  const LiftLogApp({
    required this.scope,
    required this.navigatorKey,
    required this.appThemeModel,
    super.key,
  });

  final Scope scope;
  final GlobalKey<NavigatorState> navigatorKey;
  final AppThemeModel appThemeModel;

  @override
  Widget build(BuildContext context) {
    return FoundryScope(
      scope: scope,
      child: AnimatedBuilder(
        animation: appThemeModel,
        builder: (BuildContext context, Widget? child) {
          return MaterialApp(
            title: 'Lift Log',
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            initialRoute: '/',
            onGenerateRoute: AppDeepLinkResolver.resolve,
            onUnknownRoute: (RouteSettings settings) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const AppShellView(),
              );
            },
            theme: AppThemeData.light,
            darkTheme: AppThemeData.dark,
            themeMode: appThemeModel.themeMode,
          );
        },
      ),
    );
  }
}
