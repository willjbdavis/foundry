import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundry_core/foundry_core.dart';
import 'package:lift_log/app_deep_links.g.dart';

const Timeout _defaultTestTimeout = Timeout(Duration(seconds: 30));

void main() {
  setUp(() {
    Foundry.clearDeepLinkFallbackPath();
  });

  tearDown(() {
    Foundry.clearDeepLinkFallbackPath();
  });

  test('resolves supported static deep links', () {
    expect(
      GeneratedDeepLinkResolver.resolve(const RouteSettings(name: '/')),
      isNotNull,
    );
    expect(
      GeneratedDeepLinkResolver.resolve(const RouteSettings(name: '/home')),
      isNotNull,
    );
    expect(
      GeneratedDeepLinkResolver.resolve(const RouteSettings(name: '/history')),
      isNotNull,
    );
    expect(
      GeneratedDeepLinkResolver.resolve(
        const RouteSettings(name: '/exercises'),
      ),
      isNotNull,
    );
    expect(
      GeneratedDeepLinkResolver.resolve(const RouteSettings(name: '/settings')),
      isNotNull,
    );
    expect(
      GeneratedDeepLinkResolver.resolve(const RouteSettings(name: '/about')),
      isNotNull,
    );
  }, timeout: _defaultTestTimeout);

  test('resolves supported args-based deep links', () {
    expect(
      GeneratedDeepLinkResolver.resolve(
        const RouteSettings(name: '/history/w123'),
      ),
      isNotNull,
    );
    expect(
      GeneratedDeepLinkResolver.resolve(
        const RouteSettings(name: '/exercises/e456/edit'),
      ),
      isNotNull,
    );
  }, timeout: _defaultTestTimeout);

  test(
    'returns null for routes that are not declared as deep links',
    () {
      expect(
        GeneratedDeepLinkResolver.resolve(
          const RouteSettings(name: '/exercises/new'),
        ),
        isNull,
      );
    },
    timeout: _defaultTestTimeout,
  );

  test('returns null for unknown deep links', () {
    expect(
      GeneratedDeepLinkResolver.resolve(
        const RouteSettings(name: '/unknown/path'),
      ),
      isNull,
    );
  }, timeout: _defaultTestTimeout);

  test(
    'uses configured fallback path when deep link misses',
    () {
      Foundry.configureDeepLinkFallbackPath('/home');

      expect(
        GeneratedDeepLinkResolver.resolve(
          const RouteSettings(name: '/missing/deep/link'),
        ),
        isNotNull,
      );
    },
    timeout: _defaultTestTimeout,
  );
}
