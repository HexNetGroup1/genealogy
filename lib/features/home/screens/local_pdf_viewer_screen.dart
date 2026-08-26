import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

class LocalPdfViewerScreen extends StatefulWidget {
  const LocalPdfViewerScreen({
    super.key,
    required this.title,
    required this.filePath,
  });

  final String title;
  final String filePath;

  @override
  State<LocalPdfViewerScreen> createState() => _LocalPdfViewerScreenState();
}

class _LocalPdfViewerScreenState extends State<LocalPdfViewerScreen> {
  late final PdfDocumentRef _documentRef;
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _documentRef = PdfDocumentRefFile(widget.filePath);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page, int pageCount) {
    final targetPage = page.clamp(0, pageCount - 1);
    if (targetPage == _currentPage || !_pageController.hasClients) return;

    _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _showPageDialog(int pageCount) async {
    final selectedPage = await showDialog<int>(
      context: context,
      builder: (_) => _PageNumberDialog(
        initialPage: _currentPage + 1,
        pageCount: pageCount,
      ),
    );

    if (selectedPage != null && mounted) {
      _goToPage(selectedPage, pageCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        surfaceTintColor: Colors.white,
      ),
      body: PdfDocumentViewBuilder(
        documentRef: _documentRef,
        loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.broken_image_outlined,
                  size: 52,
                  color: Colors.grey,
                ),
                const SizedBox(height: 12),
                Text(
                  'PDF файлын ашу мүмкін болмады.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        builder: (context, document) {
          if (document == null || document.pages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final pageCount = document.pages.length;
          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const PageScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  itemCount: pageCount,
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: PdfPageView(
                      key: ValueKey(index),
                      document: document,
                      pageNumber: index + 1,
                      alignment: Alignment.center,
                      backgroundColor: const Color(0xFFE5E5E5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: _BookNavigationBar(
                  currentPage: _currentPage,
                  pageCount: pageCount,
                  onPrevious: _currentPage == 0
                      ? null
                      : () => _goToPage(_currentPage - 1, pageCount),
                  onNext: _currentPage == pageCount - 1
                      ? null
                      : () => _goToPage(_currentPage + 1, pageCount),
                  onPageTap: () => _showPageDialog(pageCount),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PageNumberDialog extends StatefulWidget {
  const _PageNumberDialog({required this.initialPage, required this.pageCount});

  final int initialPage;
  final int pageCount;

  @override
  State<_PageNumberDialog> createState() => _PageNumberDialogState();
}

class _PageNumberDialogState extends State<_PageNumberDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initialPage}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final page = int.tryParse(_controller.text);
    if (page != null && page >= 1 && page <= widget.pageCount) {
      Navigator.of(context).pop(page - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Бетке өту'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(hintText: '1–${widget.pageCount}'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Болдырмау'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Өту')),
      ],
    );
  }
}

class _BookNavigationBar extends StatelessWidget {
  const _BookNavigationBar({
    required this.currentPage,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
    required this.onPageTap,
  });

  final int currentPage;
  final int pageCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onPageTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            tooltip: 'Алдыңғы бет',
            icon: const Icon(Icons.chevron_left_rounded, size: 34),
          ),
          Expanded(
            child: InkWell(
              onTap: onPageTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Бет ${currentPage + 1} / $pageCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            tooltip: 'Келесі бет',
            icon: const Icon(Icons.chevron_right_rounded, size: 34),
          ),
        ],
      ),
    );
  }
}
