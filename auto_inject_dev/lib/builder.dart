import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generator.dart';

Builder autoInjectBuilder(BuilderOptions options) {
  return LibraryBuilder(
    LibraryGenerator(),
    generatedExtension: '.auto.dart',
  );
}
