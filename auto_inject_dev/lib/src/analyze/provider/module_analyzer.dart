import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

import '../../context.dart';
import '../../exceptions.dart';
import '../../utils/auxiliary.dart';
import '../../write/module_writer.dart';
import '../dependency.dart';
import '../utils/annotation_analyzer.dart';
import '../utils/parameter_analyzer.dart';

@override
Future<DependencyProvider?> _visitMethod(Context context, int moduleId, MethodElement element) async {
  final annotationReader = getInjectAnnotation(element);
  if (annotationReader == null) return null;

  final annotation = analyzeAnnotation(context, element.returnType, annotationReader);
  final dependencies = await analyzeParameter(context, element.parameters).toList();

  checkForAssistedDependencyMismatch(annotation, dependencies, element);

  return ModuleDependencyProvider(
    target: annotation.target,
    env: annotation.env,
    dependencies: dependencies,
    groups: annotation.group,
    moduleId: moduleId,
    accessorName: element.name,
    writer: ModuleWriter(
      dependencies: dependencies,
      methodName: element.name,
      moduleId: moduleId,
      target: annotation.target,
      type: annotation.type,
    ),
  );
}

@override
Future<DependencyProvider?> _visitProperty(Context context, int moduleId, PropertyAccessorElement element) async {
  final annotationReader = getInjectAnnotation(element);
  if (annotationReader == null) return null;

  final annotation = analyzeAnnotation(context, element.returnType, annotationReader);

  return ModuleDependencyProvider(
    target: annotation.target,
    env: annotation.env,
    dependencies: [],
    groups: annotation.group,
    moduleId: moduleId,
    accessorName: element.name,
    writer: ModulePropertyWriter(
      propertyName: element.name,
      moduleId: moduleId,
      target: annotation.target,
      type: annotation.type,
    ),
  );
}

Future<List<DependencyProvider>> analyzeModule(Context context, AnnotatedElement annotatedElement) async {
  final classElement = annotatedElement.element;
  if (classElement is! ClassElement) {
    throw InputException('Module annotation not used on a class', cause: classElement);
  }
  if (!classElement.isAbstract) {
    throw InputException(
      'Module class is not abstract',
      fix: 'Make the module class abstract',
      cause: classElement,
    );
  }

  final constructor = classElement.unnamedConstructor;
  if (constructor == null || constructor.parameters.isNotEmpty) {
    throw InputException(
      'Module class does not have a valid constructor',
      fix: 'Provide a default constructor with no arguments for the module class',
      cause: classElement,
    );
  }

  final id = context.getNewModuleId();

  final methods = classElement.methods.map((e) => _visitMethod(context, id, e));
  final properties = classElement.fields.map((e) => e.getter).whereNotNull().map((e) => _visitProperty(context, id, e));
  final providers = (await Future.wait(methods.followedBy(properties))).whereNotNull().toList();

  final extern = annotatedElement.annotation.read('extern').boolValue;
  context.registerWriter(ModuleClassWriter(
    extern: extern,
    moduleId: id,
    source: context.resolveDartType(classElement.thisType),
  ));

  return providers;
}
