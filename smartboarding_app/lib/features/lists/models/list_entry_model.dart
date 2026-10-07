class ListEntry {
  final String id;
  final String userId;
  final String fullName;

  final String? email;
  final String? tripType;
  final String createdAt;
  final String? institutionName;

  final bool addedByAdmin;

  const ListEntry({
    required this.id,
    required this.userId,
    required this.fullName,
    this.email,
    this.tripType,
    required this.createdAt,
    this.institutionName,
    this.addedByAdmin = false,
  });

  factory ListEntry.fromJson(Map<String, dynamic> json) {
    return ListEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String?,
      tripType: json['tripType'] as String?,
      createdAt: json['createdAt'] as String,
      institutionName: json['institutionName'] as String?,
      addedByAdmin: json['addedByAdmin'] as bool? ?? false,
    );
  }
}
