String _pad2(int n) => n.toString().padLeft(2, '0');

String formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${_pad2(d.day)}/${_pad2(d.month)}/${d.year}';
}

String formatDateTime(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${_pad2(d.day)}/${_pad2(d.month)}/${d.year} às ${_pad2(d.hour)}:${_pad2(d.minute)}';
}

String formatTime(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${_pad2(d.hour)}:${_pad2(d.minute)}';
}

({int hour, int minute})? parseTimeOfDay(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parts = raw.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return (hour: h, minute: m);
}

DateTime brazilTimeFromUtc(DateTime instant) =>
    instant.toUtc().subtract(const Duration(hours: 3));

Duration? timeUntilListClose(String? closeTime, [DateTime? now]) {
  final parsed = parseTimeOfDay(closeTime);
  if (parsed == null) return null;
  final n = now ?? brazilTimeFromUtc(DateTime.now());
  final close = DateTime(n.year, n.month, n.day, parsed.hour, parsed.minute);
  if (!n.isBefore(close)) return null;
  return close.difference(n);
}

String formatCloseTime(String? raw) {
  final parsed = parseTimeOfDay(raw);
  if (parsed == null) return '—';
  return '${_pad2(parsed.hour)}:${_pad2(parsed.minute)}';
}

String humanizeDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h > 0) return '${h}h ${_pad2(m)}min';
  return '${m}min';
}
