class ListEntry {
  final String id;
  final String userId;
  final String fullName;

  /// Nulo quando quem pediu a lista nao e admin: o aluno ve quem embarca junto,
  /// mas nao o contato de ninguem.
  final String? email;
  final String? tripType;
  final String createdAt;
  final String? institutionName;

  const ListEntry({
    required this.id,
    required this.userId,
    required this.fullName,
    this.email,
    this.tripType,
    required this.createdAt,
    this.institutionName,
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
    );
  }
}
