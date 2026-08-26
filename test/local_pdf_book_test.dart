import 'package:flutter_test/flutter_test.dart';
import 'package:shejire/models/local_pdf_book.dart';

void main() {
  test('local PDF metadata survives JSON serialization', () {
    final importedAt = DateTime.utc(2026, 8, 26, 10, 30);
    final original = LocalPdfBook(
      id: 'book-1',
      title: 'Family history',
      storedFileName: 'book-1.pdf',
      fileSize: 2048,
      importedAt: importedAt,
    );

    final restored = LocalPdfBook.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.title, original.title);
    expect(restored.storedFileName, original.storedFileName);
    expect(restored.fileSize, original.fileSize);
    expect(restored.importedAt, original.importedAt);
  });
}
