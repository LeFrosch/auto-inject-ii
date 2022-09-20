import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';

import '../analyze/dependency.dart';
import '../analyze/utils/annotation_analyzer.dart';
import '../exceptions.dart';
import 'global.dart';

void checkForAssistedDependencyMismatch(
  InjectableAnnotation annotation,
  List<Dependency> dependencies,
  Element? cause,
) {
  if (!dependencies.any((e) => e.assisted)) return;

  if (annotation.type != ProviderType.injectable) {
    throw InputException(
      'Only Injectables can use assisted fields',
      fix: 'Remove assisted fields or mark as Injectable instead of Singleton',
      cause: cause,
    );
  }
  if (annotation.group.isNotEmpty) {
    throw InputException(
      'Injectables with assited fields can not be used in groups',
      fix: 'Remove assisted fields or remove this Injectable from the group',
      cause: cause,
    );
  }
}

Iterable<Expression> resolveDependencies(Reference getItInstance, List<Dependency> dependencies) sync* {
  for (final dependency in dependencies) {
    yield resolveDependency(getItInstance, dependency);
  }
}

Expression resolveDependency(Reference getItInstance, Dependency dependency) {
  if (dependency.assisted) {
    final assistedDependency = dependency as AssistedDependency;

    return refer(assistedDependency.name);
  } else if (dependency.group) {
    final groupDependency = dependency as GroupDependency;
    final retrieve = getItInstance.call([], {}, [groupProviderReference(dependency.target)]).property('call').call([]);

    if (groupDependency.list) {
      return retrieve.property('toList').call([]);
    } else {
      return retrieve;
    }
  } else {
    return getItInstance.call([], {}, [dependency.target.reference]);
  }
}
