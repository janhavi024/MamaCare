import 'package:intl/intl.dart';

final _dateTime = DateFormat('EEE, d MMM yyyy · h:mm a');
final _date = DateFormat('d MMM yyyy');

String fmtDateTime(DateTime d) => _dateTime.format(d.toLocal());
String fmtDate(DateTime d) => _date.format(d.toLocal());
String isoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
String fmtTimeOfDay(String hhmm) {
  final p = hhmm.split(':');
  final h = int.parse(p[0]);
  final m = p[1];
  final suffix = h >= 12 ? 'PM' : 'AM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:$m $suffix';
}

String firstName(String full) => full.trim().split(' ').first;
String initials(String full) {
  final parts = full.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
}

String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

String titleCase(String enumName) =>
    enumName.toLowerCase().split('_').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
