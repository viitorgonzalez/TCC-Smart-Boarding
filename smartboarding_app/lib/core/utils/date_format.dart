// Formatação de datas para o padrão brasileiro (dd/MM/yyyy).
// Aceita as strings ISO que vêm da API ("2026-07-11" ou "2026-07-11T16:00:00").

String _pad2(int n) => n.toString().padLeft(2, '0');

/// "2026-07-11" → "11/07/2026". Retorna a entrada crua se não parsear.
String formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${_pad2(d.day)}/${_pad2(d.month)}/${d.year}';
}

/// "2026-07-11T16:00:00" → "11/07/2026 às 16:00".
String formatDateTime(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${_pad2(d.day)}/${_pad2(d.month)}/${d.year} às ${_pad2(d.hour)}:${_pad2(d.minute)}';
}

/// Tempo restante até o horário de fechamento da lista (16:00 do dia atual).
/// Retorna null se já passou das 16:00.
Duration? timeUntilListClose([DateTime? now]) {
  final n = now ?? DateTime.now();
  final close = DateTime(n.year, n.month, n.day, 16, 0);
  if (!n.isBefore(close)) return null;
  return close.difference(n);
}

/// "3h 24min" / "24min" a partir de uma Duration.
String humanizeDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h > 0) return '${h}h ${_pad2(m)}min';
  return '${m}min';
}
