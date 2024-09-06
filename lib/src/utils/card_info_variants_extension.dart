import 'package:characters/characters.dart';
import 'package:ml_card_scanner/src/model/card_info.dart';
import 'package:ml_card_scanner/src/parser/card_parser_const.dart';
import 'package:ml_card_scanner/src/utils/list_count_extension.dart';

extension CardInfoVariantsExtension on List<CardInfo> {
  String getCardNumber() {
    final resultList = List<String>.empty(growable: true);
    for (int i = 0; i < CardParserConst.cardNumberLength; i++) {
      final chars = List<String>.empty(growable: true);
      for (var c in this) {
        if (c.number.length == CardParserConst.cardNumberLength) {
          final char = c.number.characters.toList()[i];
          chars.add(char);
        }
      }
      final mostFrequentChar = chars.getMostFrequentChar();
      resultList.add(mostFrequentChar);
    }
    return resultList.join('');
  }

  String getCardDate() {
    final resultList = List<String>.empty(growable: true);
    for (int i = 0; i < CardParserConst.cardDateLength; i++) {
      final chars = List<String>.empty(growable: true);
      for (var c in this) {
        if (c.expiry.length == CardParserConst.cardDateLength) {
          final char = c.expiry.characters.toList()[i];
          chars.add(char);
        }
      }
      final mostFrequentChar = chars.getMostFrequentChar();
      resultList.add(mostFrequentChar);
    }
    return resultList.join('');
  }

}
