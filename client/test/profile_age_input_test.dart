import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/screens/profile_age_input.dart';

void main() {
  test('пустой возраст валиден', () {
    expect(profileAgeIsInvalid(''), isFalse);
    expect(profileAgeIsInvalid('  '), isFalse);
  });

  test('1–111 валидны, 0 и 125 нет', () {
    expect(profileAgeIsInvalid('1'), isFalse);
    expect(profileAgeIsInvalid('12'), isFalse);
    expect(profileAgeIsInvalid('111'), isFalse);
    expect(profileAgeIsInvalid('0'), isTrue);
    expect(profileAgeIsInvalid('125'), isTrue);
    expect(profileAgeIsInvalid('abc'), isTrue);
  });

  test('форматтер не пропускает 125', () {
    const formatter = ProfileAgeRangeFormatter();
    const old = TextEditingValue(text: '12');
    final next = formatter.formatEditUpdate(
      old,
      const TextEditingValue(text: '125'),
    );
    expect(next.text, '12');
  });

  test('форматтер принимает 111 и пустое', () {
    const formatter = ProfileAgeRangeFormatter();
    expect(
      formatter
          .formatEditUpdate(
            const TextEditingValue(text: '11'),
            const TextEditingValue(text: '111'),
          )
          .text,
      '111',
    );
    expect(
      formatter
          .formatEditUpdate(
            const TextEditingValue(text: '1'),
            TextEditingValue.empty,
          )
          .text,
      '',
    );
  });
}
