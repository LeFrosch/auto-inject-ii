import 'package:example/car/car.dart';
import 'package:example/injection.dart';

void main(List<String> arguments) {
  initDependencies(Env.electric);

  final car = locator<Car>();

  print('Car goes: ${car.engine.makeNoise()}');
}
