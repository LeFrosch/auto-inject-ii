import 'package:auto_inject_dev/src/analyze/provider/module_analyzer.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import '../compile.dart';
import '../matcher/matcher.dart';

void main() {
  test('analyze a module', () async {
    final result = await compile('''
    class A {}
    class B {}

    @module
    abstract class Foo {
      @Singleton(env: ['test'])
      A get getA => A();

      @Injectable(env: ['test'])
      B getB(A a) => B();

      String get somethingElse => 'nothing';
    }
    ''');

    final classElement = result.library.getClass('Foo')!;
    final reader = ConstantReader(classElement.metadata.first.computeConstantValue());

    final providers = analyzeModule(result.context, AnnotatedElement(reader, classElement));

    expect(providers, hasLength(2));

    final providerA = providers[0];
    final providerB = providers[1];

    expect(providerA.dependencies, isEmpty);
    expect(providerA.env, equals(['test']));
    expect(providerA.target, isDartType('A'));

    expect(providerB.dependencies, equals([isDependency('A')]));
    expect(providerB.env, equals(['test']));
    expect(providerB.target, isDartType('B'));
  });
}
