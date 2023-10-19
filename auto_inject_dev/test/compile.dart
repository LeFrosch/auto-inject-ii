import 'dart:convert';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:auto_inject_dev/builder.dart';
import 'package:auto_inject_dev/src/context.dart';
import 'package:build/build.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:build_test/build_test.dart';

class CompilationResult {
  final LibraryElement library;
  final Context context;

  CompilationResult(this.context, this.library);
}

class CompilationError extends Error {
  final List<AnalysisError> errors;

  CompilationError(this.errors);

  @override
  String toString() {
    return 'CompilationError:\n${errors.join('\n')}';
  }
}

Future<CompilationResult> compile(String code, {bool throwOnCompilationError = true}) async {
  final id = AssetId('test_lib', 'test.dart');
  final context = await resolveSource(
    '''
    library test_lib;

    import 'package:auto_inject/auto_inject.dart';

    $code
    ''',
    (r) async => Context(libraries: await r.libraries.toList(), resolver: r),
    inputId: id,
  );

  final lib = context.libraries.firstWhere((e) => e.name == id.package);
  final errorsResult = await lib.session.getErrors('/test_lib/test.dart') as ErrorsResult;
  final errors = errorsResult.errors.where((e) => e.severity == Severity.error).toList();

  if (errors.isNotEmpty && throwOnCompilationError) {
    throw CompilationError(errors);
  }

  return CompilationResult(context, lib);
}

String _writeFile(Iterable<String> files, String fileName, String content) {
  final buf = StringBuffer();
  buf.write("import 'package:auto_inject/auto_inject.dart';");

  for (final file in files) {
    if (file == fileName) continue;

    buf.write("import '$file';");
  }

  buf.write(content);
  return buf.toString();
}

Future<String> executeBuilder({required Map<String, String> files}) async {
  final rootPackage = 'test_lib';
  final rootFileAssetId = '$rootPackage|lib/main.dart';

  final allFiles = files.keys.toList();

  files = files.map((key, value) {
    final assetId = '$rootPackage|lib/$key';
    final content = _writeFile(allFiles, key, value);

    return MapEntry(assetId, content);
  });

  files[rootFileAssetId] = "library $rootPackage; export 'main.auto.dart';";

  final writer = InMemoryAssetWriter();
  final reader = InMemoryAssetReader(rootPackage: rootPackage);

  files.forEach((descriptor, contents) {
    reader.cacheStringAsset(AssetId.parse(descriptor), contents);
  });

  final writerSpy = AssetWriterSpy(writer);
  final multiReader = MultiAssetReader([reader, await PackageAssetReader.currentIsolate()]);

  await runBuilder(
    autoInjectBuilder(BuilderOptions({})),
    {AssetId.parse(rootFileAssetId)},
    multiReader,
    writerSpy,
    AnalyzerResolvers.custom(),
  );

  final resultAssetId = '$rootPackage|lib/main.auto.dart';
  final result = utf8.decode(writer.assets[AssetId.parse(resultAssetId)]!);

  files[resultAssetId] = result;

  final libraries = await resolveSources(
    files,
    (r) => r.libraries.toList(),
    resolverFor: rootFileAssetId,
    rootPackage: rootPackage,
  );

  final lib = libraries.firstWhere((e) => e.name == rootPackage);
  final errorsResult = await lib.session.getErrors('/$rootPackage/lib/main.auto.dart') as ErrorsResult;
  final errors = errorsResult.errors.where((e) => e.severity == Severity.error).toList();

  if (errors.isNotEmpty) {
    throw CompilationError(errors);
  }

  return result;
}
