/// Модель книги для загрузки с GitHub
class Book {
  final String id;
  final String title;
  final String description;
  final int pageCount;
  final String baseUrl;
  final String thumbnailUrl;

  const Book({
    required this.id,
    required this.title,
    required this.description,
    required this.pageCount,
    required this.baseUrl,
    required this.thumbnailUrl,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      pageCount: json['pageCount'] as int,
      baseUrl: json['baseUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
    );
  }

  /// Получить URL страницы по индексу (0-based)
  String getPageUrl(int pageIndex) {
    final pageNumber = (pageIndex + 1).toString().padLeft(4, '0');
    return '$baseUrl/page_$pageNumber.png';
  }
}
