import 'strings.dart';

const int pradhaPerCen = 100000000;

/// Formats pradha as CEN with at least four decimals, trimming noise decimals.
///
/// Keeping a 4-decimal floor matches how the balance is read at a glance while
/// still showing every digit for amounts below 0.0001 CEN.
String formatCen(int pradha) {
  final negative = pradha < 0;
  final abs = pradha.abs();
  final whole = abs ~/ pradhaPerCen;
  var frac = (abs % pradhaPerCen).toString().padLeft(8, '0');
  frac = frac.replaceFirst(RegExp('0+\$'), '');
  while (frac.length < 4) {
    frac = '${frac}0';
  }
  final decimal = S.isId ? ',' : '.';
  final head = _group(whole);
  return '${negative ? '-' : ''}$head$decimal$frac';
}

String formatSignedCen(int pradha, {required bool incoming}) {
  final body = formatCen(pradha.abs());
  return '${incoming ? '+' : '-'}$body';
}

String formatRawPradha(int pradha) => '${_group(pradha)} pradha';

String _group(int value) {
  final thousands = S.isId ? '.' : ',';
  final digits = value.toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(thousands);
    out.write(digits[i]);
  }
  return out.toString();
}

/// `cen69:qp0w…jghd` — enough to recognise, short enough for one line.
String shortAddress(String address) {
  final trimmed = address.trim();
  final sep = trimmed.indexOf(':');
  if (sep < 0 || trimmed.length <= sep + 9) return trimmed;
  final prefix = trimmed.substring(0, sep);
  final body = trimmed.substring(sep + 1);
  if (body.length <= 9) return trimmed;
  return '$prefix:${body.substring(0, 4)}…${body.substring(body.length - 4)}';
}

/// `4f2a9c…d81b` — txids have no readable prefix, so keep both ends.
String shortHash(String hash, {int left = 8, int right = 6}) {
  final trimmed = hash.trim();
  if (trimmed.length <= left + right + 1) return trimmed;
  return '${trimmed.substring(0, left)}…${trimmed.substring(trimmed.length - right)}';
}

const List<String> _monthsId = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

const List<String> _monthsEn = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _month(int month) => (S.isId ? _monthsId : _monthsEn)[month - 1];

/// Compact relative-ish stamp for ledger rows: `Min, 23 Nov · 14.20`.
///
/// Includes weekday and month so scanned history stays readable without opening
/// a row. Kept to one line to avoid vertical overflow in dense lists.
String formatRelativeTime(DateTime time, {DateTime? now}) {
  final clock = '${_two(time.hour)}${S.isId ? '.' : ':'}${_two(time.minute)}';
  final dayShort = (S.isId ? _daysIdShort : _daysEnShort)[time.weekday - 1];
  final monthShort = _month(time.month);
  final ref = now ?? DateTime.now();
  final sameYear = time.year == ref.year;
  final year = sameYear ? '' : ' ${time.year}';
  return '$dayShort, ${time.day} $monthShort$year · $clock';
}

const List<String> _daysIdShort = <String>[
  'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min',
];

const List<String> _daysEnShort = <String>[
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];

/// `20 Nov · 02.41` (id) or `20 Nov · 02:41` (en).
String formatStamp(DateTime time) {
  final clock = '${_two(time.hour)}${S.isId ? '.' : ':'}${_two(time.minute)}';
  return '${time.day} ${_month(time.month)} · $clock';
}

/// `20 Nov 2026`.
String formatDay(DateTime time) => '${time.day} ${_month(time.month)} ${time.year}';

String _two(int value) => value.toString().padLeft(2, '0');