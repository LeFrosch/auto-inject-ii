import 'package:auto_inject_dev/src/analyze/dependency.dart';
import 'package:auto_inject_dev/src/analyze/utils/annotation_analyzer.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../compile.dart';
import '../matcher/matcher.dart';

Future<InjectableAnnotation> resolve(String annotation) async {
  final result = await compile('''
    class A {}
    class B {}

    @$annotation
    class Foo implements A {}
    ''');

  final classElement = result.library.getClass('Foo')!;
  final reader = ConstantReader(classElement.metadata.first.computeConstantValue());

  return analyzeAnnotation(result.context, classElement.thisType, reader);
}

void main() {
  test('right target value', () async {
    final annotation1 = await resolve("Injectable(env: ['test'], as: A)");
    expect(annotation1.target, isDartType('A'));

    final annotation2 = await resolve("Injectable(env: ['test'])");
    expect(annotation2.target, isDartType('Foo'));
  });

  test('right env value', () async {
    final annotation = await resolve("Injectable(env: ['test'])");

    expect(annotation.env, equals(['test']));
  });

  test('right group value', () async {
    final annotation = await resolve("Injectable(env: ['test'], group: [A])");

    expect(annotation.group, equals([isDartType('A')]));
  });

  test('right dependency type', () async {
    final injectableAnnotation = await resolve("Injectable(env: ['test'])");
    final singletonAnnotation = await resolve("Singleton(env: ['test'])");
    final lazySingletonAnnotation = await resolve("Singleton(env: ['test'], lazy: true)");

    expect(injectableAnnotation.type, equals(ProviderType.injectable));
    expect(singletonAnnotation.type, equals(ProviderType.singleton));
    expect(lazySingletonAnnotation.type, equals(ProviderType.lazySingleton));
  });
}
