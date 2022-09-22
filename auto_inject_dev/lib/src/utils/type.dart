import 'package:code_builder/code_builder.dart';
import 'package:equatable/equatable.dart';
import 'package:source_gen/source_gen.dart';

class TargetType extends Equatable {
  final String symbol;
  final String? url;
  final String? typeCheckerUrl;
  final List<TargetType> genericTypes;

  TargetType({required this.symbol, required this.url, this.typeCheckerUrl, this.genericTypes = const []})
      : assert(symbol.isNotEmpty);

  @override
  List<Object?> get props => [symbol, url, genericTypes];

  Reference get reference => TypeReference(
        (builder) => builder
          ..symbol = symbol
          ..url = url
          ..types.addAll(genericTypes.map((e) => e.reference)),
      );

  TypeChecker get typeChecker {
    if (url == null) {
      return TypeChecker.fromUrl('dart:core#$symbol');
    } else {
      return TypeChecker.fromUrl('${typeCheckerUrl ?? url}#$symbol');
    }
  }

  String get codeFriendlyName {
    final buf = StringBuffer();
    buf.write(symbol[0].toUpperCase());

    if (symbol.length > 1) {
      buf.write(symbol.substring(1));
    }

    if (genericTypes.isNotEmpty) {
      buf.write('\$');
      buf.write(genericTypes.join());
    }

    return buf.toString();
  }

  @override
  String toString() {
    final buf = StringBuffer();
    buf.write(symbol);

    if (genericTypes.isNotEmpty) {
      buf.write('<');
      buf.write(genericTypes.join(', '));
      buf.write('>');
    }

    return buf.toString();
  }
}
