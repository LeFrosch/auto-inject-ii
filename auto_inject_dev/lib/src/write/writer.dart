import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';

import '../analyze/dependency.dart';
import '../context.dart';

abstract class Writer {
  Spec? executeGlobal(Context context) => null;

  Expression? executeInit(Context context, Reference getItInstance, Reference moduleList) => null;

  Expression? executeEnv(Context context, Reference getItInstance, Reference moduleList, String env) => null;
}

abstract class RegisterWriter {
  @protected
  Expression register(Reference getItInstance, ProviderType type, Reference target, Expression createInstance) {
    switch (type) {
      case ProviderType.injectable:
        return getItInstance
            .property('registerFactory')
            .call([Method((b) => b..body = createInstance.code).closure], {}, [target]);
      case ProviderType.singleton:
        return getItInstance.property('registerSingleton').call([createInstance], {}, [target]);
      case ProviderType.lazySingleton:
        return getItInstance
            .property('registerLazySingleton')
            .call([Method((b) => b..body = createInstance.code).closure], {}, [target]);
    }
  }

  Expression? execute(Context context, Reference getItInstance, Reference moduleList);
}
