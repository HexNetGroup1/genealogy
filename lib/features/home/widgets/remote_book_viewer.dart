import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/book.dart';
import '../../../services/book_service.dart';
import 'unified_header.dart';

/// Просмотрщик книги с реалистичной анимацией и навигацией
/// Загружает страницы с GitHub и кэширует локально
class RemoteBookViewer extends StatefulWidget {
  final Book book;
  
  const RemoteBookViewer({super.key, required this.book});

  @override
  State<RemoteBookViewer> createState() => _RemoteBookViewerState();
}

class _RemoteBookViewerState extends State<RemoteBookViewer> with TickerProviderStateMixin {
  final BookService _bookService = BookService.instance;
  
  bool _showControls = true;
  Timer? _hideTimer;
  int _currentPage = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
    _preloadInitialPages();
  }

  Future<void> _preloadInitialPages() async {
    setState(() => _isLoading = true);
    try {
      // Предзагрузить первые страницы
      await _bookService.preloadPages(widget.book, 0, ahead: 5, behind: 0);
    } catch (e) {
      debugPrint('Error preloading pages: $e');
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  // --- Navigation Logic ---

  void _goToPage(int page) {
    if (page < 0) page = 0;
    if (page >= widget.book.pageCount) page = widget.book.pageCount - 1;
    if (page == _currentPage) return;

    if (_animationController != null && _animationController!.isAnimating) return;

    setState(() {
      _currentPage = page;
      _dragOffset = 0.0;
    });
    
    // Предзагрузить страницы вокруг текущей
    _bookService.preloadPages(widget.book, page).catchError((_) {});
    
    _startHideTimer(); 
  }

  void _jumpForward() => _goToPage(_currentPage + 10);
  void _jumpBackward() => _goToPage(_currentPage - 10);
  void _nextPage() => _goToPage(_currentPage + 1);
  void _prevPage() => _goToPage(_currentPage - 1);

  // --- Animation Logic ---
  
  double _dragOffset = 0.0;
  AnimationController? _animationController;

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_animationController?.isAnimating ?? false) return;

    final double delta = details.primaryDelta! / MediaQuery.of(context).size.width;
    setState(() {
      _dragOffset += delta;
      
      if (_currentPage == 0 && _dragOffset > 0) _dragOffset = 0;
      if (_currentPage == widget.book.pageCount - 1 && _dragOffset < 0) _dragOffset = 0;
      
      _dragOffset = _dragOffset.clamp(-1.0, 1.0);
    });
    _hideTimer?.cancel();
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragOffset == 0) return;

    final velocity = details.primaryVelocity! / MediaQuery.of(context).size.width;
    bool finish = false;
    
    if (_dragOffset < 0) {
      if (_dragOffset < -0.35 || velocity < -0.5) finish = true;
    } else {
      if (_dragOffset > 0.35 || velocity > 0.5) finish = true;
    }

    double target = finish ? (_dragOffset < 0 ? -1.0 : 1.0) : 0.0;
    
    _animationController = AnimationController(
       vsync: this, 
       duration: const Duration(milliseconds: 350)
    );
    
    final animation = Tween<double>(begin: _dragOffset, end: target).animate(
       CurvedAnimation(parent: _animationController!, curve: Curves.easeOutCubic)
    );

    animation.addListener(() {
      setState(() {
        _dragOffset = animation.value;
      });
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (target == -1.0) {
           _finishChangePage(_currentPage + 1);
        } else if (target == 1.0) {
           _finishChangePage(_currentPage - 1);
        } else {
           setState(() => _dragOffset = 0.0);
        }
        _animationController?.dispose();
        _animationController = null;
        _startHideTimer();
      }
    });

    _animationController!.forward();
  }

  void _finishChangePage(int newPage) {
    setState(() {
      _currentPage = newPage;
      _dragOffset = 0.0;
    });
    // Предзагрузить страницы вокруг новой
    _bookService.preloadPages(widget.book, newPage).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      extendBodyBehindAppBar: true,
      body: _isLoading 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Загрузка книги...'),
              ],
            ),
          )
        : GestureDetector(
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            onTap: _toggleControls,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_dragOffset < 0) ...[
                   _buildPageContent(_currentPage + 1),
                   _buildTransformingPage(
                     pageIndex: _currentPage,
                     percent: _dragOffset,
                     isRightPage: true,
                   ),
                ] else if (_dragOffset > 0) ...[
                   _buildPageContent(_currentPage),
                   _buildTransformingPage(
                     pageIndex: _currentPage - 1,
                     percent: _dragOffset - 1.0,
                     isRightPage: true,
                   ),
                ] else ...[
                   _buildPageContent(_currentPage),
                ],

                // --- Top Header ---
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: _showControls ? 0 : -100,
                  left: 0,
                  right: 0,
                  child: UnifiedHeader(
                    title: widget.book.title,
                    subtitle: 'Страница ${_currentPage + 1} из ${widget.book.pageCount}',
                    showBackButton: true,
                    actions: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.bookmark_border_rounded, size: 24),
                        color: Colors.black87,
                      ),
                    ],
                  ),
                ),

                // --- Bottom Controls ---
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  bottom: _showControls ? 20 : -120,
                  left: 20,
                  right: 20,
                  child: _GlassControls(
                    currentPage: _currentPage + 1,
                    totalPages: widget.book.pageCount,
                    onPrev10: _jumpBackward,
                    onPrev: _prevPage,
                    onNext: _nextPage,
                    onNext10: _jumpForward,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildPageContent(int index) {
    if (index < 0 || index >= widget.book.pageCount) return const SizedBox.shrink();
    return _RemoteBookPage(
      key: ValueKey('${widget.book.id}_$index'),
      book: widget.book,
      pageIndex: index,
      onTap: _toggleControls,
    );
  }

  Widget _buildTransformingPage({
    required int pageIndex,
    required double percent,
    required bool isRightPage,
  }) {
    final double angle = percent * -math.pi;
    final bool isBackVisible = angle.abs() > (math.pi / 2);

    Matrix4 transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0015)
      ..rotateY(angle);

    return Transform(
      transform: transform,
      alignment: Alignment.centerLeft,
      child: isBackVisible
          ? Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(math.pi),
              child: _buildBackPage(),
            )
          : _buildPageContent(pageIndex),
    );
  }

  Widget _buildBackPage() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Center(
            child: Icon(Icons.import_contacts, color: Colors.black12, size: 48),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Страница книги с загрузкой из сети/кэша
class _RemoteBookPage extends StatefulWidget {
  const _RemoteBookPage({
    super.key,
    required this.book,
    required this.pageIndex,
    required this.onTap,
  });

  final Book book;
  final int pageIndex;
  final VoidCallback onTap;

  @override
  State<_RemoteBookPage> createState() => _RemoteBookPageState();
}

class _RemoteBookPageState extends State<_RemoteBookPage> {
  final BookService _bookService = BookService.instance;
  String? _localPath;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  @override
  void didUpdateWidget(_RemoteBookPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageIndex != widget.pageIndex || oldWidget.book.id != widget.book.id) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final file = await _bookService.downloadPage(widget.book, widget.pageIndex);
      if (mounted) {
        setState(() {
          _localPath = file.path;
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadPage,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_localPath != null) {
      return InteractiveViewer(
        minScale: 1.0,
        maxScale: 4.0,
        child: Center(
          child: Image.file(
            File(_localPath!),
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) =>
                const Center(child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey)),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}


/// Панель навигации снизу
class _GlassControls extends StatelessWidget {
  const _GlassControls({
    required this.currentPage,
    required this.totalPages,
    required this.onPrev10,
    required this.onPrev,
    required this.onNext,
    required this.onNext10,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback onPrev10;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onNext10;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Страница $currentPage / $totalPages',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavButton(icon: Icons.keyboard_double_arrow_left_rounded, label: '-10', onTap: onPrev10),
                  _NavButton(icon: Icons.keyboard_arrow_left_rounded, label: '', iconSize: 32, onTap: onPrev),
                  const SizedBox(width: 20),
                  _NavButton(icon: Icons.keyboard_arrow_right_rounded, label: '', iconSize: 32, onTap: onNext),
                  _NavButton(icon: Icons.keyboard_double_arrow_right_rounded, label: '+10', onTap: onNext10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double iconSize;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: iconSize),
            if (label.isNotEmpty)
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }
}
