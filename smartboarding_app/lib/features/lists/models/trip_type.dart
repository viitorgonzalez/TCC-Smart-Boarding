import 'package:flutter/material.dart';

/// Direção do transporte escolhida pelo aluno.
/// Valores da API: ROUND_TRIP (ida e volta), TO_CAMPUS (só ida), FROM_CAMPUS (só volta).
class TripTypeInfo {
  final String value;
  final String label;
  final IconData icon;
  const TripTypeInfo(this.value, this.label, this.icon);
}

const tripTypes = <TripTypeInfo>[
  TripTypeInfo('ROUND_TRIP', 'Ida e volta', Icons.sync_alt),
  TripTypeInfo('TO_CAMPUS', 'Só ida', Icons.arrow_forward),
  TripTypeInfo('FROM_CAMPUS', 'Só volta', Icons.arrow_back),
];

const _fallback = TripTypeInfo('', '—', Icons.help_outline);

TripTypeInfo tripTypeInfo(String? value) =>
    tripTypes.firstWhere((t) => t.value == value, orElse: () => _fallback);

String tripTypeLabel(String? value) => tripTypeInfo(value).label;
