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

/// "2026-07-11T16:00:00" → "16:00".
String formatTime(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${_pad2(d.hour)}:${_pad2(d.minute)}';
}

/// "16:00:00" → (16, 0). Devolve null se não parsear.
({int hour, int minute})? parseTimeOfDay(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parts = raw.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return (hour: h, minute: m);
}

/// Tempo restante até o fechamento da rota. Retorna null se o horário já passou.
/// O horário vem da rota (RN18) — não é fixo em 16:00.
Duration? timeUntilListClose(String? closeTime, [DateTime? now]) {
  final parsed = parseTimeOfDay(closeTime);
  if (parsed == null) return null;
  final n = now ?? DateTime.now();
  final close = DateTime(n.year, n.month, n.day, parsed.hour, parsed.minute);
  if (!n.isBefore(close)) return null;
  return close.difference(n);
}

/// "16:00:00" → "16:00", pra exibir.
String formatCloseTime(String? raw) {
  final parsed = parseTimeOfDay(raw);
  if (parsed == null) return '—';
  return '${_pad2(parsed.hour)}:${_pad2(parsed.minute)}';
}

/// "3h 24min" / "24min" a partir de uma Duration.
String humanizeDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h > 0) return '${h}h ${_pad2(m)}min';
  return '${m}min';
}
