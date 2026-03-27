import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ViewGenerator deep-link output', () {
    test(
      'exercise editor output contains primitive auto-map and bool guard',
      () {
        final String gFile = _readWorkspaceFile(
          'apps/liftlog/lib/features/exercises/exercise_editor_view.g.dart',
        );

        expect(
          gFile,
          contains("params['exerciseId'] ?? uri.queryParameters['exerciseId']"),
        );
        expect(gFile, contains('selectAfterSaveValue = false;'));
        expect(gFile, contains('if (selectAfterSaveRaw == "true") {'));
        expect(gFile, contains('} else if (selectAfterSaveRaw == "false") {'));
        expect(gFile, contains('return ExerciseEditorViewRoute(args);'));
      },
    );

    test('workout detail output contains required field null guard', () {
      final String gFile = _readWorkspaceFile(
        'apps/liftlog/lib/features/history/workout_detail_view.g.dart',
      );

      expect(gFile, contains('if (workoutIdRaw == null) {'));
      expect(gFile, contains('return null;'));
      expect(gFile, contains('return WorkoutDetailViewRoute(args);'));
    });

    test(
      'view generator source includes deepLinkArgsFactory branch template',
      () {
        final String generatorSource = _readWorkspaceFile(
          'packages/foundry_generator/lib/src/generators/view_generator.dart',
        );

        expect(
          generatorSource,
          contains('final dynamic parsedArgs = \$factoryExpression(uri);'),
        );
        expect(
          generatorSource,
          contains('if (parsedArgs is! \$argsType) return null;'),
        );
        expect(
          generatorSource,
          contains('return \${className}Route(parsedArgs);'),
        );
      },
    );
  });
}

String _readWorkspaceFile(String workspaceRelativePath) {
  final Directory packageDir = Directory.current;
  final String path =
      '${packageDir.parent.parent.path.replaceAll('\\', '/')}/$workspaceRelativePath';
  return File(path).readAsStringSync();
}
