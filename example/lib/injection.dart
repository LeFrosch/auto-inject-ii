import 'package:get_it/get_it.dart';

import 'injection.auto.dart';

export 'package:auto_inject/auto_inject.dart';

final locator = GetIt.instance;

abstract class Env {
  static const electric = 'electric';

  static const fossil = 'fossil';

  static const all = [electric, fossil];
}

void initDependencies(String env) => initAutoInject(locator, env);
