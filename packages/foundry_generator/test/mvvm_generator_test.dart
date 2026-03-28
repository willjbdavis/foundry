import 'package:flutter_test/flutter_test.dart';
import 'package:foundry_generator/src/generators/container_generator.dart';
import 'package:foundry_generator/src/generators/generator_utils.dart';

void main() {
  // ── resolveViewStateTypeFromViewModelType ─────────────────────────────────

  group('resolveViewStateTypeFromViewModelType', () {
    test('infers state type from a ViewModel naming convention', () {
      expect(
        resolveViewStateTypeFromViewModelType('LoginViewModel'),
        'LoginState',
      );
      expect(
        resolveViewStateTypeFromViewModelType('AccountViewModel'),
        'AccountState',
      );
    });

    test('falls back to default state type when name does not match', () {
      expect(resolveViewStateTypeFromViewModelType('VM'), 'ViewModelState');
      expect(
        resolveViewStateTypeFromViewModelType('ProfileVm'),
        'ViewModelState',
      );
    });
  });

  // ── singleQuotedLiteralOrNull ─────────────────────────────────────────────

  group('singleQuotedLiteralOrNull', () {
    test('emits escaped single-quoted metadata literal or null', () {
      expect(singleQuotedLiteralOrNull(null), 'null');
      expect(singleQuotedLiteralOrNull('/home'), "'/home'");
      expect(singleQuotedLiteralOrNull("route/'id'"), "'route/\\'id\\''");
    });
  });

  // ── deepLinkPatternToRegexSource ──────────────────────────────────────────

  group('deepLinkPatternToRegexSource', () {
    test('literal-only pattern has no capture groups', () {
      final src = deepLinkPatternToRegexSource('/home');
      expect(src, startsWith('^'));
      expect(src, endsWith(r'$'));
      // No named group for a static path.
      expect(src, isNot(contains('(?<')));
    });

    test('single path param becomes a named capture group', () {
      final src = deepLinkPatternToRegexSource('/profile/:userId');
      expect(src, contains('(?<userId>[^/]+)'));
    });

    test('multiple path params each get their own named capture group', () {
      final src = deepLinkPatternToRegexSource('/user/:id/tab/:tab');
      expect(src, contains('(?<id>[^/]+)'));
      expect(src, contains('(?<tab>[^/]+)'));
    });

    test('generated regex anchors match correctly', () {
      final src = deepLinkPatternToRegexSource('/profile/:userId');
      final regex = RegExp(src);
      expect(regex.hasMatch('/profile/42'), isTrue);
      expect(regex.hasMatch('/profile/'), isFalse);
      expect(regex.hasMatch('/other/42'), isFalse);
    });
  });

  // ── deepLinkPathParamNames ────────────────────────────────────────────────

  group('deepLinkPathParamNames', () {
    test('returns empty list for static patterns', () {
      expect(deepLinkPathParamNames('/home'), isEmpty);
    });

    test('returns param names in declaration order', () {
      expect(deepLinkPathParamNames('/user/:id/tab/:tab'), ['id', 'tab']);
    });
  });

  // ── matchDeepLinkPattern ──────────────────────────────────────────────────

  group('matchDeepLinkPattern', () {
    test('returns null for non-matching URI', () {
      expect(
        matchDeepLinkPattern('/profile/:userId', Uri.parse('/other/42')),
        isNull,
      );
    });

    test('returns empty map for static match', () {
      expect(matchDeepLinkPattern('/home', Uri.parse('/home')), isEmpty);
    });

    test('extracts single path parameter', () {
      expect(
        matchDeepLinkPattern('/profile/:userId', Uri.parse('/profile/42')),
        {'userId': '42'},
      );
    });

    test('extracts multiple path parameters', () {
      expect(
        matchDeepLinkPattern(
          '/user/:id/tab/:tab',
          Uri.parse('/user/7/tab/settings'),
        ),
        {'id': '7', 'tab': 'settings'},
      );
    });
  });

  // ── coercePrimitive ───────────────────────────────────────────────────────

  group('coercePrimitive', () {
    test('String is returned verbatim', () {
      expect(coercePrimitive('String', 'hello'), 'hello');
    });

    test('int is parsed', () {
      expect(coercePrimitive('int', '42'), 42);
    });

    test('double is parsed', () {
      expect(coercePrimitive('double', '3.14'), 3.14);
    });

    test('bool true/false are parsed', () {
      expect(coercePrimitive('bool', 'true'), isTrue);
      expect(coercePrimitive('bool', 'false'), isFalse);
    });

    test('bool with invalid value returns null', () {
      expect(coercePrimitive('bool', 'yes'), isNull);
    });

    test('int with non-numeric string returns null', () {
      expect(coercePrimitive('int', 'abc'), isNull);
    });

    test('DateTime is parsed from ISO-8601', () {
      final result = coercePrimitive('DateTime', '2024-01-15T00:00:00.000Z');
      expect(result, isA<DateTime>());
      expect((result! as DateTime).year, 2024);
    });

    test('unsupported type returns null', () {
      expect(coercePrimitive('List', '[]'), isNull);
    });
  });

  // ── constructor-first dependency helpers ─────────────────────────────────

  group('inferConstructorServiceDependencies', () {
    test('returns only known service types in constructor order', () {
      final inferred = inferConstructorServiceDependencies(
        ['HiveDatabaseService', 'Logger', 'SettingsRepository'],
        {'HiveDatabaseService', 'SettingsRepository'},
      );

      expect(inferred, ['HiveDatabaseService', 'SettingsRepository']);
    });

    test('deduplicates repeated constructor service types', () {
      final inferred = inferConstructorServiceDependencies(
        ['WorkoutRepository', 'WorkoutRepository', 'String'],
        {'WorkoutRepository'},
      );

      expect(inferred, ['WorkoutRepository']);
    });
  });

  group('mergeServiceDependencies', () {
    test(
      'keeps constructor dependencies first and appends explicit extras',
      () {
        final merged = mergeServiceDependencies(
          constructorDependencies: [
            'HiveDatabaseService',
            'SettingsRepository',
          ],
          explicitDependsOn: ['SettingsRepository', 'AppThemeModel'],
        );

        expect(merged, [
          'HiveDatabaseService',
          'SettingsRepository',
          'AppThemeModel',
        ]);
      },
    );
  });

  group('topologicallySortDependencyGraph', () {
    test('sorts constructor-first merged graph order correctly', () {
      final sorted = topologicallySortDependencyGraph({
        'HiveDatabaseService': [],
        'SettingsRepository': ['HiveDatabaseService'],
        'AppThemeModel': ['SettingsRepository'],
      });

      expect(sorted, [
        'HiveDatabaseService',
        'SettingsRepository',
        'AppThemeModel',
      ]);
    });

    test('is deterministic for tie nodes', () {
      final sorted = topologicallySortDependencyGraph({
        'CModel': [],
        'AModel': [],
        'BModel': [],
      });

      expect(sorted, ['AModel', 'BModel', 'CModel']);
    });

    test('throws for cyclic dependency graph', () {
      expect(
        () => topologicallySortDependencyGraph({
          'AuthModel': ['SessionModel'],
          'SessionModel': ['AuthModel'],
        }),
        throwsA(isA<StateError>()),
      );
    });
  });
}
