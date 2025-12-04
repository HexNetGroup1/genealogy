class Branch {
  const Branch({
    required this.id,
    this.parentId,
    required this.name,
    required this.type,
    this.description,
    this.iconUrl,
    this.orderIndex,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int? parentId;
  final String name;
  final String type;
  final String? description;
  final String? iconUrl;
  final int? orderIndex;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as int,
      parentId: json['parent_id'] as int?,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : 'Без названия',
      type: (json['type'] as String?)?.trim().isNotEmpty == true
          ? (json['type'] as String).trim()
          : 'unknown',
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      orderIndex: json['order_index'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  factory Branch.fromMap(Map<String, dynamic> map) => Branch.fromJson(map);
}
