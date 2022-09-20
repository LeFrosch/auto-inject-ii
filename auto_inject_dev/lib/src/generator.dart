import 'package:analyzer/dart/element/element.dart';
import 'package:auto_inject/auto_inject.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:collection/collection.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

import 'analyze/provider/assisted_analyzer.dart';
import 'analyze/provider/class_analyzer.dart';
import 'analyze/provider/group_analyzer.dart';
import 'analyze/provider/module_analyzer.dart';
import 'context.dart';
import 'utils/environment.dart';
import 'utils/sort.dart';
import 'write/env_method.dart';
import 'write/init_method.dart';
import 'write/module_writer.dart';

class LibraryGenerator implements Generator {
  static final _dartFilesGlob = Glob("lib/**.dart");

  Future<LibraryElement?> _libraryFromAsset(AssetId assetId, Resolver resolver) async {
    try {
      return await resolver.libraryFor(assetId, allowSyntaxErrors: true);
    } on NonLibraryAssetException catch (_) {
      return null;
    }
  }

  Future<List<LibraryReader>> _readerFromGlob(BuildStep buildStep, Glob glob) {
    return buildStep
        .findAssets(glob)
        .asyncMap((file) async => await _libraryFromAsset(file, buildStep.resolver))
        .where((library) => library != null)
        .map((library) => LibraryReader(library!))
        .toList();
  }

  Iterable<AnnotatedElement> _annotatedWith(List<LibraryReader> readers, Type type) {
    final typeChecker = TypeChecker.fromRuntime(type);
    return readers.map((e) => e.annotatedWith(typeChecker)).flattened;
  }

  @override
  Future<String?> generate(LibraryReader _, BuildStep buildStep) async {
    final readers = await _readerFromGlob(buildStep, _dartFilesGlob);
    final context = Context(libraries: await buildStep.resolver.libraries.toList());

    context.registerWriter(ModuleHelperWriter());

    final classes = _annotatedWith(readers, Injectable).map((e) => analyzeClass(context, e));
    final modules = _annotatedWith(readers, Module).map((e) => analyzeModule(context, e)).flattened;

    final provider = classes.followedBy(modules).toList();

    analyzeGroups(context, provider);
    analyzeAssisted(context, provider);

    final library = Library((libraryBuilder) {
      for (final writer in context.writers) {
        final spec = writer.executeGlobal(context);
        if (spec != null) {
          libraryBuilder.body.add(spec);
        }
      }

      final envs = getEnvironments(provider);
      for (final env in envs) {
        final sorted = sort(provider, env);

        libraryBuilder.body.add(envMethod(context, sorted, env));
      }

      libraryBuilder.body.add(initMethod(context, envs));
    });

    return library.accept(DartEmitter.scoped(useNullSafetySyntax: true)).toString();
  }
}
