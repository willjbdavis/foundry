import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:foundry_annotations/foundry_annotations.dart';

/// Generator for @FoundryViewModel annotations.
///
/// Validates architecture boundaries and emits a helper mixin
/// `_$${ClassName}Helpers` containing:
/// - `_safeAsync()` for wrapped async operations
/// - `_setError()` when the ViewState has an `error` field
class ViewModelGenerator extends GeneratorForAnnotation<FoundryViewModel> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@FoundryViewModel can only be used on classes.',
        element: element,
      );
    }

    final classElement = element;
    final className = element.displayName;

    // ---- Architecture boundary validation ----
    final extendsViewModel = classElement.allSupertypes.any(
      (t) => t.element.name == 'FoundryViewModel',
    );
    if (!extendsViewModel) {
      throw InvalidGenerationSourceError(
        '@FoundryViewModel class must extend FoundryViewModel<S>.',
        element: element,
      );
    }

    // Detect if the ViewModel depends on another ViewModel (forbidden).
    final constructorParams = classElement.constructors
        .expand((c) => c.parameters)
        .toList();
    for (final param in constructorParams) {
      final paramType = param.type.element;
      if (paramType is ClassElement) {
        final isOtherViewModel = paramType.metadata.any(
          (m) =>
              m.element?.enclosingElement?.name == 'FoundryViewModel' ||
              (m.element is ConstructorElement &&
                  (m.element as ConstructorElement).enclosingElement.name ==
                      'FoundryViewModel'),
        );
        if (isOtherViewModel) {
          throw InvalidGenerationSourceError(
            '@FoundryViewModel cannot depend on another @FoundryViewModel. '
            'Move shared logic to a @FoundryModel.',
            element: element,
          );
        }
      }
    }

    final viewStateType = _resolveViewStateType(classElement);
    final helperMixinName = '_\$${className}Helpers';

    final buffer = StringBuffer();
    buffer.writeln('// Generated helpers for @FoundryViewModel $className');
    buffer.writeln('');

    // Check if the state type has an error field using the constant emitted
    // by ViewStateGenerator.  We do a best-effort check by looking for the
    // HasErrorField constant in the element's library.
    final hasErrorField = _detectErrorField(classElement, viewStateType);

    buffer.writeln(
      'mixin $helperMixinName on FoundryViewModel<$viewStateType> {',
    );
    buffer.writeln('');
    buffer.writeln('  /// Runs [action] inside a try/catch, forwarding any');
    buffer.writeln('  /// error to [invokeOnError] automatically.');
    buffer.writeln(
      '  Future<void> safeAsync(Future<void> Function() action) async {',
    );
    buffer.writeln('    try {');
    buffer.writeln('      await action();');
    buffer.writeln('    } catch (error, stackTrace) {');
    buffer.writeln('      await invokeOnError(error, stackTrace);');
    buffer.writeln('    }');
    buffer.writeln('  }');

    if (hasErrorField) {
      buffer.writeln('');
      buffer.writeln('  /// Emits a new state with [error] set on the');
      buffer.writeln('  /// `error` field of [$viewStateType].');
      buffer.writeln('  void setError(String error) {');
      buffer.writeln('    emitNewState(state.copyWith(error: error));');
      buffer.writeln('  }');
      buffer.writeln('');
      buffer.writeln('  /// Clears the error field on [$viewStateType].');
      buffer.writeln('  void clearError() {');
      buffer.writeln('    emitNewState(state.copyWith(error: null));');
      buffer.writeln('  }');
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  String _resolveViewStateType(ClassElement classElement) {
    for (final supertype in classElement.allSupertypes) {
      if (supertype.element.name == 'FoundryViewModel' &&
          supertype.typeArguments.isNotEmpty) {
        return supertype.typeArguments.first.getDisplayString(
          withNullability: false,
        );
      }
    }
    return 'dynamic';
  }

  /// Best-effort: check if the resolved state type ClassElement has an error
  /// field of type String? or Object?.
  bool _detectErrorField(ClassElement viewModelClass, String stateTypeName) {
    for (final supertype in viewModelClass.allSupertypes) {
      if (supertype.element.name == 'FoundryViewModel' &&
          supertype.typeArguments.isNotEmpty) {
        final stateElement = supertype.typeArguments.first.element;
        if (stateElement is ClassElement) {
          return stateElement.fields.any(
            (f) =>
                f.name == 'error' &&
                !f.isStatic &&
                !f.isSynthetic &&
                (f.type.getDisplayString(withNullability: true) == 'String?' ||
                    f.type.getDisplayString(withNullability: true) ==
                        'Object?'),
          );
        }
      }
    }
    return false;
  }
}
