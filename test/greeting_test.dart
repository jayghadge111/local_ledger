import 'package:flutter_test/flutter_test.dart';
import 'package:local_ledger/core/profile/greeting.dart';

void main() {
  test('greeting follows the time of day', () {
    String at(int h) => greetingFor(DateTime(2026, 10, 3, h));
    expect(at(5), 'Good morning');
    expect(at(11), 'Good morning');
    expect(at(12), 'Good afternoon');
    expect(at(16), 'Good afternoon');
    expect(at(17), 'Good evening');
    expect(at(20), 'Good evening');
    expect(at(21), 'Good night');
    expect(at(2), 'Good night');
  });

  test('names are tidied for display', () {
    expect(prettyName('  MR JAYESH bhika GHADGE '), 'Jayesh Bhika Ghadge');
    expect(firstNameOf('MR JAYESH BHIKA GHADGE'), 'Jayesh');
    expect(initialsOf('Jayesh Bhika Ghadge'), 'JG');
    expect(initialsOf('Madonna'), 'M');
    expect(initialsOf(null), '');
    expect(firstNameOf('  '), isNull);
  });
}
