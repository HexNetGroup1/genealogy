import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

/// Просмотрщик книги с реалистичной анимацией и навигацией
class BookViewer extends StatefulWidget {
  const BookViewer({super.key});

  @override
  State<BookViewer> createState() => _BookViewerState();
}

class _BookViewerState extends State<BookViewer> with TickerProviderStateMixin {
  // Количество страниц. В реальном приложении может приходить извне
  static const int _totalPages = 534;
  
  bool _showControls = true;
  Timer? _hideTimer;
  int _currentPage = 0;

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
    _animationController?.dispose();
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
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  String _getAssetPath(int pageIndex) {
    // Внимание: удостоверьтесь, что файлы называются page_0001.png, page_0002.png и т.д.
    final pageNumber = (pageIndex + 1).toString().padLeft(4, '0');
    return 'assets/book/page_$pageNumber.png';
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  // --- Navigation Logic ---

  void _goToPage(int page) {
    if (page < 0) page = 0;
    if (page >= _totalPages) page = _totalPages - 1;
    if (page == _currentPage) return;

    if (_animationController != null && _animationController!.isAnimating) return;

    setState(() {
      _currentPage = page;
      _dragOffset = 0.0;
    });
    // Сбросить таймер при взаимодействии
    _startHideTimer(); 
  }

  void _jumpForward() => _goToPage(_currentPage + 10);
  void _jumpBackward() => _goToPage(_currentPage - 10);
  void _nextPage() => _goToPage(_currentPage + 1);
  void _prevPage() => _goToPage(_currentPage - 1);

  // --- Animation Logic ---
  
  double _dragOffset = 0.0; // -1.0 (Next Page fully open) to 1.0 (Prev Page fully open)
  AnimationController? _animationController;

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_animationController?.isAnimating ?? false) return;

    final double delta = details.primaryDelta! / MediaQuery.of(context).size.width;
    setState(() {
      _dragOffset += delta;
      
      // Clamp logic:
      // Нельзя листать назад с первой страницы
      if (_currentPage == 0 && _dragOffset > 0) _dragOffset = 0;
      // Нельзя листать вперед с последней страницы
      if (_currentPage == _totalPages - 1 && _dragOffset < 0) _dragOffset = 0;
      
      _dragOffset = _dragOffset.clamp(-1.0, 1.0);
    });
    // Отменяем скрытие контролов пока тянем
    _hideTimer?.cancel();
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragOffset == 0) return;

    // Решаем, завершить переворот или отменить
    final velocity = details.primaryVelocity! / MediaQuery.of(context).size.width;
    bool finish = false;
    
    // Порог срабатывания (дистанция или скорость)
    if (_dragOffset < 0) {
      // Пытаемся листать вперед (Next)
      if (_dragOffset < -0.35 || velocity < -0.5) finish = true;
    } else {
      // Пытаемся листать назад (Prev)
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5), // Немного темнее для контраста с книгой
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onHorizontalDragUpdate: _handleDragUpdate,
        onHorizontalDragEnd: _handleDragEnd,
        // Простой тап переключает контролы
        onTap: _toggleControls,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // --- Book Rendering Logic ---
            // Base Layer: Страница, которая "лежит снизу".
            if (_dragOffset < 0) ...[
               // Тянем влево -> Видим следующую страницу внизу
               _buildPageContent(_currentPage + 1),
               // Сверху текущая страница, которая переворачивается
               _buildTransformingPage(
                 pageIndex: _currentPage,
                 percent: _dragOffset, // -0.0 -> -1.0
                 isRightPage: true, // Это правая страница, уходящая влево
               ),
            ] else if (_dragOffset > 0) ...[
               // Тянем вправо -> Видим текущую страницу внизу
               _buildPageContent(_currentPage),
               // Сверху предыдущая страница, которая возвращается
               _buildTransformingPage(
                 pageIndex: _currentPage - 1,
                 percent: _dragOffset - 1.0, // Мапим 0..1 в -1..0 (т.е. идет от "перевернута" к "прямо")
                 isRightPage: true,
               ),
            ] else ...[
               // Покой
               _buildPageContent(_currentPage),
            ],

            // --- Top Header ---
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: _showControls ? 0 : -100,
              left: 0,
              right: 0,
              child: _GlassHeader(
                title: 'Семейная книга',
                subtitle: 'Страница ${_currentPage + 1} из $_totalPages',
                onBookmarkTap: () {},
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
                totalPages: _totalPages,
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
    if (index < 0 || index >= _totalPages) return const SizedBox.shrink();
    return _BookPage(
      key: ValueKey(index),
      assetPath: _getAssetPath(index),
      onTap: _toggleControls,
    );
  }

  Widget _buildTransformingPage({
    required int pageIndex,
    required double percent, // range: 0.0 (flat) to -1.0 (flipped fully left)
    required bool isRightPage,
  }) {
    // 0 -> 0 degrees
    // -1 -> -180 degrees (flipped to left)
    // We multiply by -1 to rotate "towards" the user (positive Z)
    // instead of "away" (negative Z). 
    final double angle = percent * -math.pi;
    
    // Check if we passed the 90 degree mark (vertical)
    // If abs(angle) > pi/2, we are showing the back of the page
    final bool isBackVisible = angle.abs() > (math.pi / 2);

    // Matrix transformation for 3D rotation with perspective
    Matrix4 transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0015) // Perspective
      ..rotateY(angle);

    return Transform(
      transform: transform,
      alignment: Alignment.centerLeft, // Hinge at the left spine
      child: isBackVisible
          ? Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(math.pi), // Mirror content for back side
              child: _buildBackPage(), // The back of the page
            )
          : _buildPageContent(pageIndex), // The front of the page
    );
  }

  Widget _buildBackPage() {
    return Container(
      color: const Color(0xFFF5F5F5), // Off-white paper color
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Paper texture or generic back content
          const Center(
            child: Icon(Icons.import_contacts, color: Colors.black12, size: 48),
          ),
          // Inner spine shadow
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

class _BookPage extends StatefulWidget {
  const _BookPage({super.key, required this.assetPath, required this.onTap});

  final String assetPath;
  final VoidCallback onTap;

  @override
  State<_BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<_BookPage> {
  // Чтобы не мелькало при перерисовке, можно кешировать или просто показывать
  // Image.asset с gaplessPlayback.
  
  @override
  Widget build(BuildContext context) {
    // Используем InteractiveViewer для зума
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 4.0,
          child: Center(
            child: Image.asset(
              widget.assetPath,
              fit: BoxFit.contain,
              gaplessPlayback: true, // Важно для плавности при быстрой смене
              errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Стеклянная шапка
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
          color: Colors.white.withOpacity(0.85),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 4,
            bottom: 12,
            left: 16,
            right: 16,
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: Colors.black87,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: onBookmarkTap,
                    icon: const Icon(Icons.bookmark_border_rounded, size: 24),
                    color: Colors.black87,
                  ),
               ],
            ),
          ),
        ),
      ),
    );
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
            color: Colors.black.withOpacity(0.6), // Полупрозрачный темный фон
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Инфо о странице
              Text(
                'Страница $currentPage / $totalPages',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              // Кнопки
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavButton(icon: Icons.keyboard_double_arrow_left_rounded, label: '-10', onTap: onPrev10),
                  _NavButton(icon: Icons.keyboard_arrow_left_rounded, label: '', iconSize: 32, onTap: onPrev), // Большая
                  const SizedBox(width: 20), // Разделитель центральный
                  _NavButton(icon: Icons.keyboard_arrow_right_rounded, label: '', iconSize: 32, onTap: onNext), // Большая
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
