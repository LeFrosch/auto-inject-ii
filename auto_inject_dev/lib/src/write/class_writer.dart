import 'package:code_builder/code_builder.dart';

import '../analyze/dependency.dart';
import '../context.dart';
import '../utils/auxiliary.dart';
import '../utils/type.dart';
import 'writer.dart';

class ClassWriter extends RegisterWriter {
  final List<Dependency> dependencies;
  final TargetType source;
  final TargetType target;

  final ProviderType type;

  ClassWriter({
    required this.dependencies,
    required this.source,
    required this.target,
    required this.type,
  });

  @override
  Expression? execute(Context context, Reference getItInstance, Reference moduleList) {
    if (dependencies.any((e) => e.assisted)) return null;

    final parameter = resolveDependencies(getItInstance, dependencies);
    final createInstance = source.reference.newInstance(parameter);

    return register(getItInstance, type, target.reference, createInstance);
  }
}
