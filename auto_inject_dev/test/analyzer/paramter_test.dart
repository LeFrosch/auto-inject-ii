import 'package:auto_inject_dev/src/analyze/dependency.dart';
import 'package:auto_inject_dev/src/analyze/utils/parameter_analyzer.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../compile.dart';
import '../matcher/matcher.dart';

Future<List<Dependency>> resolve(String content) async {
  final result = await compile('''
    class A {}
    class B {}

    class Foo {
      $content
    }
    ''');

  final classElement = result.library.getClass('Foo')!;
  final constructor = classElement.unnamedConstructor!;

  return analyzeParameter(result.context, constructor.parameters).toList();
}

void main() {
  test('right dependency types', () async {
    final dependencies = await resolve('''
      final A a;
      final B b;

      Foo(this.a, this.b);
      ''');

    expect(dependencies, equals([isDependency('A'), isDependency('B')]));
  });

  test('right List group type', () async {
    final dependencies = await resolve('''
      final List<A> a;

      Foo(@group this.a);
      ''');

    expect(dependencies, equals([isDependency('A', group: true)]));
  });

  test('right Iterable group type', () async {
    final dependencies = await resolve('''
      final Iterable<A> a;

      Foo(@group this.a);
      ''');

    expect(dependencies, equals([isDependency('A', group: true)]));
  });

  test('set assisted flag', () async {
    final dependencies = await resolve('''
      final A a;

      Foo(@assisted this.a);
      ''');

    expect(dependencies, equals([isDependency('A', assisted: true)]));
  });
}
