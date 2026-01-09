import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';

/// Сервис для загрузки книг с GitHub и кэширования
class BookService {
  static const String _metadataUrl = 
    'https://raw.githubusercontent.com/Almaz0430/genealogy-books/main/books.json';
  
  static BookService? _instance;
  List<Book>? _books;
  
  BookService._();
  
  static BookService get instance {
    _instance ??= BookService._();
    return _instance!;
  }

  /// Получить список всех книг
  Future<List<Book>> getBooks({bool forceRefresh = false}) async {
    if (_books != null && !forceRefresh) {
      return _books!;
    }
    
    try {
      final response = await http.get(Uri.parse(_metadataUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final booksList = data['books'] as List<dynamic>;
        _books = booksList.map((json) => Book.fromJson(json as Map<String, dynamic>)).toList();
        return _books!;
      } else {
        throw Exception('Ошибка загрузки метаданных: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Не удалось загрузить список книг: $e');
    }
  }

  /// Получить книгу по ID
  Future<Book?> getBook(String bookId) async {
    final books = await getBooks();
    return books.where((b) => b.id == bookId).firstOrNull;
  }

  /// Получить путь к директории кэша
  Future<Directory> _getCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/book_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Получить путь к кэшированной странице
  Future<String> _getCachedPagePath(String bookId, int pageIndex) async {
    final cacheDir = await _getCacheDir();
    final pageNumber = (pageIndex + 1).toString().padLeft(4, '0');
    return '${cacheDir.path}/${bookId}_page_$pageNumber.png';
  }

  /// Проверить, закэширована ли страница
  Future<bool> isPageCached(String bookId, int pageIndex) async {
    final path = await _getCachedPagePath(bookId, pageIndex);
    return File(path).exists();
  }

  /// Загрузить и закэшировать страницу
  Future<File> downloadPage(Book book, int pageIndex) async {
    final cachedPath = await _getCachedPagePath(book.id, pageIndex);
    final file = File(cachedPath);
    
    // Проверить кэш
    if (await file.exists()) {
      return file;
    }
    
    // Загрузить с GitHub
    final url = book.getPageUrl(pageIndex);
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        throw Exception('Ошибка загрузки страницы: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Не удалось загрузить страницу: $e');
    }
  }

  /// Получить путь к странице (из кэша или URL)
  Future<String> getPagePath(Book book, int pageIndex) async {
    final cachedPath = await _getCachedPagePath(book.id, pageIndex);
    final file = File(cachedPath);
    
    if (await file.exists()) {
      return cachedPath; // Локальный путь
    }
    
    return book.getPageUrl(pageIndex); // URL для загрузки
  }

  /// Проверить, является ли путь локальным
  bool isLocalPath(String path) {
    return !path.startsWith('http');
  }

  /// Очистить кэш книги
  Future<void> clearBookCache(String bookId) async {
    final cacheDir = await _getCacheDir();
    final files = await cacheDir.list().toList();
    for (final entity in files) {
      if (entity is File && entity.path.contains(bookId)) {
        await entity.delete();
      }
    }
  }

  /// Очистить весь кэш
  Future<void> clearAllCache() async {
    final cacheDir = await _getCacheDir();
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
  }

  /// Получить размер кэша в байтах
  Future<int> getCacheSize() async {
    final cacheDir = await _getCacheDir();
    if (!await cacheDir.exists()) return 0;
    
    int size = 0;
    await for (final entity in cacheDir.list(recursive: true)) {
      if (entity is File) {
        size += await entity.length();
      }
    }
    return size;
  }

  /// Предзагрузка нескольких страниц (для плавного листания)
  Future<void> preloadPages(Book book, int currentPage, {int ahead = 3, int behind = 1}) async {
    final futures = <Future>[];
    
    // Загрузить страницы вперед
    for (int i = 1; i <= ahead; i++) {
      final pageIndex = currentPage + i;
      if (pageIndex < book.pageCount) {
        futures.add(downloadPage(book, pageIndex).catchError((_) {}));
      }
    }
    
    // Загрузить страницы назад
    for (int i = 1; i <= behind; i++) {
      final pageIndex = currentPage - i;
      if (pageIndex >= 0) {
        futures.add(downloadPage(book, pageIndex).catchError((_) {}));
      }
    }
    
    await Future.wait(futures);
  }
}
