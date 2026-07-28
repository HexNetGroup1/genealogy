import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/book.dart';
import '../../../services/book_service.dart';
import 'remote_book_viewer.dart';

/// Экран "Библиотека" с выбором книг - загрузка с GitHub
class BookLibrary extends StatefulWidget {
  const BookLibrary({super.key});

  @override
  State<BookLibrary> createState() => _BookLibraryState();
}

class _BookLibraryState extends State<BookLibrary> {
  final BookService _bookService = BookService.instance;
  
  List<Book>? _books;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final books = await _bookService.getBooks();
      if (mounted) {
        setState(() {
          _books = books;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _openBook(Book book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RemoteBookViewer(book: book),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Кітаптар жүктелуде...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Кітаптарды жүктеу мүмкін болмады',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Интернет байланысын тексеріңіз',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadBooks,
                icon: const Icon(Icons.refresh),
                label: const Text('Қайталау'),
              ),
            ],
          ),
        ),
      );
    }

    if (_books == null || _books!.isEmpty) {
      return const Center(
        child: Text('Кітаптар табылмады'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadBooks(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.62,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _books!.length,
          itemBuilder: (context, index) {
            final book = _books![index];
            return _BookCard(
              book: book,
              onTap: () => _openBook(book),
            );
          },
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.onTap,
  });

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Фиксированная область обложки
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 10,
                    offset: const Offset(4, 6),
                  ),
                ],
              ),
              child: Hero(
                tag: 'book_cover_${book.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: book.thumbnailUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.book, size: 48),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Название — строго 2 строки, обрезается
          SizedBox(
            height: 40,
            child: Text(
              book.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          // Кол-во страниц — всегда 1 строка
          Text(
            '${book.pageCount} бет',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

