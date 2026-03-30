import 'package:flutter_test/flutter_test.dart';
import 'package:foundry_annotations/foundry_annotations.dart';

Uri parseArgsFromUri(final Uri uri) => uri;

void main() {
  group('Annotations', () {
    test('ViewState annotation defaults are correct', () {
      const FoundryViewState viewState = FoundryViewState();
      expect(viewState.name, isNull);
    });

    test('ViewState supports custom name', () {
      const FoundryViewState viewState = FoundryViewState(name: 'HomeState');
      expect(viewState.name, 'HomeState');
    });

    test('ServiceState annotation defaults are correct', () {
      const FoundryServiceState serviceState = FoundryServiceState();
      expect(serviceState.persistent, isFalse);
      expect(serviceState.name, isNull);
    });

    test('ServiceState supports persistent and name parameters', () {
      const FoundryServiceState serviceState = FoundryServiceState(
        persistent: true,
        name: 'SessionState',
      );
      expect(serviceState.persistent, isTrue);
      expect(serviceState.name, 'SessionState');
    });

    test('ViewModel annotation defaults are correct', () {
      const FoundryViewModel viewModel = FoundryViewModel();
      expect(viewModel.name, isNull);
      expect(viewModel.lifetime, 'scoped');
    });

    test('ViewModel supports custom name and lifetime', () {
      const FoundryViewModel viewModel = FoundryViewModel(
        name: 'HomeViewModel',
        lifetime: 'singleton',
      );
      expect(viewModel.name, 'HomeViewModel');
      expect(viewModel.lifetime, 'singleton');
    });

    test('Service annotation defaults are correct', () {
      const FoundryService service = FoundryService();
      expect(service.stateful, isFalse);
      expect(service.dependsOn, isNull);
      expect(service.name, isNull);
      expect(service.lifetime, 'singleton');
    });

    test('Service supports all parameters', () {
      const FoundryService service = FoundryService(
        stateful: true,
        dependsOn: <Type>[String, int],
        name: 'NotificationService',
        lifetime: 'transient',
      );

      expect(service.stateful, isTrue);
      expect(service.dependsOn, <Type>[String, int]);
      expect(service.name, 'NotificationService');
      expect(service.lifetime, 'transient');
    });

    test('View annotation defaults are correct', () {
      const FoundryView view = FoundryView();
      expect(view.route, isNull);
      expect(view.args, isNull);
      expect(view.result, isNull);
      expect(view.deepLink, isNull);
      expect(view.deepLinkArgsFactory, isNull);
      expect(view.name, isNull);
    });

    test('View supports route args result deepLink parser and name', () {
      const FoundryView view = FoundryView(
        route: '/home',
        args: String,
        result: bool,
        deepLink: '/home/:id',
        deepLinkArgsFactory: parseArgsFromUri,
        name: 'HomeView',
      );

      expect(view.route, '/home');
      expect(view.args, String);
      expect(view.result, bool);
      expect(view.deepLink, '/home/:id');
      expect(view.deepLinkArgsFactory, parseArgsFromUri);
      expect(view.name, 'HomeView');
    });

    test('View supports typed args and result without a deepLink', () {
      const FoundryView view = FoundryView(
        route: '/product',
        args: String,
        result: bool,
      );

      expect(view.route, '/product');
      expect(view.args, String);
      expect(view.result, bool);
      expect(view.deepLink, isNull);
      expect(view.deepLinkArgsFactory, isNull);
    });

    test('ViewModel supports transient lifetime', () {
      const FoundryViewModel viewModel = FoundryViewModel(
        lifetime: 'transient',
      );
      expect(viewModel.lifetime, 'transient');
    });

    test('Service supports scoped lifetime', () {
      const FoundryService service = FoundryService(lifetime: 'scoped');
      expect(service.lifetime, 'scoped');
    });

    test('Service supports stateless named service', () {
      const FoundryService service = FoundryService(name: 'AnalyticsService');
      expect(service.stateful, isFalse);
      expect(service.name, 'AnalyticsService');
      expect(service.lifetime, 'singleton');
      expect(service.dependsOn, isNull);
    });
  });
}
