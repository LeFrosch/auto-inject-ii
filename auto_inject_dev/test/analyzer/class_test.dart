import 'package:auto_inject_dev/src/analyze/provider/class_analyzer.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../compile.dart';
import '../matcher/matcher.dart';

void main() {
  test('analyze a class', () async {
    final result = await compile('''
    class A {}
    class B {}

    @Injectable(env: ['test'])
    class Foo {
      final A a;
      final B b;

      Foo(this.a, this.b);
    }
    ''');

    final classElement = result.library.getClass('Foo')!;
    final reader = ConstantReader(classElement.metadata.first.computeConstantValue());

    final provider = analyzeClass(result.context, AnnotatedElement(reader, classElement));

    expect(provider.dependencies, equals([isDependency('A'), isDependency('B')]));
    expect(provider.env, equals(['test']));
    expect(provider.target, isDartType('Foo'));
  });
}
