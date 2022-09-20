import 'package:test/test.dart';

class OutputMatcher extends Matcher {
  final List<String> contains;

  OutputMatcher(this.contains);

  String _trim(String item) => item.replaceAll(' ', '').replaceAll('\n', '');

  @override
  Description describe(Description description) {
    final content = contains.map((e) => "'$e'").join(', ');
    return description.add('input should contain: $content');
  }

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription, Map matchState, bool verbose) {
    if (item is! String) return mismatchDescription.add('not a String');

    final trimmed = _trim(item);
    for (final entry in contains.map(_trim)) {
      if (!trimmed.contains(entry)) {
        return mismatchDescription.add("does not contain '$entry'");
      }
    }

    return mismatchDescription;
  }

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! String) return false;

    final trimmed = _trim(item);
    for (final entry in contains.map(_trim)) {
      if (!trimmed.contains(entry)) {
        return false;
      }
    }

    return true;
  }
}

Matcher outputContains(List<String> contains) => OutputMatcher(contains);
