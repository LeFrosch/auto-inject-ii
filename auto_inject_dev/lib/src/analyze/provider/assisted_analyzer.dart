import 'package:collection/collection.dart';

import '../../context.dart';
import '../../exceptions.dart';
import '../../utils/environment.dart';
import '../../utils/type.dart';
import '../../write/factory_writer.dart';
import '../dependency.dart';

class AssistedDependencyProvider {
  final Map<TargetType, Map<String, DependencyProvider>> targetMap;

  AssistedDependencyProvider(this.targetMap);

  Iterable<TargetType> get assistedProviderTargets => targetMap.keys;

  DependencyProvider? getTargetProvider(TargetType type, String env) => targetMap[type]?[env];

  Iterable<AssistedDependency> getTargetAssistedDependencies(TargetType type) =>
      targetMap[type]!.values.first.dependencies.whereType<AssistedDependency>();
}

void analyzeAssisted(Context context, List<DependencyProvider> providers) {
  final equality = DeepCollectionEquality();

  final assistedTypes = providers.where((e) => e.dependencies.any((e) => e.assisted)).map((e) => e.target).toSet();
  final targetMap = <TargetType, Map<String, DependencyProvider>>{};

  for (final type in assistedTypes) {
    final typeMap = <String, DependencyProvider>{};
    final typeProvider = providers.where((e) => e.target == type).toList();

    final typeAssistedDependencies = typeProvider.first.dependencies.whereType<AssistedDependency>().toList();
    assert(typeAssistedDependencies.isNotEmpty);

    for (final provider in typeProvider) {
      if (!equality.equals(typeAssistedDependencies, provider.dependencies.whereType<AssistedDependency>().toList())) {
        throw InputException(
          'Type is registered in multiple environments with different assisted fields',
          fix: 'Make sure that one type as the same assisted fields in all environments',
        );
      }

      for (final env in provider.env) {
        typeMap[env] = provider;
      }
    }

    targetMap[type] = typeMap;
  }

  final assistedProvider = AssistedDependencyProvider(targetMap);

  context.registerWriter(GlobalFactoryWriter(assistedProvider));

  for (final env in getEnvironments(providers)) {
    context.registerWriter(EnvFactoryWriter(assistedProvider, env));
  }
}
