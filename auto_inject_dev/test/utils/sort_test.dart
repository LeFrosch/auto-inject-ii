import 'package:auto_inject_dev/src/analyze/dependency.dart';
import 'package:auto_inject_dev/src/analyze/provider/module_analyzer.dart';
import 'package:auto_inject_dev/src/exceptions.dart';
import 'package:auto_inject_dev/src/utils/sort.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../compile.dart';
import '../matcher/matcher.dart';

Matcher inOrder(List<String> types) {
  return equals(types.map((e) {
    final matcher = isA<DependencyProvider>();

    if (e != '_') {
      return matcher.having((v) => v.target, 'target', isDartType(e));
    } else {
      return matcher;
    }
  }).toList());
}

Future<List<DependencyProvider>> resolve(String content) async {
  final result = await compile('''
    class G {}

    class A implements G {}
    class B implements G {}
    class C implements G {}
    class D implements G {}

    @module
    abstract class Foo {
      $content
    }
    ''');

  final classElement = result.library.getClass('Foo')!;
  final reader = ConstantReader(classElement.metadata.first.computeConstantValue());

  return analyzeModule(result.context, AnnotatedElement(reader, classElement));
}

void main() {
  test('sort linear order', () async {
    final dependencies = await resolve('''
      @Singleton(env: ['test'])
      C c() => C();

      @Singleton(env: ['test'])
      B b(D d) => B();

      @Singleton(env: ['test'])
      D d(A a) => D();

      @Singleton(env: ['test'])
      A a(C c) => A();
      ''');

    expect(sort(dependencies, 'test'), inOrder(['C', 'A', 'D', 'B']));
    expect(sort(dependencies, 'test2'), isEmpty);
  });

  test('sort double dependency', () async {
    final dependencies = await resolve('''
      @Singleton(env: ['test', 'test2'])
      A a(C c, B b) => A();

      @Singleton(env: ['test', 'test2'])
      B b() => B();

      @Singleton(env: ['test'])
      C c() => C();
      ''');

    expect(sort(dependencies, 'test'), inOrder(['_', '_', 'A']));
    expect(() => sort(dependencies, 'test2'), throwsA(isA<InputException>()));
  });

  test('sort group dependency', () async {
    final dependencies = await resolve('''
      @Singleton(env: ['test'])
      A a(B b) => A();

      @Singleton(env: ['test'])
      B b(@group List<G> g) => B();

      @Singleton(env: ['test'], group: [G])
      C c() => C();

      @Singleton(env: ['test'], group: [G])
      D d() => D();
      ''');

    expect(sort(dependencies, 'test'), inOrder(['_', '_', 'B', 'A']));
  });

  test('sort assisted dependency', () async {
    final dependencies = await resolve('''
      @Injectable(env: ['test'])
      D d(C c, @assisted int test) => D();

      @Injectable(env: ['test'])
      B b(A a, @assisted String test) => B();

      @Singleton(env: ['test'])
      C c(A a) => C();

      @Singleton(env: ['test'])
      A a() => A();
      ''');

    expect(sort(dependencies, 'test'), inOrder(['A', 'C', 'D', 'B']));
  });
}
