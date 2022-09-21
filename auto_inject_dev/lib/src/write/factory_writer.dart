import 'package:code_builder/code_builder.dart';

import '../analyze/dependency.dart';
import '../analyze/provider/assisted_analyzer.dart';
import '../context.dart';
import '../utils/auxiliary.dart';
import '../utils/global.dart';
import 'writer.dart';

Iterable<Parameter> _assistedParameter(Iterable<Dependency> dependencies) {
  return dependencies.whereType<AssistedDependency>().map((e) => Parameter(
        (builder) => builder
          ..name = e.name
          ..type = e.target.reference,
      ));
}

Code _factoryMethodBody(Reference getItInstance, Reference moduleList, DependencyProvider? provider) {
  if (provider == null) {
    return refer('UnimplementedError').newInstance([literal('Not registered in this env')]).thrown.code;
  }

  final arguments = provider.dependencies.map((e) => resolveDependency(getItInstance, e));

  if (provider.module) {
    final moduleProvider = provider as ModuleDependencyProvider;

    return moduleList
        .index(refer(moduleProvider.moduleId.toString()))
        .property(moduleProvider.accessorName)
        .call(arguments)
        .code;
  } else {
    return provider.target.reference.newInstance(arguments).code;
  }
}

class GlobalFactoryWriter extends Writer {
  final AssistedDependencyProvider provider;

  GlobalFactoryWriter(this.provider);

  @override
  Spec? executeGlobal(Context context) {
    return Class((builder) {
      builder.name = factoryClassName;
      builder.abstract = true;

      for (final target in provider.assistedProviderTargets) {
        builder.methods.add(Method(
          (builder) => builder
            ..name = getFactoryMethodName(target)
            ..returns = target.reference
            ..requiredParameters.addAll(_assistedParameter(provider.getTargetAssistedDependencies(target))),
        ));
      }
    });
  }
}

class EnvFactoryWriter extends Writer {
  final AssistedDependencyProvider provider;
  final String env;

  EnvFactoryWriter(this.provider, this.env);

  @override
  Spec? executeGlobal(Context context) {
    return Class((builder) {
      final getItInstance = refer(getItParameterName);
      final moduleList = refer(modulesParameterName);

      builder.name = getEnvFactoryClassName(env);
      builder.extend = refer(factoryClassName);

      builder.fields.add(Field(
        (builder) => builder
          ..name = getItParameterName
          ..type = getItReference()
          ..modifier = FieldModifier.final$,
      ));

      builder.fields.add(Field(
        (builder) => builder
          ..name = modulesParameterName
          ..type = refer('List')
          ..modifier = FieldModifier.final$,
      ));

      builder.constructors.add(Constructor(
        (builder) => builder
          ..requiredParameters.add(Parameter(
            (builder) => builder
              ..name = getItParameterName
              ..toThis = true,
          ))
          ..requiredParameters.add(Parameter(
            (builder) => builder
              ..name = modulesParameterName
              ..toThis = true,
          )),
      ));

      for (final target in provider.assistedProviderTargets) {
        builder.methods.add(Method(
          (builder) => builder
            ..name = getFactoryMethodName(target)
            ..annotations.add(refer('override'))
            ..returns = target.reference
            ..requiredParameters.addAll(_assistedParameter(provider.getTargetAssistedDependencies(target)))
            ..body = _factoryMethodBody(getItInstance, moduleList, provider.getTargetProvider(target, env))
            ..lambda = true,
        ));
      }
    });
  }

  @override
  Expression? executeEnv(Context context, Reference getItInstance, Reference moduleList, String env) {
    if (env != this.env) return null;

    return getItInstance.property('registerSingleton').call(
      [
        refer(getEnvFactoryClassName(env)).newInstance([getItInstance, moduleList])
      ],
      {},
      [refer(factoryClassName)],
    );
  }
}
