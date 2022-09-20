import 'package:code_builder/code_builder.dart';

import 'type.dart';

Reference getItReference() => refer('GetIt', 'package:get_it/get_it.dart');

Reference groupProviderReference(TargetType target) => TypeReference(
      (builder) => builder
        ..symbol = 'GroupProvider'
        ..url = 'package:auto_inject/auto_inject.dart'
        ..types.add(target.reference),
    );

const initMethodName = 'initAutoInject';
const factoryClassName = 'AutoFactory';
const getItParameterName = 'getItInstance';
const modulesParameterName = 'modules';
const externModulesParameterName = 'externModules';
const retrieveExternModuleMethodName = '_retrieveExternModule';

String getModuleClassName(int id) => '_Module$id';

String getGroupProviderClassName(TargetType type, String env) => '_GroupProvider${type.symbol}$env';

String getFactoryMethodName(TargetType type) => 'get${type.codeFriendlyName}';

String getEnvFactoryClassName(String env) => '_$factoryClassName$env';
