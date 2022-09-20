import 'package:code_builder/code_builder.dart';

import '../analyze/dependency.dart';
import '../context.dart';
import '../utils/auxiliary.dart';
import '../utils/global.dart';
import '../utils/type.dart';
import 'writer.dart';

class ModuleWriter extends RegisterWriter {
  final List<Dependency> dependencies;
  final int moduleId;
  final TargetType target;
  final String methodName;

  final ProviderType type;

  ModuleWriter({
    required this.dependencies,
    required this.moduleId,
    required this.target,
    required this.type,
    required this.methodName,
  });

  @override
  Expression? execute(Context context, Reference getItInstance, Reference moduleList) {
    if (dependencies.any((e) => e.assisted)) return null;

    final parameter = resolveDependencies(getItInstance, dependencies);
    final createInstance = moduleList.index(literal(moduleId)).property(methodName).call(parameter);

    return register(getItInstance, type, target.reference, createInstance);
  }
}

class ModulePropertyWriter extends RegisterWriter {
  final int moduleId;
  final TargetType target;
  final String propertyName;

  final ProviderType type;

  ModulePropertyWriter({
    required this.moduleId,
    required this.target,
    required this.type,
    required this.propertyName,
  });

  @override
  Expression execute(Context context, Reference getItInstance, Reference moduleList) {
    final createInstance = moduleList.index(literal(moduleId)).property(propertyName);

    return register(getItInstance, type, target.reference, createInstance);
  }
}

class ModuleHelperWriter extends Writer {
  @override
  Spec? executeGlobal(Context context) {
    return Method((builder) {
      builder.name = retrieveExternModuleMethodName;
      builder.returns = refer('T?');
      builder.types.add(refer('T'));

      builder.requiredParameters.add(Parameter(
        (builder) => builder
          ..name = externModulesParameterName
          ..type = refer('List'),
      ));

      builder.body = Code('''
        for (final module in $externModulesParameterName) {
          if (module is T) {
            return module;
          }
        }

        return null;
        ''');
    });
  }
}

class ModuleClassWriter extends Writer {
  final bool extern;
  final int moduleId;
  final TargetType source;

  ModuleClassWriter({
    required this.moduleId,
    required this.source,
    required this.extern,
  });

  @override
  Spec? executeGlobal(Context context) {
    if (extern) return null;

    return Class(
      (builder) => builder
        ..name = getModuleClassName(moduleId)
        ..extend = source.reference,
    );
  }

  @override
  Expression? executeInit(Context context, Reference getItInstance, Reference moduleList) {
    if (extern) {
      return moduleList
          .index(literal(moduleId))
          .assign(refer(retrieveExternModuleMethodName).call([moduleList], {}, [source.reference]));
    } else {
      return moduleList.index(literal(moduleId)).assign(refer(getModuleClassName(moduleId)).newInstance([]));
    }
  }
}
