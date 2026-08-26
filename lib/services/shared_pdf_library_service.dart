import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/shared_pdf_book.dart';
import 'supabase_initializer.dart';

class SharedPdfLibraryService {
  SharedPdfLibraryService._();

  static final SharedPdfLibraryService instance = SharedPdfLibraryService._();

  static const _bucketName = 'library-books';

  SupabaseClient get _client => SupabaseInitializer.client;

  Future<List<SharedPdfBook>> getBooks() async {
    final rows = await _client
        .from('shared_books')
        .select(
          'id,title,description,storage_path,original_filename,file_size,created_at',
        )
        .order('created_at', ascending: false);

    return rows
        .map((row) => SharedPdfBook.fromJson(row))
        .toList(growable: false);
  }

  Future<String> getCachedBookPath(SharedPdfBook book) async {
    final cacheDirectory = await _getCacheDirectory();
    final cachedFile = File(path.join(cacheDirectory.path, '${book.id}.pdf'));

    if (await _isValidCachedFile(cachedFile, book.fileSize)) {
      return cachedFile.path;
    }

    if (await cachedFile.exists()) {
      await cachedFile.delete();
    }

    try {
      final bytes = await _client.storage
          .from(_bucketName)
          .download(book.storagePath);
      await cachedFile.writeAsBytes(bytes, flush: true);

      if (!await _isValidCachedFile(cachedFile, book.fileSize)) {
        throw const FormatException('Сервердегі файл жарамды PDF емес.');
      }
      return cachedFile.path;
    } catch (_) {
      if (await cachedFile.exists()) {
        await cachedFile.delete();
      }
      rethrow;
    }
  }

  Future<Directory> _getCacheDirectory() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final cacheDirectory = Directory(
      path.join(supportDirectory.path, 'shared_pdf_cache'),
    );
    if (!await cacheDirectory.exists()) {
      await cacheDirectory.create(recursive: true);
    }
    return cacheDirectory;
  }

  Future<bool> _isValidCachedFile(File file, int expectedSize) async {
    if (!await file.exists() || await file.length() != expectedSize) {
      return false;
    }

    final randomAccessFile = await file.open();
    try {
      final signature = await randomAccessFile.read(5);
      return signature.length == 5 && ascii.decode(signature) == '%PDF-';
    } finally {
      await randomAccessFile.close();
    }
  }
}
