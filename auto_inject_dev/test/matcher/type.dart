import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:auto_inject_dev/src/analyze/dependency.dart';
import 'package:auto_inject_dev/src/utils/type.dart';
import 'package:test/test.dart';

class TypeMatcher extends Matcher {
  final String type;
  final bool nullable;

  TypeMatcher(this.type, this.nullable);

  @override
  Description describe(Description description) {
    return description.add("Type should be of type '$type'");
  }

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription, Map matchState, bool verbose) {
    if (item is DartType) {
      if (!nullable && item.nullabilitySuffix == NullabilitySuffix.question) {
        return mismatchDescription.add('Is nullable');
      }

      return mismatchDescription.add("Is of type: '${item.getDisplayString(withNullability: false)}'");
    }
    if (item is TargetType) {
      return mismatchDescription.add("Is of type: '${item.symbol}'");
    }

    return mismatchDescription.add('Is not a DartType or TargetType');
  }

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is DartType) {
      if (!nullable && item.nullabilitySuffix == NullabilitySuffix.question) return false;

      return item.getDisplayString(withNullability: false) == type;
    }
    if (item is TargetType) {
      return item.symbol == type;
    }

    return false;
  }
}

Matcher isDartType(String type, {bool nullable = false}) => TypeMatcher(type, nullable);

Matcher isDependency(String type, {bool assisted = false, bool group = false}) => isA<Dependency>()
    .having((v) => v.target, 'target', isDartType(type))
    .having((v) => v.assisted, 'assisted', equals(assisted))
    .having((v) => v.group, 'group', equals(group));
