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
  bool _showControls = true;

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
          // 1. Книга с эффектом перелистывания
          GestureDetector(
            onTap: _toggleControls,
            child: PageFlipWidget(
              key: _controller,
              backgroundColor: const Color(0xFFF0EFEF),
              isRightSwipe: false,
              lastPage: Container(
                color: Colors.white, 
                child: const Center(child: Text('Конец книги', style: TextStyle(fontSize: 20))),
              ),
              children: <Widget>[
                for (var i = 0; i < _totalPages; i++)
                  Container(
                    color: Colors.white,
                    child: Center(
                      child: Image.asset(
                        _getAssetPath(i),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey)),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 2. Верхняя панель (Header)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: const _GlassHeader(
              title: 'Семейная книга',
              subtitle: 'Том 1',
            ),
          ),
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
