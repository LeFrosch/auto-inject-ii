import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:source_gen/source_gen.dart';

import '../../context.dart';
import '../../exceptions.dart';
import '../../utils/auxiliary.dart';
import '../../write/module_writer.dart';
import '../dependency.dart';
import '../utils/annotation_analyzer.dart';
import '../utils/parameter_analyzer.dart';

class _ModuleVisitor extends SimpleElementVisitor<void> {
  final Context context;
  final int moduleId;

  final List<DependencyProvider> providers;

  _ModuleVisitor(this.context, this.moduleId) : providers = [];

  @override
  void visitMethodElement(MethodElement element) {
    final annotationReader = getInjectAnnotation(element);
    if (annotationReader == null) return;

    final annotation = analyzeAnnotation(context, element.returnType, annotationReader);
    final dependencies = analyzeParameter(context, element.parameters).toList();

    checkForAssistedDependencyMismatch(annotation, dependencies, element);

    final provider = ModuleDependencyProvider(
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

    providers.add(provider);
  }

  @override
  void visitPropertyAccessorElement(PropertyAccessorElement element) {
    final annotationReader = getInjectAnnotation(element);
    if (annotationReader == null) return;

    final annotation = analyzeAnnotation(context, element.returnType, annotationReader);

    final provider = ModuleDependencyProvider(
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

    providers.add(provider);
  }
}

List<DependencyProvider> analyzeModule(Context context, AnnotatedElement annotatedElement) {
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

  final moduleId = context.getNewModuleId();

  final visitor = _ModuleVisitor(context, moduleId);
  classElement.visitChildren(visitor);

  final extern = annotatedElement.annotation.read('extern').boolValue;
  context.registerWriter(ModuleClassWriter(
    extern: extern,
    moduleId: moduleId,
    source: context.resolveDartType(classElement.thisType),
  ));

  return visitor.providers;
}
