import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shejire/features/home/data/supabase_genealogy_repository.dart';

void main() {
  test('generated person ID is a valid lowercase UUID v4', () {
    final id = generatePersonId(Random(42));

    expect(
      id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('generated person IDs are unique', () {
    final random = Random(42);
    final ids = {
      for (var index = 0; index < 100; index++) generatePersonId(random),
    };

    expect(ids, hasLength(100));
  });
}
