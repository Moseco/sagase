extension Converter on DateTime {
  int toInt() {
    return (year * 10000) + (month * 100) + day;
  }
}
