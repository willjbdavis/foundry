import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:foundry_annotations/foundry_annotations.dart';
import 'generator_utils.dart';

/// Generator for @FoundryView annotations.
///
/// - Validates View extends `FoundryView<TViewModel, TState>`
/// - Generates a typed `${ClassName}Route extends RouteConfig<T>`
/// - Generates a `BuildContext` push extension
/// - Generates static `matchDeepLink(Uri)` if deepLink is set
class ViewGenerator extends GeneratorForAnnotation<FoundryView> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@FoundryView can only be used on classes.',
        element: element,
      );
    }

    final className = element.displayName;

    final routeValue = annotation.peek('route')?.stringValue;
    final deepLinkValue = annotation.peek('deepLink')?.stringValue;
    final argsType = _resolveArgsType(annotation);
    final resultType = _resolveResultType(annotation) ?? 'void';
    final pushReturnType = 'Future<$resultType>';

    final routeLiteral = singleQuotedLiteralOrNull(routeValue);
    final deepLinkLiteral = singleQuotedLiteralOrNull(deepLinkValue);

    // Validate: if deepLink has path params and no args/factory -> build error
    if (deepLinkValue != null) {
      final hasParams = deepLinkPathParamNames(deepLinkValue).isNotEmpty;
      final hasArgs = argsType != null;
      final hasFactory =
          annotation.peek('deepLinkArgsFactory') != null &&
          !annotation.peek('deepLinkArgsFactory')!.isNull;
      if (hasParams && !hasArgs && !hasFactory) {
        throw InvalidGenerationSourceError(
          '@FoundryView deepLink "$deepLinkValue" has path parameters but no `args` '
          'type or `deepLinkArgsFactory` was provided.',
          element: element,
        );
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('// Generated code for @FoundryView $className');
    buffer.writeln('');

    // Route constants on the view class (via an extension).
    final routeType = routeValue != null ? 'String' : 'String?';
    final deepLinkType = deepLinkValue != null ? 'String' : 'String?';
    buffer.writeln('extension ${className}GeneratedExt on $className {');
    buffer.writeln('  static const $routeType generatedRoute = $routeLiteral;');
    buffer.writeln(
      '  static const $deepLinkType generatedDeepLink = $deepLinkLiteral;',
    );
    buffer.writeln('}');
    buffer.writeln('');

    // RouteConfig subclass.
    final hasArgs = argsType != null;
    buffer.writeln(
      '/// Typed route for [$className]. Use [${className}Route] to navigate.',
    );
    if (hasArgs) {
      buffer.writeln(
        'class ${className}Route extends RouteConfig<$resultType> {',
      );
      buffer.writeln('  const ${className}Route(this.args);');
      buffer.writeln('');
      buffer.writeln('  final $argsType args;');
    } else {
      buffer.writeln(
        'class ${className}Route extends RouteConfig<$resultType> {',
      );
      buffer.writeln('  const ${className}Route();');
    }
    buffer.writeln('');
    buffer.writeln('  @override');
    buffer.writeln("  String? get name => $routeLiteral;");
    buffer.writeln('');
    buffer.writeln('  @override');
    buffer.writeln('  Route<$resultType> build(BuildContext context) {');
    if (hasArgs) {
      buffer.writeln(
        '    return MaterialPageRoute<$resultType>(builder: (_) => $className(args: args));',
      );
    } else {
      buffer.writeln(
        '    return MaterialPageRoute<$resultType>(builder: (_) => const $className());',
      );
    }
    buffer.writeln('  }');
    buffer.writeln('');
    buffer.writeln('  @override');
    buffer.writeln(
      '  Route<$resultType> buildDeepLink(RouteSettings settings) {',
    );
    if (hasArgs) {
      buffer.writeln(
        '    return MaterialPageRoute<$resultType>(settings: settings, builder: (_) => $className(args: args));',
      );
    } else {
      buffer.writeln(
        '    return MaterialPageRoute<$resultType>(settings: settings, builder: (_) => const $className());',
      );
    }
    buffer.writeln('  }');

    // matchDeepLink static method.
    if (deepLinkValue != null) {
      buffer.writeln('');
      buffer.writeln(
        '  /// Returns a [$className Route] if [uri] matches the deep link pattern,',
      );
      buffer.writeln('  /// otherwise returns null.');
      buffer.writeln('  static ${className}Route? matchDeepLink(Uri uri) {');
      buffer.writeln('    final Uri patternUri = Uri.parse($deepLinkLiteral);');
      buffer.writeln(
        '    final List<String> pattern = patternUri.pathSegments;',
      );
      buffer.writeln('    final List<String> actual = uri.pathSegments;');
      buffer.writeln('    if (pattern.length != actual.length) return null;');
      buffer.writeln(
        '    final Map<String, String> params = <String, String>{};',
      );
      buffer.writeln('    for (int i = 0; i < pattern.length; i++) {');
      buffer.writeln('      final String p = pattern[i];');
      buffer.writeln('      final String a = actual[i];');
      buffer.writeln("      if (p.startsWith(':')) {");
      buffer.writeln('        params[p.substring(1)] = a;');
      buffer.writeln('        continue;');
      buffer.writeln('      }');
      buffer.writeln('      if (p != a) return null;');
      buffer.writeln('    }');
      if (!hasArgs) {
        buffer.writeln('    return const ${className}Route();');
      } else {
        final String? factoryExpression = _resolveDeepLinkArgsFactoryExpression(
          annotation,
        );
        if (factoryExpression != null) {
          buffer.writeln(
            '    final dynamic parsedArgs = $factoryExpression(uri);',
          );
          buffer.writeln('    if (parsedArgs is! $argsType) return null;');
          buffer.writeln('    return ${className}Route(parsedArgs);');
        } else {
          final _ArgsConstructorShape? argsCtor = _resolveArgsConstructorShape(
            annotation,
          );
          if (argsCtor == null) {
            throw InvalidGenerationSourceError(
              '@FoundryView args type could not be resolved for deep-link mapping.',
              element: element,
            );
          }
          for (final _ArgsParameterInfo param in argsCtor.parameters) {
            final String typeName = param.typeName;
            final String rawVar = '${param.name}Raw';
            final String valueVar = '${param.name}Value';
            buffer.writeln(
              "    final String? $rawVar = params['${param.name}'] ?? uri.queryParameters['${param.name}'];",
            );
            buffer.writeln('    final Object? $valueVar;');
            buffer.writeln('    if ($rawVar == null) {');
            if (param.defaultValueCode != null) {
              buffer.writeln('      $valueVar = ${param.defaultValueCode};');
            } else if (param.isNullable) {
              buffer.writeln('      $valueVar = null;');
            } else {
              buffer.writeln('      return null;');
            }
            buffer.writeln('    } else {');
            if (typeName == 'String') {
              buffer.writeln('      $valueVar = $rawVar;');
            } else if (typeName == 'int') {
              buffer.writeln(
                '      final int? parsed = int.tryParse($rawVar);',
              );
              buffer.writeln('      if (parsed == null) return null;');
              buffer.writeln('      $valueVar = parsed;');
            } else if (typeName == 'double') {
              buffer.writeln(
                '      final double? parsed = double.tryParse($rawVar);',
              );
              buffer.writeln('      if (parsed == null) return null;');
              buffer.writeln('      $valueVar = parsed;');
            } else if (typeName == 'bool') {
              buffer.writeln('      if ($rawVar == "true") {');
              buffer.writeln('        $valueVar = true;');
              buffer.writeln('      } else if ($rawVar == "false") {');
              buffer.writeln('        $valueVar = false;');
              buffer.writeln('      } else {');
              buffer.writeln('        return null;');
              buffer.writeln('      }');
            } else if (typeName == 'DateTime') {
              buffer.writeln(
                '      final DateTime? parsed = DateTime.tryParse($rawVar);',
              );
              buffer.writeln('      if (parsed == null) return null;');
              buffer.writeln('      $valueVar = parsed;');
            } else {
              buffer.writeln('      return null;');
            }
            buffer.writeln('    }');
          }

          buffer.writeln('    final $argsType args = $argsType(');
          for (final _ArgsParameterInfo param in argsCtor.parameters) {
            final String typeName = param.typeName;
            final String castExpr =
                '${param.name}Value as $typeName${param.isNullable ? '?' : ''}';
            if (param.isNamed) {
              buffer.writeln('      ${param.name}: $castExpr,');
            } else {
              buffer.writeln('      $castExpr,');
            }
          }
          buffer.writeln('    );');
          buffer.writeln('    return ${className}Route(args);');
        }
      }
      buffer.writeln('  }');
    }

    buffer.writeln('}');
    buffer.writeln('');

    // BuildContext push extension.
    buffer.writeln('/// Navigation helpers for [$className].');
    buffer.writeln('extension ${className}Navigation on BuildContext {');
    if (hasArgs) {
      buffer.writeln('  $pushReturnType push$className($argsType args) =>');
      buffer.writeln(
        '      FoundryNavigator.push(${className}Route(args), context: this);',
      );
    } else {
      buffer.writeln('  $pushReturnType push$className() =>');
      buffer.writeln(
        '      FoundryNavigator.push(const ${className}Route(), context: this);',
      );
    }
    buffer.writeln('}');

    return buffer.toString();
  }

  String? _resolveArgsType(ConstantReader annotation) {
    final peek = annotation.peek('args');
    if (peek == null || peek.isNull) return null;
    final typeStr = peek.typeValue.getDisplayString(withNullability: false);
    return typeStr == 'dynamic' || typeStr == 'Null' ? null : typeStr;
  }

  String? _resolveResultType(ConstantReader annotation) {
    final ConstantReader? peek = annotation.peek('result');
    if (peek == null || peek.isNull) {
      return null;
    }
    final String typeStr = peek.typeValue.getDisplayString(
      withNullability: true,
    );
    return typeStr == 'dynamic' || typeStr == 'Null' ? null : typeStr;
  }

  String? _resolveDeepLinkArgsFactoryExpression(ConstantReader annotation) {
    final ConstantReader? factoryPeek = annotation.peek('deepLinkArgsFactory');
    if (factoryPeek == null || factoryPeek.isNull) {
      return null;
    }
    final DartObject value = factoryPeek.objectValue;
    final ExecutableElement? function = value.toFunctionValue();
    if (function == null) {
      return null;
    }
    final Element enclosing = function.enclosingElement;
    if (enclosing is ClassElement) {
      return '${enclosing.displayName}.${function.displayName}';
    }
    return function.displayName;
  }

  _ArgsConstructorShape? _resolveArgsConstructorShape(
    ConstantReader annotation,
  ) {
    final ConstantReader? argsPeek = annotation.peek('args');
    if (argsPeek == null || argsPeek.isNull) {
      return null;
    }

    final Element? argsElement = argsPeek.typeValue.element;
    if (argsElement is! InterfaceElement) {
      return null;
    }

    final ConstructorElement? constructor = _selectArgsConstructor(argsElement);
    if (constructor == null) {
      return null;
    }

    final List<_ArgsParameterInfo> params = constructor.parameters
        .map(_toArgsParamInfo)
        .toList();
    return _ArgsConstructorShape(parameters: params);
  }

  ConstructorElement? _selectArgsConstructor(InterfaceElement argsClass) {
    if (argsClass.constructors.isEmpty) {
      return null;
    }
    for (final ctor in argsClass.constructors) {
      if (ctor.name.isEmpty) {
        return ctor;
      }
    }
    return argsClass.constructors.first;
  }

  _ArgsParameterInfo _toArgsParamInfo(ParameterElement param) {
    final String typeName = param.type.getDisplayString(withNullability: false);
    final String fullType = param.type.getDisplayString(withNullability: true);
    return _ArgsParameterInfo(
      name: param.name,
      typeName: typeName,
      isNamed: param.isNamed,
      isNullable: fullType.endsWith('?'),
      defaultValueCode: param.defaultValueCode,
    );
  }
}

class _ArgsConstructorShape {
  const _ArgsConstructorShape({required this.parameters});

  final List<_ArgsParameterInfo> parameters;
}

class _ArgsParameterInfo {
  const _ArgsParameterInfo({
    required this.name,
    required this.typeName,
    required this.isNamed,
    required this.isNullable,
    required this.defaultValueCode,
  });

  final String name;
  final String typeName;
  final bool isNamed;
  final bool isNullable;
  final String? defaultValueCode;
}
