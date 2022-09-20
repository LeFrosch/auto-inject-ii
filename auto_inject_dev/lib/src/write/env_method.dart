import 'package:code_builder/code_builder.dart';

import '../analyze/dependency.dart';
import '../context.dart';
import '../utils/global.dart';

String envMethodName(String env) => '_build$env';

Method envMethod(Context context, List<DependencyProvider> providers, String env) {
  return Method((builder) {
    final getItInstance = refer(getItParameterName);
    final moduleList = refer(modulesParameterName);

    builder.name = envMethodName(env);
    builder.returns = refer('void');

    // getIt parameter
    builder.requiredParameters.add(Parameter(
      (builder) => builder
        ..name = getItParameterName
        ..type = getItReference(),
    ));

    // modules parameter
    builder.requiredParameters.add(Parameter(
      (builder) => builder
        ..name = modulesParameterName
        ..type = refer('List'),
    ));

    final expressions = <Expression>[];

    for (final writer in context.writers) {
      final expression = writer.executeEnv(context, getItInstance, moduleList, env);
      if (expression != null) {
        expressions.add(expression);
      }
    }

    for (final provider in providers) {
      final expression = provider.writer.execute(context, getItInstance, moduleList);
      if (expression != null) {
        expressions.add(expression);
      }
    }

    builder.body = Block.of(expressions.map((e) => e.statement));
  });
}
