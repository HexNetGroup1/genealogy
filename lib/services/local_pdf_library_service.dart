import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/local_pdf_book.dart';

class LocalPdfLibraryService {
  LocalPdfLibraryService._();

  static final LocalPdfLibraryService instance = LocalPdfLibraryService._();

  Future<Directory> _getLibraryDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final libraryDirectory = Directory(
      path.join(documentsDirectory.path, 'pdf_library'),
    );

    if (!await libraryDirectory.exists()) {
      await libraryDirectory.create(recursive: true);
    }

    return libraryDirectory;
  }

  Future<File> _getIndexFile() async {
    final libraryDirectory = await _getLibraryDirectory();
    return File(path.join(libraryDirectory.path, 'library.json'));
  }

  Future<List<LocalPdfBook>> getBooks() async {
    await _removeLegacyRemoteBookCache();

    final indexFile = await _getIndexFile();
    if (!await indexFile.exists()) {
      return [];
    }

    try {
      final decoded =
          jsonDecode(await indexFile.readAsString()) as List<dynamic>;
      final books = decoded
          .map((item) => LocalPdfBook.fromJson(item as Map<String, dynamic>))
          .toList();

      final availableBooks = <LocalPdfBook>[];
      for (final book in books) {
        if (await File(await getBookPath(book)).exists()) {
          availableBooks.add(book);
        }
      }

      availableBooks.sort((a, b) => b.importedAt.compareTo(a.importedAt));
      if (availableBooks.length != books.length) {
        await _saveBooks(availableBooks);
      }
      return availableBooks;
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  Future<LocalPdfBook> importPdf(XFile selectedFile) async {
    if (path.extension(selectedFile.name).toLowerCase() != '.pdf') {
      throw const FormatException('Тек PDF форматындағы файлды таңдаңыз.');
    }

    final books = await getBooks();
    final libraryDirectory = await _getLibraryDirectory();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final storedFileName = '$id.pdf';
    final destinationPath = path.join(libraryDirectory.path, storedFileName);

    try {
      await selectedFile.saveTo(destinationPath);
      final destinationFile = File(destinationPath);

      if (!await _hasPdfSignature(destinationFile)) {
        await destinationFile.delete();
        throw const FormatException('Таңдалған файл жарамды PDF емес.');
      }

      final title = path.basenameWithoutExtension(selectedFile.name).trim();
      final book = LocalPdfBook(
        id: id,
        title: title.isEmpty ? 'PDF құжаты' : title,
        storedFileName: storedFileName,
        fileSize: await destinationFile.length(),
        importedAt: DateTime.now(),
      );

      await _saveBooks([book, ...books]);
      return book;
    } catch (_) {
      final incompleteFile = File(destinationPath);
      if (await incompleteFile.exists()) {
        await incompleteFile.delete();
      }
      rethrow;
    }
  }

  Future<String> getBookPath(LocalPdfBook book) async {
    final libraryDirectory = await _getLibraryDirectory();
    return path.join(libraryDirectory.path, book.storedFileName);
  }

  Future<void> deleteBook(LocalPdfBook book) async {
    final books = await getBooks();
    final bookFile = File(await getBookPath(book));
    if (await bookFile.exists()) {
      await bookFile.delete();
    }

    await _saveBooks(books.where((item) => item.id != book.id).toList());
  }

  Future<bool> _hasPdfSignature(File file) async {
    final randomAccessFile = await file.open();
    try {
      final bytes = await randomAccessFile.read(5);
      return bytes.length == 5 && ascii.decode(bytes) == '%PDF-';
    } finally {
      await randomAccessFile.close();
    }
  }

  Future<void> _saveBooks(List<LocalPdfBook> books) async {
    final indexFile = await _getIndexFile();
    final encoded = jsonEncode(books.map((book) => book.toJson()).toList());
    await indexFile.writeAsString(encoded, flush: true);
  }

  Future<void> _removeLegacyRemoteBookCache() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final legacyCache = Directory(
      path.join(documentsDirectory.path, 'book_cache'),
    );
    if (await legacyCache.exists()) {
      await legacyCache.delete(recursive: true);
    }
  }
}
