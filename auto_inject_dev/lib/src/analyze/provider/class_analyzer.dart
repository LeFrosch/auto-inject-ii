import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

import '../../context.dart';
import '../../exceptions.dart';
import '../../utils/auxiliary.dart';
import '../../write/class_writer.dart';
import '../dependency.dart';
import '../utils/annotation_analyzer.dart';
import '../utils/parameter_analyzer.dart';

Future<DependencyProvider> analyzeClass(Context context, AnnotatedElement annotatedElement) async {
  final classElement = annotatedElement.element;
  if (classElement is! ClassElement) {
    throw InputException('Injectable annotation not used on a class', cause: classElement);
  }
  if (classElement.isAbstract) {
    throw InputException(
      'Annotated class is abstract',
      fix: 'Only annotate classes which can be instantiated',
      cause: classElement,
    );
  }

  final constructor = classElement.unnamedConstructor;
  if (constructor == null) {
    throw InputException(
      'Annotated class has no unnamed constructor',
      fix: 'Create an unnamed constructor that can be used to instantiated this class',
      cause: classElement,
    );
  }

  final annotation = analyzeAnnotation(context, classElement.thisType, annotatedElement.annotation);
  final dependencies = await analyzeParameter(context, constructor.parameters).toList();

  checkForAssistedDependencyMismatch(annotation, dependencies, classElement);

  return DependencyProvider(
    target: annotation.target,
    env: annotation.env,
    dependencies: dependencies,
    groups: annotation.group,
    writer: ClassWriter(
      dependencies: dependencies,
      source: context.resolveDartType(classElement.thisType),
      target: annotation.target,
      type: annotation.type,
    ),
  );
}
