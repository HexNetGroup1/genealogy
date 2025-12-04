class JoinRequest {
  const JoinRequest({
    required this.id,
    required this.userId,
    required this.personId,
    required this.status,
    this.message,
    this.createdAt,
  });

  final int id;
  final String userId;
  final int personId;
  final String status;
  final String? message;
  final DateTime? createdAt;

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      personId: json['person_id'] as int,
      status: json['status'] as String,
      message: json['message'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
