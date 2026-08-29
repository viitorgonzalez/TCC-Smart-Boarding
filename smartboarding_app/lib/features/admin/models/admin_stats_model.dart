/// Números do "Resumo de Hoje" do painel (`GET /api/admin/stats`).
class AdminStats {
  final int activeStudents;
  final int routesInUse;
  final int occupancyPercent;

  const AdminStats({
    required this.activeStudents,
    required this.routesInUse,
    required this.occupancyPercent,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      activeStudents: json['activeStudents'] as int,
      routesInUse: json['routesInUse'] as int,
      occupancyPercent: json['occupancyPercent'] as int,
    );
  }
}
