extension StringExtension on String {
  String clean() => replaceAll(RegExp(r'\D'), '');

  //L,l,S,s,o,O
  String fixPossibleMisspells() =>
      replaceAll('/', '').replaceAll('\\', '').replaceAll('L', '1')
        ..replaceAll('l', '1')
        ..replaceAll('S', '5')
        ..replaceAll('s', '5')
        ..replaceAll('o', '0')
        ..replaceAll('O', '0');

  String possibleDateFormatted() {
    if (isEmpty || length != 4) {
      return '';
    }
    final m = substring(0, 2);
    final y = substring(2, 4);
    return '$m/$y';
  }

  int getDateMonthNumber() {
    if (isEmpty || length != 4) {
      return 0;
    }
    final m = substring(0, 2);
    return int.tryParse(m) ?? -1;
  }

  int getDateYearNumber() {
    if (isEmpty || length != 4) {
      return 0;
    }
    final y = substring(2, 4);
    return int.tryParse(y) ?? -1;
  }
}
