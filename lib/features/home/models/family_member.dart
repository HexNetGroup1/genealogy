class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.fullName,
    required this.lifeSpan,
    required this.story,
    required this.role,
    this.childrenIds = const [],
    this.highlights = const [],
  });

  final String id;
  final String fullName;
  final String lifeSpan;
  final String story;
  final String role;
  final List<String> childrenIds;
  final List<String> highlights;

  bool get hasChildren => childrenIds.isNotEmpty;

  FamilyMember copyWith({
    String? id,
    String? fullName,
    String? lifeSpan,
    String? story,
    String? role,
    List<String>? childrenIds,
    List<String>? highlights,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      lifeSpan: lifeSpan ?? this.lifeSpan,
      story: story ?? this.story,
      role: role ?? this.role,
      childrenIds: childrenIds ?? this.childrenIds,
      highlights: highlights ?? this.highlights,
    );
  }
}
