import 'package:analyzer/dart/element/element.dart';

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

class UnexpectedException implements Exception {
  final String description;

  UnexpectedException(this.description);
}
