extension Converter on DateTime {
  int toInt() {
    return (year * 10000) + (month * 100) + day;
  }

  bool isDifferentDay(DateTime other) {
    return day != other.day || month != other.month || year != other.year;
  }
}
