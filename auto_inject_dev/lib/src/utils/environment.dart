import 'package:collection/collection.dart';

import '../analyze/dependency.dart';
import 'type.dart';

List<String> getEnvironments(List<DependencyProvider> provider) {
  return provider.map((e) => e.env).flattened.toSet().toList();
}

Map<TargetType, List<TargetType>> resolveGroups(List<DependencyProvider> input, String env) {
  final groups = <TargetType, List<TargetType>>{};

  for (final provider in input) {
    if (!provider.env.contains(env)) continue;

    for (final group in provider.groups) {
      groups.putIfAbsent(group, () => []).add(provider.target);
    }
  }

  return groups;
}
