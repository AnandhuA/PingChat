String formatTime(DateTime dt) {
  int hour = dt.hour;
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = hour >= 12 ? 'PM' : 'AM';

  hour = hour % 12;
  if (hour == 0) hour = 12;

  return '$hour:$minute $period';
}
