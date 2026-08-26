import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../models/local_pdf_book.dart';
import '../../../services/local_pdf_library_service.dart';
import '../screens/local_pdf_viewer_screen.dart';

class BookLibrary extends StatefulWidget {
  const BookLibrary({super.key});

  @override
  State<BookLibrary> createState() => _BookLibraryState();
}

class _BookLibraryState extends State<BookLibrary> {
  static const _pdfTypeGroup = XTypeGroup(
    label: 'PDF',
    extensions: ['pdf'],
    mimeTypes: ['application/pdf'],
    uniformTypeIdentifiers: ['com.adobe.pdf'],
    webWildCards: ['application/pdf'],
  );

  final _libraryService = LocalPdfLibraryService.instance;

  List<LocalPdfBook> _books = [];
  bool _isLoading = true;
  bool _isImporting = false;
  Object? _error;

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
      final books = await _libraryService.getBooks();
      if (!mounted) return;
      setState(() {
        _books = books;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _importPdf() async {
    if (_isImporting) return;

    setState(() => _isImporting = true);
    try {
      final selectedFile = await openFile(
        acceptedTypeGroups: const [_pdfTypeGroup],
      );
      if (selectedFile == null) return;

      final book = await _libraryService.importPdf(selectedFile);
      if (!mounted) return;
      setState(() => _books = [book, ..._books]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('«${book.title}» кітапханаға қосылды.')),
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (_) {
      if (!mounted) return;
      _showError('PDF файлын қосу мүмкін болмады.');
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _openBook(LocalPdfBook book) async {
    final filePath = await _libraryService.getBookPath(book);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            LocalPdfViewerScreen(title: book.title, filePath: filePath),
      ),
    );
  }

  Future<void> _confirmDelete(LocalPdfBook book) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF файлын жою керек пе?'),
        content: Text('«${book.title}» осы құрылғыдан жойылады.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Болдырмау'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Жою'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await _libraryService.deleteBook(book);
      if (!mounted) return;
      setState(() => _books.removeWhere((item) => item.id == book.id));
    } catch (_) {
      if (!mounted) return;
      _showError('PDF файлын жою мүмкін болмады.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      floatingActionButton: _books.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _isImporting ? null : _importPdf,
              backgroundColor: const Color(0xFFF57F17),
              foregroundColor: Colors.white,
              icon: _isImporting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('PDF қосу'),
            ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _LibraryMessage(
        icon: Icons.error_outline,
        title: 'Кітапхананы ашу мүмкін болмады',
        description: 'Қайталап көріңіз.',
        buttonLabel: 'Қайталау',
        onPressed: _loadBooks,
      );
    }

    if (_books.isEmpty) {
      return _LibraryMessage(
        icon: Icons.picture_as_pdf_outlined,
        title: 'Жеке кітапханаңыз бос',
        description:
            'Құрылғыдан PDF таңдаңыз. Файл қосымшаның жергілікті қоймасында сақталады және біздің серверге жіберілмейді.',
        buttonLabel: _isImporting ? 'Қосылуда...' : 'PDF таңдау',
        onPressed: _isImporting ? null : _importPdf,
        showRightsNotice: true,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBooks,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 104),
        itemCount: _books.length + 1,
        separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 16 : 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const _LocalStorageNotice();
          }

          final book = _books[index - 1];
          return _PdfBookTile(
            book: book,
            onTap: () => _openBook(book),
            onDelete: () => _confirmDelete(book),
          );
        },
      ),
    );
  }
}

class _LocalStorageNotice extends StatelessWidget {
  const _LocalStorageNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, color: Color(0xFFF57F17)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'PDF файлдары қосымшаның жергілікті қоймасында сақталады және біздің серверге жіберілмейді. Қолдануға құқығыңыз бар файлдарды ғана қосыңыз.',
              style: TextStyle(height: 1.35, color: Color(0xFF5D4037)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfBookTile extends StatelessWidget {
  const _PdfBookTile({
    required this.book,
    required this.onTap,
    required this.onDelete,
  });

  final LocalPdfBook book;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFFD32F2F),
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${_formatFileSize(book.fileSize)} · ${_formatDate(book.importedAt)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_PdfBookAction>(
                tooltip: 'Әрекеттер',
                onSelected: (_) => onDelete(),
                itemBuilder: (context) => const [
                  PopupMenuItem<_PdfBookAction>(
                    value: _PdfBookAction.delete,
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Жою'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} КБ';
    }
    return '$bytes Б';
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}

enum _PdfBookAction { delete }

class _LibraryMessage extends StatelessWidget {
  const _LibraryMessage({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
    this.showRightsNotice = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final bool showRightsNotice;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3E0),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: const Color(0xFFF57F17)),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], height: 1.45),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF57F17),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(buttonLabel),
            ),
            if (showRightsNotice) ...[
              const SizedBox(height: 18),
              Text(
                'Файлды қосу арқылы оны пайдалануға құқығыңыз бар екенін растайсыз.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
