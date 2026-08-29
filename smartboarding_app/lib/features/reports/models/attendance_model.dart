/// Um dia em que o aluno esteve na lista.
class AttendanceDay {
  final String date;
  final String routeName;
  final String? tripType;

  const AttendanceDay({
    required this.date,
    required this.routeName,
    this.tripType,
  });

  factory AttendanceDay.fromJson(Map<String, dynamic> json) => AttendanceDay(
    date: json['date'] as String,
    routeName: json['routeName'] as String,
    tripType: json['tripType'] as String?,
  );
}
