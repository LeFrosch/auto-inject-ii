import '../injection.dart';
import 'engine.dart';
import 'tire.dart';

@Injectable(env: Env.all)
class Car {
  final Engine engine;
  final Tire tire;

  Car(this.engine, this.tire);
}
