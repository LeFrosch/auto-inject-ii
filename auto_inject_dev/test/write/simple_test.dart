import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../compile.dart';
import '../matcher/matcher.dart';

void main() {
  test('multiple class files', () async {
    final files = {
      'testA.dart': '''
        @Injectable(env: ['test'])
        class A {}
      ''',
      'testB.dart': '''
        @Singleton(env: ['test'])
        class B {
          final A a;
          B(this.a);
        }
      ''',
      'testC.dart': '''
        @Singleton(env: ['test'], lazy: true)
        class C {
          final B b;
          final A a

          C(this.b, this.a);
        }
      '''
    };

    final result = await executeBuilder(files: files);
    expect(
      result,
      outputContains([
        'getItInstance.registerFactory<_i2.A>(() => _i2.A());',
        'getItInstance.registerSingleton<_i3.B>(_i3.B(getItInstance<_i2.A>()));',
        'getItInstance.registerLazySingleton<_i4.C>(() => _i4.C(getItInstance<_i3.B>(), getItInstance<_i2.A>(),));'
      ]),
    );
  });

  test('one module', () async {
    final files = {
      'testA.dart': '''
        class A {}
        class B {}
        class C {}
      ''',
      'module.dart': '''
        @module
        abstract class Module {
          @Singleton(env: ['test'])
          A get a => A();

          @Injectable(env: ['test'])
          B get b => B();

          @Injectable(env: ['test'])
          C c(A a, B b) => C();
        }
      ''',
    };

    final result = await executeBuilder(files: files);
    expect(
      result,
      outputContains([
        'class _Module0 extends _i1.Module {}',
        'getItInstance.registerSingleton<_i3.A>(modules[0].a);',
        'getItInstance.registerFactory<_i3.B>(() => modules[0].b);',
        'getItInstance.registerFactory<_i3.C>(() => modules[0].c(getItInstance<_i3.A>(), getItInstance<_i3.B>(),));',
        'modules[0] = _Module0();',
      ]),
    );
  });

  test('one group', () async {
    final files = {
      'testA.dart': '''
        class G {}

        class A implements G {}
        class B {}
        class C implements G {}
      ''',
      'module.dart': '''
        @module
        abstract class Module {
          @Singleton(env: ['test'], group: [G])
          A get a => A();

          @Injectable(env: ['test'])
          B b(@group List<G> g) => B();

          @Injectable(env: ['test'], group: [G])
          C c(A a) => C();
        }
      ''',
    };

    final result = await executeBuilder(files: files);
    expect(
      result,
      outputContains([
        'class _GroupProviderGtest extends _i2.GroupProvider<_i3.G>',
        '_GroupProviderGtest(this.getItInstance)',
        'Iterable<_i3.G> call() => [getItInstance<_i3.A>(), getItInstance<_i3.C>(), ];',
        'getItInstance.registerSingleton<_i2.GroupProvider<_i3.G>>(_GroupProviderGtest(getItInstance));',
        'getItInstance.registerFactory<_i3.B>(() => modules[0].b(getItInstance<_i2.GroupProvider<_i3.G>>().call().toList()));',
      ]),
    );
  });

  test('simple factory', () async {
    final files = {
      'testA.dart': '''
        class A {}
      ''',
      'module.dart': '''
        @module
        abstract class Module {
          @Injectable(env: ['1'])
          A a(@assisted String test) => A();

          @Injectable(env: ['2'])
          A a(@assisted String test) => A();
        }
      ''',
    };

    final result = await executeBuilder(files: files);
    expect(
      result,
      outputContains([
        'abstract class AutoFactory { _i2.A getA(String test); }',
        'class _AutoFactory1 extends AutoFactory',
        '_i2.A getA(String test) => modules[0].a(test);',
        'class _AutoFactory2 extends AutoFactory',
        'getItInstance.registerSingleton<AutoFactory>(_AutoFactory1(getItInstance, modules, ));',
        'getItInstance.registerSingleton<AutoFactory>(_AutoFactory2(getItInstance, modules, ));',
      ]),
    );
  });
}
