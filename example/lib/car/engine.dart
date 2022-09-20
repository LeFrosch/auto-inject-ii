import 'package:example/injection.dart';

abstract class Engine {
  String makeNoise();
}

@Injectable(as: Engine, env: [Env.fossil])
class DieselEngine implements Engine {
  @override
  String makeNoise() => 'Brum Brum';
}

@Injectable(as: Engine, env: [Env.electric])
class ElectricEngine implements Engine {
  @override
  String makeNoise() => 'Mhmmmmmmmm';
}
