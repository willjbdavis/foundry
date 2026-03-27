import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generators/view_state_generator.dart';
import 'src/generators/model_state_generator.dart';
import 'src/generators/view_model_generator.dart';
import 'src/generators/model_generator.dart';
import 'src/generators/view_generator.dart';
import 'src/generators/container_generator.dart';

export 'src/generators/view_state_generator.dart';
export 'src/generators/model_state_generator.dart';
export 'src/generators/view_model_generator.dart';
export 'src/generators/model_generator.dart';
export 'src/generators/view_generator.dart';
export 'src/generators/container_generator.dart';
export 'src/generators/generator_utils.dart';

Builder viewStateBuilderFactory(BuilderOptions options) =>
    SharedPartBuilder([ViewStateGenerator()], 'view_state_builder');

Builder modelStateBuilderFactory(BuilderOptions options) =>
    SharedPartBuilder([ModelStateGenerator()], 'model_state_builder');

Builder viewModelBuilderFactory(BuilderOptions options) =>
    SharedPartBuilder([ViewModelGenerator()], 'view_model_builder');

Builder modelBuilderFactory(BuilderOptions options) =>
    SharedPartBuilder([ModelGenerator()], 'model_builder');

Builder viewBuilderFactory(BuilderOptions options) =>
    SharedPartBuilder([ViewGenerator()], 'view_builder');

Builder containerBuilderFactory(BuilderOptions options) =>
    AppContainerBuilder();

Builder deepLinksBuilderFactory(BuilderOptions options) =>
    AppDeepLinksBuilder();

class AppDeepLinksBuilder implements Builder {
  @override
  final Map<String, List<String>> buildExtensions = const {
    'lib/app_module.dart': ['lib/app_deep_links.g.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final AssetId output = AssetId(
      buildStep.inputId.package,
      'lib/app_deep_links.g.dart',
    );

    await buildStep.writeAsString(
      output,
      '// Generated file for app-level deep-link registry.\n',
    );
  }
}
