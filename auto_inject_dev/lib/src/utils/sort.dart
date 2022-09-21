import '../analyze/dependency.dart';
import '../exceptions.dart';
import 'environment.dart';
import 'type.dart';

class _Dependency {
  final TargetType? type;

  _Dependency(this.type);

  bool get assisted => type == null;

  bool satisfiesDependency(TargetType type) => type == this.type;
}

List<DependencyProvider> sort(List<DependencyProvider> input, String env) {
  final groups = resolveGroups(input, env);

  final dependencies = <DependencyProvider, List<_Dependency>>{};
  for (final provider in input) {
    if (!provider.env.contains(env)) continue;

    final providerDependencies = <_Dependency>[];

    for (final dependency in provider.dependencies) {
      if (dependency.factory) {
        continue;
      } else if (dependency.assisted) {
        providerDependencies.add(_Dependency(null));
      } else if (dependency.group) {
        final group = groups[dependency.target];

        if (group != null) {
          providerDependencies.addAll(group.map((e) => _Dependency(e)));
        }
      } else {
        providerDependencies.add(_Dependency(dependency.target));
      }
    }

    dependencies[provider] = providerDependencies;
  }

  final result = <DependencyProvider>[];
  bool changes = true;

  // Try to sort all dependencies
  while (changes) {
    changes = false;

    dependencies.removeWhere((provider, dependencies) {
      dependencies.removeWhere(
        (dependency) => result.any(
          (provider) {
            if (dependency.satisfiesDependency(provider.target)) {
              changes = true;
              return true;
            } else {
              return false;
            }
          },
        ),
      );

      if (dependencies.isEmpty) {
        result.add(provider);

        changes = true;
        return true;
      } else {
        return false;
      }
    });
  }

  // Remove all assisted dependencies, because the can not be resolved
  // automatically
  dependencies.removeWhere((provider, dependencies) {
    dependencies.removeWhere((e) => e.assisted);

    if (dependencies.isEmpty) {
      result.add(provider);
      return true;
    } else {
      return false;
    }
  });

  // If there are any unresolved dependencies left, there either is a circle in
  // the dependency tree or on dependency depends on a assisted source
  if (dependencies.isNotEmpty) {
    throw InputException(
      'Could not sort dependencies',
      fix: 'Make sure all dependencies can be satisfied',
    );
  }

  return result;
}
