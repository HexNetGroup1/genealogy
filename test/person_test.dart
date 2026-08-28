import 'package:flutter_test/flutter_test.dart';
import 'package:shejire/features/home/models/person.dart';

void main() {
  group('Person.displayName', () {
    test('uses a regular name', () {
      const person = Person(id: '1', name: '  Abai  ', path: 'Alash > Abai');

      expect(person.displayName, 'Abai');
    });

    test('uses the last path part for a placeholder name', () {
      const person = Person(
        id: '2',
        name: '-',
        path: 'Alash > Orta zhuz > Argyn > Aitkozha',
      );

      expect(person.displayName, 'Aitkozha');
    });

    test('supports paths created by the admin form', () {
      const person = Person(id: '3', name: ' ', path: 'Alash.Argyn.Kanat');

      expect(person.displayName, 'Kanat');
    });
  });
}
