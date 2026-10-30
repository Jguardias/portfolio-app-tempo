/// 45 seg, 12 min, 1 h, 1 h 13 min.
String formatDuration(Duration d) {
  if (d.inSeconds < 60) return "${d.inSeconds} seg";
  final totalMinutes = d.inMinutes;
  if (totalMinutes < 60) return "$totalMinutes min";
  final h = d.inHours;
  final m = totalMinutes % 60;
  return m == 0 ? "$h h" : "$h h $m min";
}