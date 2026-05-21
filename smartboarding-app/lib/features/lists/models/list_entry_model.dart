class ListEntryModel {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String createdAt;

  const ListEntryModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.createdAt,
  });

  factory ListEntryModel.fromJson(Map<String, dynamic> json) {
    return ListEntryModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}
