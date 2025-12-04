class Person {
  const Person({
    required this.id,
    required this.branchId,
    this.firstName,
    this.lastName,
    this.middleName,
    this.birthDate,
    this.deathDate,
    this.photo,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int branchId;
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? photo;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as int,
      branchId: json['branch_id'] as int,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      middleName: json['middle_name'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.tryParse(json['birth_date'] as String)
          : null,
      deathDate: json['death_date'] != null
          ? DateTime.tryParse(json['death_date'] as String)
          : null,
      photo: json['photo'] as String?,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  factory Person.fromMap(Map<String, dynamic> map) => Person.fromJson(map);

  String get fullName {
    final parts = [
      lastName,
      firstName,
      middleName,
    ]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    return parts.isEmpty ? 'Person #$id' : parts.join(' ');
  }

  String get displayName => fullName;
}
