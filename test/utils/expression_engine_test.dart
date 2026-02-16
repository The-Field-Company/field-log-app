import 'package:flutter_test/flutter_test.dart';
import 'package:fieldlog_mobile/utils/expression_engine.dart';

void main() {
  group('ExpressionEngine', () {
    group('null / empty → true (fail-open)', () {
      test('null expression', () {
        expect(ExpressionEngine.evaluate(null, {}), isTrue);
      });
      test('empty string', () {
        expect(ExpressionEngine.evaluate('', {}), isTrue);
      });
      test('whitespace only', () {
        expect(ExpressionEngine.evaluate('   ', {}), isTrue);
      });
    });

    group('equality', () {
      test('string equal', () {
        expect(
          ExpressionEngine.evaluate("{q1} = 'yes'", {'q1': 'yes'}),
          isTrue,
        );
      });
      test('string not equal', () {
        expect(
          ExpressionEngine.evaluate("{q1} = 'yes'", {'q1': 'no'}),
          isFalse,
        );
      });
      test('<> operator', () {
        expect(
          ExpressionEngine.evaluate("{q1} <> 'yes'", {'q1': 'no'}),
          isTrue,
        );
      });
      test('!= operator', () {
        expect(
          ExpressionEngine.evaluate("{q1} != 'yes'", {'q1': 'no'}),
          isTrue,
        );
      });
      test('numeric equality with coercion', () {
        expect(
          ExpressionEngine.evaluate("{age} = 25", {'age': '25'}),
          isTrue,
        );
      });
    });

    group('comparisons', () {
      test('greater than', () {
        expect(
          ExpressionEngine.evaluate("{age} > 18", {'age': 25}),
          isTrue,
        );
      });
      test('less than', () {
        expect(
          ExpressionEngine.evaluate("{age} < 18", {'age': 10}),
          isTrue,
        );
      });
      test('greater or equal', () {
        expect(
          ExpressionEngine.evaluate("{age} >= 18", {'age': 18}),
          isTrue,
        );
      });
      test('less or equal', () {
        expect(
          ExpressionEngine.evaluate("{age} <= 18", {'age': 18}),
          isTrue,
        );
      });
      test('greater than false', () {
        expect(
          ExpressionEngine.evaluate("{age} > 18", {'age': 10}),
          isFalse,
        );
      });
    });

    group('contains', () {
      test('string contains', () {
        expect(
          ExpressionEngine.evaluate("{name} contains 'ohn'", {'name': 'John'}),
          isTrue,
        );
      });
      test('string not contains', () {
        expect(
          ExpressionEngine.evaluate("{name} contains 'xyz'", {'name': 'John'}),
          isFalse,
        );
      });
      test('list contains', () {
        expect(
          ExpressionEngine.evaluate(
            "{colors} contains 'red'",
            {
              'colors': ['red', 'blue'],
            },
          ),
          isTrue,
        );
      });
    });

    group('anyof', () {
      test('single value in array', () {
        expect(
          ExpressionEngine.evaluate(
            "{q1} anyof ['a', 'b', 'c']",
            {'q1': 'b'},
          ),
          isTrue,
        );
      });
      test('single value not in array', () {
        expect(
          ExpressionEngine.evaluate(
            "{q1} anyof ['a', 'b', 'c']",
            {'q1': 'd'},
          ),
          isFalse,
        );
      });
      test('list value with overlap', () {
        expect(
          ExpressionEngine.evaluate(
            "{q1} anyof ['a', 'b']",
            {
              'q1': ['b', 'x'],
            },
          ),
          isTrue,
        );
      });
    });

    group('empty / notempty', () {
      test('null is empty', () {
        expect(
          ExpressionEngine.evaluate("{q1} empty", {}),
          isTrue,
        );
      });
      test('empty string is empty', () {
        expect(
          ExpressionEngine.evaluate("{q1} empty", {'q1': ''}),
          isTrue,
        );
      });
      test('non-empty string is notempty', () {
        expect(
          ExpressionEngine.evaluate("{q1} notempty", {'q1': 'hello'}),
          isTrue,
        );
      });
      test('empty list is empty', () {
        expect(
          ExpressionEngine.evaluate("{q1} empty", {'q1': []}),
          isTrue,
        );
      });
      test('value present is not empty', () {
        expect(
          ExpressionEngine.evaluate("{q1} empty", {'q1': 'val'}),
          isFalse,
        );
      });
    });

    group('logical combinators', () {
      test('and - both true', () {
        expect(
          ExpressionEngine.evaluate(
            "{a} = 'x' and {b} = 'y'",
            {'a': 'x', 'b': 'y'},
          ),
          isTrue,
        );
      });
      test('and - one false', () {
        expect(
          ExpressionEngine.evaluate(
            "{a} = 'x' and {b} = 'y'",
            {'a': 'x', 'b': 'z'},
          ),
          isFalse,
        );
      });
      test('or - one true', () {
        expect(
          ExpressionEngine.evaluate(
            "{a} = 'x' or {b} = 'y'",
            {'a': 'x', 'b': 'z'},
          ),
          isTrue,
        );
      });
      test('or - both false', () {
        expect(
          ExpressionEngine.evaluate(
            "{a} = 'x' or {b} = 'y'",
            {'a': 'z', 'b': 'z'},
          ),
          isFalse,
        );
      });
    });

    group('parenthesized grouping', () {
      test('changes precedence', () {
        // Without parens: a=x AND (b=y OR c=z) would need explicit parens
        expect(
          ExpressionEngine.evaluate(
            "({a} = 'x' or {b} = 'y') and {c} = 'z'",
            {'a': 'wrong', 'b': 'y', 'c': 'z'},
          ),
          isTrue,
        );
      });
      test('nested parentheses', () {
        expect(
          ExpressionEngine.evaluate(
            "(({a} = 'x'))",
            {'a': 'x'},
          ),
          isTrue,
        );
      });
    });

    group('fail-open on bad input', () {
      test('malformed expression returns true', () {
        expect(
          ExpressionEngine.evaluate("??? broken {{", {'q1': 'x'}),
          isTrue,
        );
      });
      test('unknown operator returns true', () {
        expect(
          ExpressionEngine.evaluate("{q1} unknownop 'x'", {'q1': 'x'}),
          isTrue,
        );
      });
    });

    group('word operators', () {
      test('equal keyword', () {
        expect(
          ExpressionEngine.evaluate("{q1} equal 'yes'", {'q1': 'yes'}),
          isTrue,
        );
      });
      test('notequal keyword', () {
        expect(
          ExpressionEngine.evaluate("{q1} notequal 'yes'", {'q1': 'no'}),
          isTrue,
        );
      });
      test('greater keyword', () {
        expect(
          ExpressionEngine.evaluate("{q1} greater 5", {'q1': 10}),
          isTrue,
        );
      });
    });

    group('boolean literals', () {
      test('equals true', () {
        expect(
          ExpressionEngine.evaluate("{q1} = true", {'q1': true}),
          isTrue,
        );
      });
      test('equals false', () {
        expect(
          ExpressionEngine.evaluate("{q1} = false", {'q1': false}),
          isTrue,
        );
      });
    });

    group('double-quoted strings', () {
      test('double quotes work', () {
        expect(
          ExpressionEngine.evaluate('{q1} = "hello"', {'q1': 'hello'}),
          isTrue,
        );
      });
    });
  });
}
