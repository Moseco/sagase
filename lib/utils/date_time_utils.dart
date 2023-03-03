extension Converter on DateTime {
  int toInt() {
    return (year * 10000) + (month * 100) + day;
  }

  bool isDifferentDay(DateTime other) {
    return year != other.year || month != other.month || day != other.day;
  }
}
