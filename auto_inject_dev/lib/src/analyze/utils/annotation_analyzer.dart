import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:auto_inject/auto_inject.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:source_gen/source_gen.dart';

import '../../context.dart';
import '../../exceptions.dart';
import '../../utils/type.dart';
import '../dependency.dart';

final _injectableTypeChecker = TypeChecker.fromRuntime(Injectable);
final _singletonTypeChecker = TypeChecker.fromRuntime(Singleton);

class InjectableAnnotation extends Equatable {
  final ProviderType type;

  final TargetType target;

  final List<TargetType> group;
  final List<String> env;

  // final Function? dispose;

  InjectableAnnotation({
    required this.type,
    required this.target,
    required this.group,
    required this.env,
  });

  @override
  List<Object?> get props => [type, target, group, env];
}

T? _readNullable<T>(ConstantReader reader, T Function(ConstantReader reader) read) {
  if (reader.isNull) return null;

  return read(reader);
}

ConstantReader? getInjectAnnotation(Element element) {
  final obj = _injectableTypeChecker.firstAnnotationOf(element, throwOnUnresolved: false);

  if (obj == null) {
    return null;
  } else {
    return ConstantReader(obj);
  }
}

InjectableAnnotation analyzeAnnotation(Context context, DartType target, ConstantReader reader) {
  final element = reader.objectValue.type!.element2;
  if (element == null) {
    throw UnexpectedException('Annotation element was null');
  }

  if (!_injectableTypeChecker.isAssignableFrom(element)) {
    throw UnexpectedException('Annotation does not derive from Injectable');
  }

  final as = _readNullable(reader.read('as'), (r) => r.typeValue);
  final annotationTarget = context.resolveDartType(as ?? target);
  final env = reader.read('env').listValue.map((e) => e.toStringValue()).whereNotNull().toList();

  final groups = reader
      .read('group')
      .listValue
      .map((e) => e.toTypeValue())
      .whereNotNull()
      .map((e) => context.resolveDartType(e))
      .toList();

  for (final group in groups) {
    if (!group.typeChecker.isAssignableFromType(target)) {
      throw InputException(
        'Target is part of group but is not assignable to group [$group]',
        fix: 'Make sure the target implements the group type',
        cause: element,
      );
    }
  }

  if (!_singletonTypeChecker.isAssignableFrom(element)) {
    return InjectableAnnotation(
      type: ProviderType.injectable,
      target: annotationTarget,
      group: groups,
      env: env,
    );
  } else {
    final lazy = reader.read('lazy').boolValue;

    return InjectableAnnotation(
      type: lazy ? ProviderType.lazySingleton : ProviderType.singleton,
      target: annotationTarget,
      group: groups,
      env: env,
    );
  }
}
