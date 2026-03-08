enum Weekday {
  mon('Пн', 'mon'),
  tue('Вт', 'tue'),
  wed('Ср', 'wed'),
  thu('Чт', 'thu'),
  fri('Пт', 'fri'),
  sat('Сб', 'sat'),
  sun('Вс', 'sun');

  const Weekday(this.label, this.apiCode);

  final String label;
  final String apiCode;

  static Weekday? fromApiCode(String? value) {
    for (final day in values) {
      if (day.apiCode == value) {
        return day;
      }
    }
    return null;
  }

  static Weekday fromDate(DateTime value) {
    return switch (value.weekday) {
      DateTime.monday => Weekday.mon,
      DateTime.tuesday => Weekday.tue,
      DateTime.wednesday => Weekday.wed,
      DateTime.thursday => Weekday.thu,
      DateTime.friday => Weekday.fri,
      DateTime.saturday => Weekday.sat,
      DateTime.sunday => Weekday.sun,
      _ => Weekday.mon,
    };
  }
}
