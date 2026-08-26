import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../models/local_pdf_book.dart';
import '../../../models/shared_pdf_book.dart';
import '../../../services/local_pdf_library_service.dart';
import '../../../services/shared_pdf_library_service.dart';
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

  final _localLibrary = LocalPdfLibraryService.instance;
  final _sharedLibrary = SharedPdfLibraryService.instance;

  List<LocalPdfBook> _localBooks = [];
  List<SharedPdfBook> _sharedBooks = [];
  bool _isLoading = true;
  bool _isImporting = false;
  String? _openingSharedBookId;
  Object? _localError;
  Object? _sharedError;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _localError = null;
      _sharedError = null;
    });

    var localBooks = <LocalPdfBook>[];
    var sharedBooks = <SharedPdfBook>[];
    Object? localError;
    Object? sharedError;

    await Future.wait([
      () async {
        try {
          localBooks = await _localLibrary.getBooks();
        } catch (error) {
          localError = error;
        }
      }(),
      () async {
        try {
          sharedBooks = await _sharedLibrary.getBooks();
        } catch (error) {
          sharedError = error;
        }
      }(),
    ]);

    if (!mounted) return;
    setState(() {
      _localBooks = localBooks;
      _sharedBooks = sharedBooks;
      _localError = localError;
      _sharedError = sharedError;
      _isLoading = false;
    });
  }

  Future<void> _importPdf() async {
    if (_isImporting) return;

    setState(() => _isImporting = true);
    try {
      final selectedFile = await openFile(
        acceptedTypeGroups: const [_pdfTypeGroup],
      );
      if (selectedFile == null) return;

      final book = await _localLibrary.importPdf(selectedFile);
      if (!mounted) return;
      setState(() => _localBooks = [book, ..._localBooks]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('«${book.title}» жеке кітапханаға қосылды.')),
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (_) {
      if (!mounted) return;
      _showError('PDF файлын қосу мүмкін болмады.');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _openLocalBook(LocalPdfBook book) async {
    final filePath = await _localLibrary.getBookPath(book);
    if (!mounted) return;
    await _openViewer(book.title, filePath);
  }

  Future<void> _openSharedBook(SharedPdfBook book) async {
    if (_openingSharedBookId != null) return;
    setState(() => _openingSharedBookId = book.id);

    try {
      final filePath = await _sharedLibrary.getCachedBookPath(book);
      if (!mounted) return;
      await _openViewer(book.title, filePath);
    } on FormatException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) _showError('Кітапты серверден жүктеу мүмкін болмады.');
    } finally {
      if (mounted) setState(() => _openingSharedBookId = null);
    }
  }

  Future<void> _openViewer(String title, String filePath) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            LocalPdfViewerScreen(title: title, filePath: filePath),
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
      await _localLibrary.deleteBook(book);
      if (!mounted) return;
      setState(() => _localBooks.removeWhere((item) => item.id == book.id));
    } catch (_) {
      if (!mounted) return;
      _showError('PDF файлын жою мүмкін болмады.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      floatingActionButton: _localBooks.isEmpty && _sharedBooks.isEmpty
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
              label: const Text('Жеке PDF қосу'),
            ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasBooks = _localBooks.isNotEmpty || _sharedBooks.isNotEmpty;
    if (!hasBooks && _localError != null && _sharedError != null) {
      return _LibraryMessage(
        icon: Icons.error_outline,
        title: 'Кітапхананы ашу мүмкін болмады',
        description: 'Интернет байланысын тексеріп, қайталап көріңіз.',
        buttonLabel: 'Қайталау',
        onPressed: _loadBooks,
      );
    }

    if (!hasBooks) {
      return _LibraryMessage(
        icon: Icons.menu_book_outlined,
        title: 'Кітапхана әзірге бос',
        description: _sharedError == null
            ? 'Серверде ортақ кітаптар жоқ. Қаласаңыз, құрылғыдан жеке PDF қоса аласыз.'
            : 'Ортақ кітаптарды жүктеу мүмкін болмады. Қаласаңыз, құрылғыдан жеке PDF қоса аласыз.',
        buttonLabel: _isImporting ? 'Қосылуда...' : 'Жеке PDF таңдау',
        onPressed: _isImporting ? null : _importPdf,
        showRightsNotice: true,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBooks,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 104),
        children: [
          if (_sharedError != null) ...[
            _LoadWarning(onRetry: _loadBooks),
            const SizedBox(height: 18),
          ],
          if (_sharedBooks.isNotEmpty) ...[
            const _SectionHeading(
              icon: Icons.cloud_outlined,
              title: 'Ортақ кітаптар',
              subtitle: 'Барлық пайдаланушыларға қолжетімді',
            ),
            const SizedBox(height: 10),
            ..._sharedBooks.map(
              (book) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PdfBookTile(
                  title: book.title,
                  subtitle: book.description,
                  fileSize: book.fileSize,
                  date: book.createdAt,
                  isShared: true,
                  isOpening: _openingSharedBookId == book.id,
                  onTap: () => _openSharedBook(book),
                ),
              ),
            ),
          ],
          if (_localBooks.isNotEmpty) ...[
            if (_sharedBooks.isNotEmpty) const SizedBox(height: 12),
            const _SectionHeading(
              icon: Icons.phone_android_outlined,
              title: 'Жеке кітаптар',
              subtitle: 'Тек осы құрылғыда сақталады',
            ),
            const SizedBox(height: 10),
            const _LocalStorageNotice(),
            const SizedBox(height: 10),
            ..._localBooks.map(
              (book) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PdfBookTile(
                  title: book.title,
                  fileSize: book.fileSize,
                  date: book.importedAt,
                  onTap: () => _openLocalBook(book),
                  onDelete: () => _confirmDelete(book),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 21, color: const Color(0xFFF57F17)),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadWarning extends StatelessWidget {
  const _LoadWarning({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 8, 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: Color(0xFFF57F17)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Ортақ кітаптарды жүктеу мүмкін болмады.'),
          ),
          TextButton(onPressed: onRetry, child: const Text('Қайталау')),
        ],
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
              'Жеке PDF файлдары серверге жіберілмейді. Қолдануға құқығыңыз бар файлдарды ғана қосыңыз.',
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
    required this.title,
    required this.fileSize,
    required this.date,
    required this.onTap,
    this.subtitle,
    this.onDelete,
    this.isShared = false,
    this.isOpening = false,
  });

  final String title;
  final String? subtitle;
  final int fileSize;
  final DateTime date;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isShared;
  final bool isOpening;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isOpening ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 64,
                decoration: BoxDecoration(
                  color: isShared
                      ? const Color(0xFFFFF3E0)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isShared
                      ? Icons.menu_book_rounded
                      : Icons.picture_as_pdf_rounded,
                  color: isShared
                      ? const Color(0xFFF57F17)
                      : const Color(0xFFD32F2F),
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Text(
                      '${_formatFileSize(fileSize)} · ${_formatDate(date)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isOpening)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (onDelete != null)
                PopupMenuButton<_PdfBookAction>(
                  tooltip: 'Әрекеттер',
                  onSelected: (_) => onDelete!(),
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
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.chevron_right_rounded, color: Colors.grey),
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
