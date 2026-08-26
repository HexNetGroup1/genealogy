class SharedPdfBook {
  const SharedPdfBook({
    required this.id,
    required this.title,
    required this.storagePath,
    required this.originalFilename,
    required this.fileSize,
    required this.createdAt,
    this.description,
  });

  final String id;
  final String title;
  final String? description;
  final String storagePath;
  final String originalFilename;
  final int fileSize;
  final DateTime createdAt;

  factory SharedPdfBook.fromJson(Map<String, dynamic> json) {
    return SharedPdfBook(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      storagePath: json['storage_path'] as String,
      originalFilename: json['original_filename'] as String,
      fileSize: json['file_size'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
