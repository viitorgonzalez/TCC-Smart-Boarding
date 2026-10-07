class AdminStats {
  final int activeStudents;
  final int enrolledToday;
  final int capacityToday;
  final int occupancyPercent;
  final int pendingProfileRequests;
  final int warningsToday;

  const AdminStats({
    required this.activeStudents,
    required this.enrolledToday,
    required this.capacityToday,
    required this.occupancyPercent,
    required this.pendingProfileRequests,
    required this.warningsToday,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      activeStudents: json['activeStudents'] as int,
      enrolledToday: json['enrolledToday'] as int,
      capacityToday: json['capacityToday'] as int,
      occupancyPercent: json['occupancyPercent'] as int,
      pendingProfileRequests: json['pendingProfileRequests'] as int,
      warningsToday: json['warningsToday'] as int,
    );
  }
}
