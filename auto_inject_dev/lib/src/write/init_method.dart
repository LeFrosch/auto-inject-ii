import 'package:code_builder/code_builder.dart';

import '../context.dart';
import '../utils/global.dart';
import 'env_method.dart';

String _envParameterName = 'environment';

Method initMethod(Context context, List<String> envs) {
  return Method((builder) {
    final getItInstance = refer(getItParameterName);
    final moduleList = refer(modulesParameterName);

    builder.name = initMethodName;
    builder.returns = refer('void');

    // getIt parameter
    builder.requiredParameters.add(Parameter(
      (builder) => builder
        ..name = getItParameterName
        ..type = getItReference(),
    ));

    // environment parameter
    builder.requiredParameters.add(Parameter(
      (builder) => builder
        ..name = _envParameterName
        ..type = refer('String')
        ..named = true,
    ));

    // extern modules parameter
    builder.optionalParameters.add(Parameter(
      (builder) => builder
        ..name = externModulesParameterName
        ..type = refer('List')
        ..named = true
        ..defaultTo = Code('const []'),
    ));

    final expressions = <Code>[];

    // create modules list
    expressions.add(declareFinal(modulesParameterName)
        .assign(refer('List<dynamic>').newInstanceNamed(
          'filled',
          [literal(context.moduleCount), literalNull],
        ))
        .statement);

    // fill modules list
    for (final writer in context.writers) {
      final expression = writer.executeInit(context, getItInstance, moduleList);
      if (expression != null) {
        expressions.add(expression.statement);
      }
    }

    // build env switch statement
    expressions.add(Code('switch ($_envParameterName) {'));

    for (final env in envs) {
      final callEnvMethod = refer(envMethodName(env)).call([getItInstance, moduleList]);

      expressions.add(Code("case '$env':"));
      expressions.add(callEnvMethod.statement);
      expressions.add(Code('break;'));
    }

    expressions.add(Code('default:'));
    expressions.add(Code("assert(false, 'Unknown environment \\'\$$_envParameterName\\'');"));
    expressions.add(Code('break;'));

    expressions.add(Code('}'));

    builder.body = Block.of(expressions);
  });
}
