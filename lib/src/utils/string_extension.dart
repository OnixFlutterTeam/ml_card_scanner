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
    final m = substring(0, 2);
    final y = substring(2, 4);
    return '$m/$y';
  }
}
