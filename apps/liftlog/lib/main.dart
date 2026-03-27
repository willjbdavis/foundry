import 'package:flutter/material.dart';
import 'app.dart';
import 'bootstrap/app_bootstrap.dart';

Future<void> main() async {
  final AppBootstrap bootstrap = await AppBootstrap.create();

  runApp(
    LiftLogApp(
      scope: bootstrap.scope,
      navigatorKey: bootstrap.navigatorKey,
      appThemeModel: bootstrap.appThemeModel,
    ),
  );
}
