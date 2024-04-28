import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:auto_inject/auto_inject.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

import '../../context.dart';
import '../../exceptions.dart';
import '../../utils/global.dart';
import '../dependency.dart';

final _assistedTypeChecker = TypeChecker.fromRuntime(AssistedField);
final _groupTypeChecker = TypeChecker.fromRuntime(GroupField);

final _listTypeChecker = TypeChecker.fromRuntime(List);
final _iterableTypeChecker = TypeChecker.fromRuntime(Iterable);

Future<Dependency?> _resolveDynamicType(Context context, ParameterElement parameter) async {
  final ast = await context.resolver.astNodeFor(parameter);
  if (ast == null) return null;

  final TypeAnnotation? type;
  if (ast is FieldFormalParameter) {
    final enclosingClass = ast.thisOrAncestorOfType<ClassDeclaration>();
    if (enclosingClass == null) return null;

    type = enclosingClass.members
        .whereType<FieldDeclaration>()
        .map((e) => e.fields)
        .where((e) => e.variables.any((e) => e.name.toString() == parameter.name))
        .map((e) => e.type)
        .firstOrNull;
  } else if (ast is SimpleFormalParameter) {
    type = ast.type;
  } else {
    throw UnexpectedException('Unknown parameter type: ${ast.runtimeType}');
  }
  if (type is! NamedType) return null;

  final name = type.name2.toString();

  if (name == factoryClassName) {
    return FactoryDependency();
  }

  return null;
}

Stream<Dependency> analyzeParameter(Context context, List<ParameterElement> parameters) async* {
  for (final parameter in parameters) {
    if (parameter.isNamed) {
      throw InputException(
        'Named parameters are not supported',
        fix: 'Turn named parameter into unnamed',
        cause: parameter,
      );
    }
    if (parameter.isOptional) {
      throw InputException(
        'Optional parameters are not supported',
        fix: 'Remove optional parameter or make it required',
        cause: parameter,
      );
    }

    if (_groupTypeChecker.hasAnnotationOfExact(parameter)) {
      final type = parameter.type;

      if (type is! ParameterizedType) {
        throw InputException(
          'Group parameter has no generic type',
          fix: 'Add an explicit generic type',
          cause: parameter,
        );
      }
      if (!_listTypeChecker.isAssignableFromType(type) && !_iterableTypeChecker.isAssignableFromType(type)) {
        throw InputException(
          'Group parameter is not assignable to List or Iterable',
          fix: 'Only use Iterable or List can be used to inject a group',
          cause: parameter,
        );
      }
      if (type.typeArguments.length != 1) {
        throw InputException(
          'Could not determine group type',
          fix: 'Use exactly one explicit generic type for the List or Iterable',
          cause: parameter,
        );
      }

      yield GroupDependency(
        context.resolveDartType(type.typeArguments[0]),
        list: _listTypeChecker.isAssignableFromType(type),
      );
    } else if (_assistedTypeChecker.hasAnnotationOfExact(parameter)) {
      yield AssistedDependency(
        context.resolveDartType(parameter.type),
        name: parameter.name,
      );
    } else {
      if (parameter.type is DynamicType || parameter.type is InvalidType) {
        final dependency = await _resolveDynamicType(context, parameter);

        if (dependency != null) {
          yield dependency;
        } else {
          throw InputException(
            'Could not resolve type',
            fix: 'Make sure the type is not dynamic or generated,'
                'because not all generated types are available when the code generator is running',
            cause: parameter,
          );
        }
      } else {
        yield Dependency(context.resolveDartType(parameter.type));
      }
    }
  }
}
