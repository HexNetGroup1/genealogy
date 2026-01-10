class Person {
  const Person({
    required this.id,
    required this.name,
    this.parentId,
    this.birthYear,
    this.deathYear,
    this.image,
    this.author,
    this.depth,
    this.path,
    this.metaStatus,
    this.locked,
    this.orderBy,
    this.childrenCount,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? parentId;
  final int? birthYear;
  final int? deathYear;
  final String? image;
  final String? author;
  final int? depth;
  final String? path;
  final String? metaStatus;
  final String? locked;
  final String? orderBy;
  final int? childrenCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Person.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString().trim().toLowerCase() ?? '';
    final rawParentId = json['parent_id']?.toString().trim().toLowerCase();
    //Treat empty string as null
    final parentId = (rawParentId != null && rawParentId.isNotEmpty) ? rawParentId : null;

    return Person(
      id: rawId,
      name: json['name'] as String? ?? 'Unknown',
      parentId: parentId,
      birthYear: json['birth_year'] as int?,
      deathYear: json['death_year'] as int?,
      image: json['image'] as String?,
      author: json['author'] as String?,
      depth: json['depth'] as int?,
      path: json['path'] as String?,
      metaStatus: json['meta_status'] as String?,
      locked: json['locked'] as String?,
      orderBy: json['orderby'] as String?,
      childrenCount: json['children_count'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  factory Person.fromMap(Map<String, dynamic> map) => Person.fromJson(map);

  String get displayName => name;

  DateTime? get birthDate {
    if (birthYear == null) return null;
    return DateTime(birthYear!);
  }

  DateTime? get deathDate {
    if (deathYear == null) return null;
    return DateTime(deathYear!);
  }

  // For backwards compatibility - treating this person as both person and "branch"
  int get branchId => int.tryParse(id) ?? 0;
}
