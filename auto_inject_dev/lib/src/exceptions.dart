import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';

import 'utils/type.dart';

class InputException implements Exception {
  final String description;
  final Element? cause;
  final String? fix;

  InputException(this.description, {this.cause, this.fix});

  @override
  String toString() {
    final buf = StringBuffer();

    buf.write('Invalid input: $description\n');

    if (fix != null) {
      buf.write('Possible fix: $fix\n');
    }

    if (cause != null) {
      final source = cause!.source?.fullName;
      buf.write('Caused by: $cause [${cause?.kind}] in $source\n');
    }

    return buf.toString();
  }
}

class SortExcption implements Exception {
  final String env;
  final Map<TargetType, List<TargetType>> dependencies;

  SortExcption(this.dependencies, {required this.env});

  @override
  String toString() {
    final buf = StringBuffer();
    buf.writeln('Could not sort dependencies in $env, affected dependencies:');

    final nameWidth = dependencies.keys.map((e) => e.toString().length).max;
    for (final entry in dependencies.entries) {
      buf.write(entry.key.toString().padLeft(nameWidth));
      buf.write(' -> ');
      buf.write(entry.value.map((e) => e.toString()).sorted().join(', '));
      buf.writeln();
    }

    buf.writeln('\nPossible fix: Make sure all dependencies can be satisfied. Look out for circles (╭ರ_•́)');

    return buf.toString();
  }
}

class UnexpectedException implements Exception {
  final String description;

  UnexpectedException(this.description);
}
