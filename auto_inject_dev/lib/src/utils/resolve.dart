import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../context.dart';
import 'type.dart';

bool _isCoreDartType(Element? element) {
  return element?.source?.fullName == 'dart:core';
}

extension ResolveExtension on Context {
  String? _resolveImport(List<LibraryElement> libraries, Element? element) {
    // return early if source is null or element is a core type
    if (element?.source == null || _isCoreDartType(element)) {
      return null;
    }

    for (final lib in libraries) {
      if (!_isCoreDartType(lib) && lib.exportNamespace.definedNames.values.contains(element)) {
        return lib.identifier;
      }
    }

    return null;
  }

  String _resolveDartTypeName(DartType type) {
    return type.element2?.name ?? type.getDisplayString(withNullability: false);
  }

  Iterable<TargetType> _resolveTypeArguments(List<LibraryElement> libraries, DartType type) sync* {
    if (type is! ParameterizedType) {
      return;
    }

    for (final argumentType in type.typeArguments) {
      yield resolveDartType(argumentType);
    }
  }

  TargetType resolveDartType(DartType type) {
    return TargetType(
      symbol: _resolveDartTypeName(type),
      url: _resolveImport(libraries, type.element2),
      typeCheckerUrl: type.element2?.librarySource?.uri.toString(),
      genericTypes: _resolveTypeArguments(libraries, type).toList(),
    );
  }
}
