class Profile {
  const Profile({
    required this.id,
    this.fullName,
    this.personId,
    this.createdAt,
  });

  final String id;
  final String? fullName;
  final int? personId;
  final DateTime? createdAt;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      personId: json['person_id'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
