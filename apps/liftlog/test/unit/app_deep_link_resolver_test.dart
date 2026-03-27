import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lift_log/core/navigation/app_deep_link_resolver.dart';

const Timeout _defaultTestTimeout = Timeout(Duration(seconds: 30));

void main() {
  test('resolves supported static deep links', () {
    expect(
      AppDeepLinkResolver.resolve(const RouteSettings(name: '/')),
      isNotNull,
    );
    expect(
      AppDeepLinkResolver.resolve(const RouteSettings(name: '/home')),
      isNotNull,
    );
    expect(
      AppDeepLinkResolver.resolve(const RouteSettings(name: '/history')),
      isNotNull,
    );
    expect(
      AppDeepLinkResolver.resolve(const RouteSettings(name: '/exercises')),
      isNotNull,
    );
    expect(
      AppDeepLinkResolver.resolve(const RouteSettings(name: '/settings')),
      isNotNull,
    );
    expect(
      AppDeepLinkResolver.resolve(const RouteSettings(name: '/about')),
      isNotNull,
    );
  }, timeout: _defaultTestTimeout);

  test('resolves supported args-based deep links', () {
    expect(
      AppDeepLinkResolver.resolve(const RouteSettings(name: '/history/w123')),
      isNotNull,
    );
    expect(
      AppDeepLinkResolver.resolve(
        const RouteSettings(name: '/exercises/e456/edit'),
      ),
      isNotNull,
    );
    expect(
      AppDeepLinkResolver.resolve(const RouteSettings(name: '/exercises/new')),
      isNotNull,
    );
  }, timeout: _defaultTestTimeout);

  test('returns null for unknown deep links', () {
    expect(
      AppDeepLinkResolver.resolve(const RouteSettings(name: '/unknown/path')),
      isNull,
    );
  }, timeout: _defaultTestTimeout);
}
