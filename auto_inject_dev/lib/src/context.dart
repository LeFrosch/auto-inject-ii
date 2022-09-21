import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

import 'write/writer.dart';

export 'utils/resolve.dart';

class Context {
  int _moduleId;

  final List<LibraryElement> libraries;
  final Resolver resolver;
  final List<Writer> writers;

  Context({required this.libraries, required this.resolver})
      : _moduleId = 0,
        writers = [];

  int get moduleCount => _moduleId;

  int getNewModuleId() => _moduleId++;

  void registerWriter(Writer writer) => writers.add(writer);
}
