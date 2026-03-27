import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:foundry_annotations/foundry_annotations.dart';

/// Generator for @FoundryViewState annotations.
///
/// Emits a mixin `_$${ClassName}Mixin` that the user applies to their
/// immutable state class:
///
/// ```dart
/// part 'home_state.g.dart';
///
/// @FoundryViewState()
/// class HomeState with _$HomeStateMixin {
///   final bool isLoading;
///   final String? error;
///   HomeState({this.isLoading = false, this.error});
/// }
/// ```
class ViewStateGenerator extends GeneratorForAnnotation<FoundryViewState> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@FoundryViewState can only be used on classes.',
        element: element,
      );
    }

    final classElement = element;
    final className = element.displayName;
    final mixinName = '_\$${className}Mixin';
    final sentinelName = '_\$${className}Sentinel';

    final instanceFields = classElement.fields
        .where((field) => !field.isStatic && !field.isSynthetic)
        .toList();

    // Detect if there is an error field (String? or Object?) for Phase B.
    final hasErrorField = instanceFields.any(
      (f) =>
          f.name == 'error' &&
          (f.type.getDisplayString(withNullability: true) == 'String?' ||
              f.type.getDisplayString(withNullability: true) == 'Object?'),
    );

    final buffer = StringBuffer();

    buffer.writeln(
      '// ignore_for_file: unused_element, annotate_overrides, prefer_interpolation_to_compose_strings',
    );
    buffer.writeln('');
    buffer.writeln('// Generated code for @FoundryViewState $className');
    buffer.writeln('');
    buffer.writeln('const $sentinelName = Object();');
    buffer.writeln('');
    buffer.writeln('/// Whether [$className] has an `error` field.');
    buffer.writeln('const bool \$${className}HasErrorField = $hasErrorField;');
    buffer.writeln('');

    // Mixin declaration is unconstrained so it can be applied directly to the
    // annotated class (e.g. `class X with _$XMixin`).
    buffer.writeln('mixin $mixinName {');

    // copyWith
    if (instanceFields.isNotEmpty) {
      buffer.writeln('  $className copyWith({');
      for (final field in instanceFields) {
        buffer.writeln('    Object? ${field.name} = $sentinelName,');
      }
      buffer.writeln('  }) {');
      buffer.writeln('    final $className self = this as $className;');
      buffer.writeln('    return $className(');
      for (final field in instanceFields) {
        final typeName = field.type.getDisplayString(withNullability: true);
        buffer.writeln(
          '      ${field.name}: identical(${field.name}, $sentinelName)'
          ' ? self.${field.name} : ${field.name} as $typeName,',
        );
      }
      buffer.writeln('    );');
      buffer.writeln('  }');
      buffer.writeln('');
    }

    // operator ==
    buffer.writeln('  @override');
    buffer.writeln('  bool operator ==(Object other) {');
    buffer.writeln('    if (identical(this, other)) return true;');
    buffer.writeln('    if (other.runtimeType != runtimeType) return false;');
    if (instanceFields.isEmpty) {
      buffer.writeln('    return other is $className;');
    } else {
      buffer.writeln('    final $className self = this as $className;');
      buffer.writeln('    return other is $className &&');
      for (var i = 0; i < instanceFields.length; i++) {
        final field = instanceFields[i];
        final suffix = i == instanceFields.length - 1 ? ';' : ' &&';
        buffer.writeln(
          '        self.${field.name} == other.${field.name}$suffix',
        );
      }
    }
    buffer.writeln('  }');
    buffer.writeln('');

    // hashCode
    buffer.writeln('  @override');
    if (instanceFields.isEmpty) {
      buffer.writeln('  int get hashCode => runtimeType.hashCode;');
    } else {
      final hashArgs = instanceFields.map((f) => 'self.${f.name}').join(', ');
      buffer.writeln('  int get hashCode {');
      buffer.writeln('    final $className self = this as $className;');
      buffer.writeln('    return Object.hash($hashArgs);');
      buffer.writeln('  }');
    }
    buffer.writeln('');

    // toString
    buffer.writeln('  @override');
    buffer.writeln('  String toString() {');
    if (instanceFields.isEmpty) {
      buffer.writeln("    return '$className()';");
    } else {
      buffer.writeln('    final $className self = this as $className;');
      buffer.writeln('    final List<String> values = <String>[');
      for (final field in instanceFields) {
        buffer.writeln(
          "      '${field.name}: ' + self.${field.name}.toString(),",
        );
      }
      buffer.writeln('    ];');
      buffer.writeln("    return '$className(' + values.join(', ') + ')';");
    }
    buffer.writeln('  }');

    buffer.writeln('}');

    return buffer.toString();
  }
}
