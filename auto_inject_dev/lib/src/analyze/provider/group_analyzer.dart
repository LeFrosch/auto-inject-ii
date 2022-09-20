import '../../context.dart';
import '../../utils/environment.dart';
import '../../write/group_writer.dart';
import '../dependency.dart';

void analyzeGroups(Context context, List<DependencyProvider> providers) {
  final envs = getEnvironments(providers);

  for (final env in envs) {
    final groups = resolveGroups(providers, env);

    for (final group in groups.entries) {
      context.registerWriter(GroupWriter(target: group.key, sources: group.value, env: env));
    }
  }
}
