# Auto Inject 
Code generation library for automatic dependency injection with GetIt, to reduce boilerplate code to a minimum. My target was not to support every feature get it provides, but to make the use of the most common feature more ergonomic and to provide some extra features i personally find useful.
## Setup
1. Add the required dependencies: 
```yaml
dependencies:
  # GetIt itself
  get_it: any
  
  # The annotation library
  auto_inject: any

dev_dependencies:
  # Build runner to execute the code generator
  build_runner: any
  
  # The code generator
  auto_inject_dev: any
```
2. Enable the code generator and point it to one entry file. The content of the file is not important and all dart files in your project will be analyzed anyway. Add the following to the `build.yaml` file:
```yaml
targets:
  $default:
    builders:
      auto_inject_dev|auto_inject_builder:
        enabled: true
        generate_for: 
          - lib/injection.dart 
```
3. Call the generated `initAutoInject` method to configure a GetIt instance. For example:
```dart
import 'file.auto.dart';

void main() {
    final instance = GetIt.instance;
    final environment = 'dev';

    // Call the init method to configure the GetIt instance 
    initAutoInject(instance, environment);

    // Now the instance is ready to be used
    final obj = instance<SomeClass>();
}
```
## Features
### Basic injection
There are three ways a dependency can be registered:
- Injectable (annotated with `@Injectable()`): Every time a new instance of this class is request a new instance will be created
- Singleton (annotated with `@Singleton()`): The instance of the class will be created when the init method is called and every time an instance of this class is requested, this exact instance will be provided
- Lazy singleton (annotated with `@Singleton(lazy: true)`): Like a normal singleton, but the instance will be created the first time an instance of this class is requested

Every class that should be registered with the GetIt instance needs to be annotated with on of the two annotations. Dependency can be automatically injected into the constructor of another class like:
```dart
@Singleton(env: 'env1')
class A {}

@Singleton(env: 'env1')
class B { 
  final A a;
  
  B(this.a)
}
```
Or manually retrieved using a reference to the GetIt instance:
```dart
final b = GetIt.instance<B>();
```
### Environments
Dependencies can be registered in one or multiple environments. When the init method is called only classes that are in the specified environment will be registered. This is useful when a class has different implementations in different environments. For example:
```dart
class Flower { }

@Injectable(as: Flower, env: ['yellow'])
class YellowFlower implements Flower { }

@Injectable(as: Flower, env: ['red'])
class RedFlower implements Flower { }

@Injectable(env: ['yellow', 'red'])
class FlowerPot {
  final Flower flower;

  FlowerPot(this.flower);
}
```
If an instance of FlowerPot is request in the yellow environment a YellowFlower will be passed into the constructor and a red one in the red environment. 
### Modules
If it is not possible to add an annotation to the class that should be injected a module can be created instead. This could be the case when the class is provided by a third party dependency. Modules are abstract classes annotated with `@module`. Methods or properties of a module can be annotated and the return type will then be registered with the GetIt instance. It is also possible to automatically inject other dependencies into the method of a module. For example:
```dart
@module
abstract class Module {
  // Provides dependency A
  @Injectable(env: ['env1'])
  A get a => A();
  
  // Provides dependency B and an instance of A will be injected automatically
  @Injectable(env: ['env1'])
  B b(A a) => B(a);
}
```
### Groups
It is also possible to register multiple classes in a group. If a group is request an instance of every dependency in this group will be provided. Every class that is registered in a group must also implement the group type. For example:
```dart
class G { }

@Injectable(env: ['env1'], group: [G])
class A implements G { }

@Singleton(env: ['env1'], group: [G])
class B implements G { }
```
An instance of this group can be automatically injected by annotating the constructor parameter or the module function parameter with `@group`. Group parameter must be either a List or an Iterable.
```dart
@Injectable(env: ['env1'])
class C {
  final List<G> g;
  
  C(@group this.g);
}
```
If the group is empty an empty list will be injected.
### Assisted injection
Sometimes a value or dependency needs to be provided manually. Therefore it is possible to annotate constructor parameter or the module function parameter with `@assisted`. But assisted injection can only be used with `@Injectable` and it is not possible to automatically inject these dependencies into other dependencies. For every assisted dependency a function will be generated on the `AutoFactory`. An instance of this factory can be used to create an instance of assisted dependencies. For example:
```dart
@Injectable(env: ['env1'])
class A { 
  final String info;
  
  A(@assisted this.info)
}

@Injectable(env: ['env1'])
class B {
  final A a;
  
  B(AutoFactory factory) : factory.getB('Additional information');
}
```
# Extern modules
To make modules more flexible it is possible to create extern modules. Extern modules are abstract class annotated with `@externModule`. Unlike normal modules they do not provide implementations for the dependencies they provide. An instance that provides these implementations can be passed into the init method. This is useful during testing when mocks should be injected into the test environment. For example:
```dart
@Singleton(env: ['prod'])
class A { }

@externModule
abstract class Module {
  @Singleton(env: ['test'])
  A get a;
}

class TestModule implements Module {
  @override
  A get a => MockA();
}

void main() {
  initAutoInject(GetIt.instance, 'test', externModules: [TestModule()]);
}
```
