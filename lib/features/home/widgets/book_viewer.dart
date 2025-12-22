import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

/// Просмотрщик книги с 3D анимацией перелистывания.
class BookViewer extends StatefulWidget {
  const BookViewer({super.key});

  @override
  State<BookViewer> createState() => _BookViewerState();
}

class _BookViewerState extends State<BookViewer> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 534;
  bool _showControls = true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _previousPage() => _goToPage(_currentPage - 1);
  void _nextPage() => _goToPage(_currentPage + 1);

  String _getAssetPath(int pageIndex) {
    final pageNumber = (pageIndex + 1).toString().padLeft(4, '0');
    return 'assets/book/page_$pageNumber.png';
  }

  void _toggleControls() => setState(() => _showControls = !_showControls);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EFEF),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Книга (Swipe only)
          GestureDetector(
            onTap: _toggleControls,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _totalPages,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemBuilder: (context, index) {
                // Возвращаем стиль книги, но без 3D вращения (прямые страницы)
                // Используем стандартный слайд PageView
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(
                    child: Hero(
                      tag: 'book_page_$index',
                      child: Container(
                        // Убраны отступы и тени для полного экрана
                        margin: EdgeInsets.zero,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                        child: Image.asset(
                          _getAssetPath(index),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey)),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Верхняя панель (Header) - оставляем для информации
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: _GlassHeader(
              title: 'Семейная книга',
              subtitle: 'Страница ${_currentPage + 1} из $_totalPages',
            ),
          ),
          
          // Нижняя панель удалена по запросу.
          // Листание только через Swipe (руками).
        ],
      ),
    );
  }
}

class _GlassHeader extends StatelessWidget {
  const _GlassHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.white.withAlpha(200),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            bottom: 15,
            left: 20,
            right: 20,
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
                // Заголовок
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
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
