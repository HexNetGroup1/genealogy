import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui';

/// Просмотрщик книги с простым свайпом
class BookViewer extends StatefulWidget {
  const BookViewer({super.key});

  @override
  State<BookViewer> createState() => _BookViewerState();
}

class _BookViewerState extends State<BookViewer> with TickerProviderStateMixin {
  // final _pageController = PageController(); // Removed
  static const int _totalPages = 534;
  bool _showControls = true;
  Timer? _hideTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _animationController?.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EFEF),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onHorizontalDragUpdate: _handleDragUpdate,
        onHorizontalDragEnd: _handleDragEnd,
        // Block swipes during animation to keep it simple, or handle interruptions
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Base Layer (The page underneath)
            // If dragging LEFT (showing next page): Base is _currentPage + 1
            // If dragging RIGHT (showing prev page): Base is _currentPage
            // If idle: Base is _currentPage
            if (_dragOffset < 0) ...[
               // Dragging Left -> Next Page is bottom
               _buildPageContent(_currentPage + 1),
               // Active Page (Current) is Top and flipping away
               _buildTransformingPage(
                 pageIndex: _currentPage,
                 percent: _dragOffset, // -0.0 to -1.0
                 isRightPage: true, // It is the page on the "Right" (visible) stack
               ),
            ] else if (_dragOffset > 0) ...[
               // Dragging Right -> Current Page is bottom
               _buildPageContent(_currentPage),
               // Prev Page is Top and flipping in
               _buildTransformingPage(
                 pageIndex: _currentPage - 1,
                 percent: _dragOffset - 1.0, // Maps 0..1 to -1..0 (logic: -1 is open, 0 is closed)
                 // Wait.
                 // Ideally: 
                 // Prev page starts at -90deg (or -180).
                 // We drag it to 0.
                 // My percent logic: 0 is flat. 
                 // Let's standardize:
                 // 0 = Flat Visible.
                 // -1 = Flipped Left (Invisible/Vertical).
                 
                 // Drag Right (0 -> 1):
                 // We want Prev Page to go from -1 (Left/Vertical) to 0 (Flat).
                 // So we pass ( _dragOffset - 1.0 ) which goes from -1.0 to 0.0.
                 isRightPage: true, 
               ),
            ] else ...[
               // Idle
               _buildPageContent(_currentPage),
            ],

            // Header
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
          ],
        ),
      ),
    );
  }

  // --- Logic ---
  double _dragOffset = 0.0; // -1.0 to 1.0
  AnimationController? _animationController;

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_animationController?.isAnimating ?? false) return;

    final double delta = details.primaryDelta! / MediaQuery.of(context).size.width;
    setState(() {
      _dragOffset += delta;
      // Clamp logic:
      // Can't go Prev if page 0.
      if (_currentPage == 0 && _dragOffset > 0) _dragOffset = 0;
      // Can't go Next if page max.
      if (_currentPage == _totalPages - 1 && _dragOffset < 0) _dragOffset = 0;
      
      _dragOffset = _dragOffset.clamp(-1.0, 1.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragOffset == 0) return;

    // Decide whether to finish flip or cancel
    // Threshold 0.3 or velocity
    final velocity = details.primaryVelocity! / MediaQuery.of(context).size.width;
    bool finish = false;
    
    if (_dragOffset < 0) {
      // Trying to go Next
      if (_dragOffset < -0.3 || velocity < -0.5) finish = true;
    } else {
      // Trying to go Prev
      if (_dragOffset > 0.3 || velocity > 0.5) finish = true;
    }

    double target = finish ? (_dragOffset < 0 ? -1.0 : 1.0) : 0.0;
    
    _animationController = AnimationController(
       vsync: this, 
       duration: const Duration(milliseconds: 300)
    );
    
    final animation = Tween<double>(begin: _dragOffset, end: target).animate(
       CurvedAnimation(parent: _animationController!, curve: Curves.easeOut)
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
    required double percent, // 0.0 to -1.0
    required bool isRightPage,
  }) {
    // Rotation: 0 to -90 degrees
    // We map 0..-1 to 0..-pi/2
    final double angle = percent * 1.5708; 
    
    // Shadow opacity
    // 0 -> 0
    // -1 -> 0.5 (Darkest when vertical)
    final double shadowOpacity = (percent.abs() * 0.5).clamp(0.0, 0.5);

    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // perspective
        ..rotateY(angle),
      alignment: Alignment.centerLeft, // Spine
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildPageContent(pageIndex),
          // Gradient Shadow overlay
           IgnorePointer(
             child: Container(
               decoration: BoxDecoration(
                 gradient: LinearGradient(
                   begin: Alignment.centerRight,
                   end: Alignment.centerLeft,
                   colors: [
                     Colors.black.withOpacity(0.0),
                     Colors.black.withOpacity(shadowOpacity),
                   ],
                   stops: const [0.5, 1.0],
                 ),
               ),
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
          color: Colors.white.withAlpha(200),
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

/// Виджет страницы книги с автоопределением ориентации
class _BookPage extends StatefulWidget {
  const _BookPage({super.key, required this.assetPath, required this.onTap});

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
              quarterTurns: isHorizontal ? -1 : 0,
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
