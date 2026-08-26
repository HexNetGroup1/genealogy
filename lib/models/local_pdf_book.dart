class LocalPdfBook {
  const LocalPdfBook({
    required this.id,
    required this.title,
    required this.storedFileName,
    required this.fileSize,
    required this.importedAt,
  });

  final String id;
  final String title;
  final String storedFileName;
  final int fileSize;
  final DateTime importedAt;

  Map<String, Object> toJson() {
    return {
      'id': id,
      'title': title,
      'storedFileName': storedFileName,
      'fileSize': fileSize,
      'importedAt': importedAt.toIso8601String(),
    };
  }

  factory LocalPdfBook.fromJson(Map<String, dynamic> json) {
    return LocalPdfBook(
      id: json['id'] as String,
      title: json['title'] as String,
      storedFileName: json['storedFileName'] as String,
      fileSize: json['fileSize'] as int,
      importedAt: DateTime.parse(json['importedAt'] as String),
    );
  }
}
