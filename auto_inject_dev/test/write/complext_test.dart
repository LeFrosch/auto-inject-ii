import 'package:test/test.dart';

import '../compile.dart';
import '../matcher/matcher.dart';

void main() {
  test('factory with different providers', () async {
    final files = {
      'testA.dart': '''
        @Injectable(env: ['1'])
        class A {
          final String test;

          A(@assisted this.test);
        }
      ''',
      'testB.dart': '''
        class B {}
      ''',
      'module.dart': '''
        @module
        abstract class Module {
          @Injectable(env: ['2'])
          A a(@assisted String test) => A();

          @Singleton(env: ['1', '2'])
          B b() => B();
        }
      ''',
    };

    final result = await executeBuilder(files: files);
    expect(
      result,
      outputContains([
        'abstract class AutoFactory { _i2.A getA(String test); }',
        'class _AutoFactory1 extends AutoFactory',
        '_i2.A getA(String test) => _i2.A(test)',
        'class _AutoFactory2 extends AutoFactory',
        '_i2.A getA(String test) => modules[0].a(test)',
      ]),
    );
  });

  test('inject AutoFactory', () async {
    final files = {
      'testA.dart': '''
        @Injectable(env: ['env1', 'env2'])
        class A {
          final String test;

          A(@assisted this.test);
        }
      ''',
      'testB.dart': '''
        @Singleton(env: ['env1'])
        class B {
          final AutoFactory _factory;

          B(this._factory)
        }
      ''',
      'testC.dart': '''
        @Singleton(env: ['env1'])
        class C {
          final AutoFactory factory;

          C(this.factory)
        }
      ''',
      'module.dart': '''
        @module
        abstract class Module {
          @Singleton(env: ['env2'])
          B b(AutoFactory factory) => B(factory);
        }
      ''',
    };

    final result = await executeBuilder(files: files);
    expect(
      result,
      outputContains([
        'abstract class AutoFactory { _i2.A getA(String test); }',
        'class _AutoFactoryenv1 extends AutoFactory',
        'class _AutoFactoryenv2 extends AutoFactory',
        '_i2.A getA(String test) => _i2.A(test);',
        'getItInstance.registerSingleton<_i4.B>(_i4.B(getItInstance<AutoFactory>()));',
        'getItInstance.registerSingleton<_i4.B>(modules[0].b(getItInstance<AutoFactory>()));',
      ]),
    );
  });

  test('extern modules', () async {
    final files = {
      'testA.dart': '''
        class A { }
      ''',
      'testB.dart': '''
        class B { }
      ''',
      'module.dart': '''
        @externModule
        abstract class Module {
          @Injectable(env: ['test'])
          A a(@assisted String test);

          @Singleton(env: ['test'])
          B b();
        }
      ''',
    };

    final result = await executeBuilder(files: files);
    expect(
      result,
      outputContains([
        'class _AutoFactorytest extends AutoFactory ',
        '_i1.A getA(String test) => modules[0].a(test);',
        'getItInstance.registerSingleton<AutoFactory>(_AutoFactorytest(getItInstance, modules, ));',
        'getItInstance.registerSingleton<_i3.B>(modules[0].b());',
        'modules[0] = _retrieveExternModule<_i4.Module>(externModules);',
      ]),
    );
  });

  test('factory with injection', () async {
    final files = {
      'testA.dart': '''
        @Singleton(env: ['test'])
        class A {}
      ''',
      'testB.dart': '''
        @Injectable(env: ['test'])
        class B {
          final A a;
          final String test;

          B(this.a, @assisted this.test);
        }
      ''',
    };

    final result = await executeBuilder(files: files);
    expect(
      result,
      outputContains([
        'abstract class AutoFactory { _i1.B getB(String test); }',
        '_i1.B getB(String test) => _i1.B( getItInstance<_i3.A>(), test, );',
      ]),
    );
  });

  test('all features', () async {
    final files = {
      'testG.dart': '''
        abstract class G {}
      ''',
      'testA.dart': '''
        @Singleton(env: ['env1', 'env2'], group: [G])
        class A implements G {}
      ''',
      'testB.dart': '''
        @Singleton(env: ['env1'], group: [G], lazy: true)
        class B implements G {
          final A a;

          B(this.a);
        }
      ''',
      'module.dart': '''
        class M1 {}
        class M2 {}

        @module
        abstract class Module {
          @Injectable(env: ['env1'])
          M1 get m1 => M1();

          @Injectable(env: ['env1'])
          M2 m2(M1 m1, @group Iterable<G> g, @assisted int test) => M2();
        }
      ''',
      'extern_module.dart': '''
        class EM1 {}
        class EM2 {}

        @externModule
        abstract class ExternModule {
          @Injectable(env: ['env1', 'env2'])
          EM1 get m1;

          @Injectable(env: ['env1'])
          EM2 m2(EM1 m1);
        }
      ''',
    };

    await executeBuilder(files: files);
  });
}
