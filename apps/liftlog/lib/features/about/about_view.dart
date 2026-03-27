import 'package:flutter/material.dart';
import 'package:foundry_annotations/foundry_annotations.dart' as foundry;
import 'package:foundry_flutter/foundry_flutter.dart';
import 'package:foundry_navigation_flutter/foundry_navigation_flutter.dart';

part 'about_view.g.dart';

@foundry.FoundryViewState()
class AboutState with _$AboutStateMixin {
  final String appName;
  final String appVersion;

  const AboutState({this.appName = 'Lift Log', this.appVersion = '0.1.0'});
}

@foundry.FoundryViewModel()
class AboutViewModel extends FoundryViewModel<AboutState> {
  AboutViewModel() {
    emitNewState(const AboutState());
  }
}

@foundry.FoundryView(route: '/about', deepLink: '/about')
class AboutView extends FoundryView<AboutViewModel, AboutState> {
  const AboutView({super.key});

  @override
  Widget buildWithState(
    BuildContext context,
    AboutState? oldState,
    AboutState state,
  ) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Center(
        child: Text('${state.appName} - ${state.appVersion} placeholder'),
      ),
    );
  }
}
