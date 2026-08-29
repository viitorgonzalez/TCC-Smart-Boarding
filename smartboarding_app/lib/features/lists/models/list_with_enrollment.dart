import 'daily_list_model.dart';

/// Agrega a lista diária com o status de inscrição do usuário atual.
class ListWithEnrollment {
  final DailyList list;
  final bool isEnrolled;
  final String? tripType; // direção escolhida, se inscrito

  const ListWithEnrollment({
    required this.list,
    required this.isEnrolled,
    this.tripType,
  });
}
