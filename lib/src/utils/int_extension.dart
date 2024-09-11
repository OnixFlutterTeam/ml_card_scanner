extension IntExtension on int {
  bool validateDateMonth() {
    return this > 0 && this <= 12;
  }

  bool validateDateYear() {
    return this > 0;
  }
}
