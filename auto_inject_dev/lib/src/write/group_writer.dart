import 'package:code_builder/code_builder.dart';

import '../context.dart';
import '../utils/global.dart';
import '../utils/type.dart';
import 'writer.dart';

class GroupWriter extends Writer {
  final TargetType target;
  final List<TargetType> sources;
  final String env;

  GroupWriter({
    required this.target,
    required this.sources,
    required this.env,
  });

  String get thisProviderClassName => getGroupProviderClassName(target, env);

  Reference get thisProviderReference => refer(thisProviderClassName);

  Reference extendedProviderReference(Context context) => groupProviderReference(target);

  @override
  Spec? executeGlobal(Context context) {
    final code = <Code>[];
    code.add(Code('['));

    for (final source in sources) {
      code.add(refer(getItParameterName).call([], {}, [source.reference]).code);
      code.add(Code(','));
    }

    code.add(Code(']'));

    return Class((builder) {
      builder.name = thisProviderClassName;
      builder.extend = extendedProviderReference(context);

      builder.fields.add(Field(
        (builder) => builder
          ..name = getItParameterName
          ..type = getItReference()
          ..modifier = FieldModifier.final$,
      ));

      builder.constructors.add(Constructor(
        (builder) => builder.requiredParameters.add(Parameter(
          (builder) => builder
            ..name = getItParameterName
            ..toThis = true,
        )),
      ));

      builder.methods.add(Method(
        (builder) => builder
          ..name = 'call'
          ..annotations.add(refer('override'))
          ..returns = TypeReference(
            (builder) => builder
              ..symbol = 'Iterable'
              ..types.add(target.reference),
          )
          ..body = Block.of(code)
          ..lambda = true,
      ));
    });
  }

  @override
  Expression? executeEnv(Context context, Reference getItInstance, Reference moduleList, String env) {
    if (env != this.env) return null;

    return getItInstance.property('registerSingleton').call(
      [
        thisProviderReference.newInstance([getItInstance])
      ],
      {},
      [extendedProviderReference(context)],
    );
  }
}
