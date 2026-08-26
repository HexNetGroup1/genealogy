import 'package:flutter_test/flutter_test.dart';
import 'package:shejire/models/shared_pdf_book.dart';

void main() {
  test('parses a shared PDF book returned by Supabase', () {
    final book = SharedPdfBook.fromJson({
      'id': 'c36f6f01-cf1d-4c98-98eb-6d25e17f171d',
      'title': 'Шежіре кітабы',
      'description': 'Ортақ кітап',
      'storage_path': 'c36f6f01-cf1d-4c98-98eb-6d25e17f171d.pdf',
      'original_filename': 'shezhire.pdf',
      'file_size': 4096,
      'created_at': '2026-08-26T10:15:00.000Z',
    });

    expect(book.title, 'Шежіре кітабы');
    expect(book.description, 'Ортақ кітап');
    expect(book.fileSize, 4096);
    expect(book.createdAt, DateTime.utc(2026, 8, 26, 10, 15));
  });
}
