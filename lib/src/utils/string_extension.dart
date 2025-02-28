import 'package:ml_card_scanner/src/parser/card_parser_const.dart';

extension StringExtension on String {
  String clean() => replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

  //L,l,S,s,o,O,I,b
  String fixPossibleMisspells() {
    return replaceAll('/', '')
        .replaceAll('\\', '')
        .replaceAll('L', '1')
        .replaceAll('l', '1')
        .replaceAll('S', '5')
        .replaceAll('s', '5')
        .replaceAll('o', '0')
        .replaceAll('O', '0')
        .replaceAll('b', '6')
        .replaceAll('I', '1')
        .replaceAll('i', '1')
        .replaceAll('c', '0')
        .replaceAll('C', '0')
        .replaceAll('T', '1')
        .replaceAll('t', '1')
        .replaceAll('H', '4')
        .replaceAll('&', '8')
        .replaceAll('q', '9')
        .replaceAll('h', '6')
        .replaceAll('D', '0')
        .replaceAll('n', '0')
        .replaceAll('A', '4')
        .replaceAll('z', '2')
        .replaceAll('Z', '2')
        .replaceAll('Q', '0')
        .replaceAll('B', '8')
        .replaceAll('Y', '4')
        .replaceAll('y', '4')
        .replaceAll('g', '9')
        .replaceAll('j', '1')
        .replaceAll('J', '1')
        .replaceAll('k', '8')
        .replaceAll('K', '8')
        .replaceAll('R', '8')
        .replaceAll('U', '0')
        .replaceAll('X', '8')
        .replaceAll('x', '8')
    ;
  }

  String possibleDateFormatted() {
    if (isEmpty || length != CardParserConst.cardDateLength) {
      return '';
    }
    final m = substring(0, 2);
    final y = substring(2, 4);
    return '$m/$y';
  }

  int getDateMonthNumber() {
    if (isEmpty || length != CardParserConst.cardDateLength) {
      return 0;
    }
    final m = substring(0, 2);
    return int.tryParse(m) ?? -1;
  }

  int getDateYearNumber() {
    if (isEmpty || length != CardParserConst.cardDateLength) {
      return 0;
    }
    final y = substring(2, 4);
    return int.tryParse(y) ?? -1;
  }
}
