import 'daily_list_model.dart';

class ListWithEnrollment {
  final DailyList list;
  final bool isEnrolled;
  final String? tripType;

  const ListWithEnrollment({
    required this.list,
    required this.isEnrolled,
    this.tripType,
  });
}
