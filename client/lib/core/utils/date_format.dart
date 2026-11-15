bool isSameDay(DateTime a, DateTime b) {
  final x = a.toLocal();
  final y = b.toLocal();
  return x.year == y.year && x.month == y.month && x.day == y.day;
}

const _months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];

/// «Сегодня», «Вчера» или дата вроде «5 ноября» (с годом, если он не текущий)
String dayLabel(DateTime value) {
  final d = value.toLocal();
  final now = DateTime.now();
  // Считаем по UTC-датам, чтобы переход на летнее время не сбивал разницу
  final today = DateTime.utc(now.year, now.month, now.day);
  final day = DateTime.utc(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;

  if (diff == 0) return 'Сегодня';
  if (diff == 1) return 'Вчера';
  final base = '${d.day} ${_months[d.month - 1]}';
  return d.year == now.year ? base : '$base ${d.year}';
}
