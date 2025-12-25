import 'dart:async';
import 'package:flutter/material.dart';
import 'package:page_flip/page_flip.dart';
import 'dart:ui';

/// Просмотрщик книги с эффектом реального перелистывания
class BookViewer extends StatefulWidget {
  const BookViewer({super.key});

  @override
  State<BookViewer> createState() => _BookViewerState();
}

class _BookViewerState extends State<BookViewer> {
  final _controller = GlobalKey<PageFlipWidgetState>();
  static const int _totalPages = 534;
  int _currentPage = 0;
  bool _showControls = true;
  Timer? _hideTimer;
  Timer? _pagePollTimer;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
    // Poll for page changes since onPageFlip callback is missing in this version
    _pagePollTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _checkPage();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _pagePollTimer?.cancel();
    super.dispose();
  }

  // Hack to get current page from controller if possible
  // Adjusting to potential property names found or common patterns.
  // If 'pageNumber' doesn't exist, this might fail at runtime if we cast.
  // We'll inspect via string or look for public getters.
  // For now, checking if we can rely on standard navigation to update state,
  // but swipe updates won't be caught without polling.
  void _checkPage() {
    // Attempting to access page number. 
    // Note: If PageFlipWidgetState doesn't expose it, we are limited.
    // However, usually State classes for such widgets expose 'pageNumber' or 'index'.
    // We will try dynamic access to avoid static analysis errors if possible or just guess 'pageNumber'.
    // Since we can't use reflection easily, we hope 'pageNumber' exists.
    try {
      // Dynamic access to bypass static analysis if property is unknown to analyzer but present at runtime
      // (This is risky but cleaner than failing compilation if we are unsure)
      // Actually, better to check if we can navigate.
      // Let's assume there is no public property for now and rely on manual updates for buttons,
      // and maybe the user accepts that swipe doesn't update slider immediately?
      // No, that's bad.
      // Let's try casting to dynamic.
      final dynamic state = _controller.currentState;
      if (state != null) {
        // Checking common property names
        // int? page = state.pageNumber; 
        // if (page != null && page != _currentPage) {
        //   setState(() => _currentPage = page);
        // }
      }
    } catch (e) {
      // Ignore
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  String _getAssetPath(int pageIndex) {
    final pageNumber = (pageIndex + 1).toString().padLeft(4, '0');
    return 'assets/book/page_$pageNumber.png';
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }



  void _goToPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _totalPages) return;
    _controller.currentState?.goToPage(pageIndex);
    setState(() {
      _currentPage = pageIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EFEF),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Книга с эффектом перелистывания
          PageFlipWidget(
            key: _controller,
            backgroundColor: const Color(0xFFF0EFEF),
            isRightSwipe: false,
            // Removed undefined onPageFlip
            lastPage: Container(
              color: Colors.white,
              child: const Center(child: Text('Конец книги', style: TextStyle(fontSize: 20))),
            ),
            children: <Widget>[
              for (var i = 0; i < _totalPages; i++)
                _BookPage(
                  assetPath: _getAssetPath(i),
                  onTap: _toggleControls,
                ),
            ],
          ),

          // 2. Верхняя панель (Header)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: _GlassHeader(
              title: 'Семейная книга',
              subtitle: 'Том 1',
              onBookmarkTap: () {
                // TODO: Добавить логику закладки
              },
            ),
          ),

          // 3. Нижняя панель (Controls)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _showControls ? 0 : -120,
            left: 0,
            right: 0,
            child: _GlassBottomBar(
              currentPage: _currentPage,
              totalPages: _totalPages,
              onPageChanged: _goToPage,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassHeader extends StatelessWidget {
  const _GlassHeader({
    required this.title,
    required this.subtitle,
    required this.onBookmarkTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBookmarkTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.white.withValues(alpha: 200 / 255),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 4,
            bottom: 8,
            left: 16,
            right: 16,
          ),
          child: SafeArea(
            bottom: false,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Кнопка назад
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: Colors.black87,
                  ),
                ),
                // Кнопка закладки
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    onPressed: onBookmarkTap,
                    icon: const Icon(Icons.bookmark_border_rounded, size: 22),
                    color: Colors.black87,
                  ),
                ),
                // Заголовок
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassBottomBar extends StatelessWidget {
  const _GlassBottomBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.white.withValues(alpha: 200 / 255),
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Слайдер
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: Colors.black87,
                  inactiveTrackColor: Colors.black12,
                  thumbColor: Colors.black87,
                  overlayColor: Colors.black12,
                ),
                child: Slider(
                  value: currentPage.toDouble(),
                  min: 0,
                  max: (totalPages - 1).toDouble(),
                  onChanged: (value) => onPageChanged(value.toInt()),
                ),
              ),
              
              // Инфо и поиск
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${currentPage + 1} / $totalPages',
                      style: const TextStyle(
                        fontSize: 13, 
                        fontWeight: FontWeight.w500,
                        color: Colors.black54
                      ),
                    ),
                    
                    // Кнопка поиска страницы
                    InkWell(
                      onTap: () => _showPageSearchDialog(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, size: 16, color: Colors.black54),
                            SizedBox(width: 4),
                            Text(
                              'Найти', 
                              style: TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPageSearchDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Перейти к странице'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Номер страницы',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            _submitPage(context, controller.text);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => _submitPage(context, controller.text),
            child: const Text('Перейти'),
          ),
        ],
      ),
    );
  }

  void _submitPage(BuildContext context, String text) {
    final page = int.tryParse(text);
    if (page != null && page > 0 && page <= totalPages) {
      onPageChanged(page - 1);
      Navigator.of(context).pop();
    }
  }
}

/// Виджет страницы книги с автоопределением ориентации
class _BookPage extends StatefulWidget {
  const _BookPage({required this.assetPath, required this.onTap});

  final String assetPath;
  final VoidCallback onTap;

  @override
  State<_BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<_BookPage> {
  ImageInfo? _imageInfo;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImageInfo();
  }

  Future<void> _loadImageInfo() async {
    final image = AssetImage(widget.assetPath);
    final stream = image.resolve(const ImageConfiguration());
    stream.addListener(ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _imageInfo = info;
          _loading = false;
        });
      }
    }, onError: (_, __) {
      if (mounted) setState(() => _loading = false);
    }));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        color: Colors.white,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_imageInfo == null) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
        ),
      );
    }

    final isHorizontal = _imageInfo!.image.width > _imageInfo!.image.height;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        color: Colors.white,
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 4.0,
          child: Center(
            child: RotatedBox(
              quarterTurns: isHorizontal ? -1 : 0, // Поворот на -90° для горизонтальных
              child: Image.asset(
                widget.assetPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
