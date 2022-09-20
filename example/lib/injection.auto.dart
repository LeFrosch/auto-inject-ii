// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// Generator: Instance of 'LibraryGenerator'
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i1;
import 'package:example/car/engine.dart' as _i2;
import 'package:example/car/tire.dart' as _i3;
import 'package:example/car/car.dart' as _i4;

T? _retrieveExternModule<T>(List externModules) {
  for (final module in externModules) {
    if (module is T) {
      return module;
    }
  }

  return null;
}

abstract class AutoFactory {}

void _buildfossil(
  _i1.GetIt getItInstance,
  List modules,
) {
  getItInstance.registerFactory<_i2.Engine>(() => _i2.DieselEngine());
  getItInstance.registerFactory<_i3.Tire>(() => _i3.Tire());
  getItInstance.registerFactory<_i4.Car>(() => _i4.Car(
        getItInstance<_i2.Engine>(),
        getItInstance<_i3.Tire>(),
      ));
}

void _buildelectric(
  _i1.GetIt getItInstance,
  List modules,
) {
  getItInstance.registerFactory<_i2.Engine>(() => _i2.ElectricEngine());
  getItInstance.registerFactory<_i3.Tire>(() => _i3.Tire());
  getItInstance.registerFactory<_i4.Car>(() => _i4.Car(
        getItInstance<_i2.Engine>(),
        getItInstance<_i3.Tire>(),
      ));
}

void initAutoInject(
  _i1.GetIt getItInstance,
  String environment, {
  List externModules = const [],
}) {
  final modules = List<dynamic>.filled(
    0,
    null,
  );
  switch (environment) {
    case 'fossil':
      _buildfossil(
        getItInstance,
        modules,
      );
      break;
    case 'electric':
      _buildelectric(
        getItInstance,
        modules,
      );
      break;
    default:
      assert(false, 'Unknown environment \'$environment\'');
      break;
  }
}
