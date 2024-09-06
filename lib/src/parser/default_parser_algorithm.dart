import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ml_card_scanner/src/model/card_info.dart';
import 'package:ml_card_scanner/src/parser/card_parser_const.dart';
import 'package:ml_card_scanner/src/parser/parser_algorithm.dart';
import 'package:ml_card_scanner/src/utils/card_info_variants_extension.dart';
import 'package:ml_card_scanner/src/utils/int_extension.dart';
import 'package:ml_card_scanner/src/utils/string_extension.dart';

class DefaultParserAlgorithm extends ParserAlgorithm {
  final int cardScanTries;
  final List<CardInfo> _recognizedVariants = List.empty(growable: true);

  DefaultParserAlgorithm(this.cardScanTries);

  @override
  CardInfo? parse(RecognizedText recognizedText) {
    CardInfo? cardOption;

    try {
      final elements =
          recognizedText.blocks.map((e) => e.text.clean()).toList();
      final possibleCardNumber = getCardNumber(elements);
      final cardType = getCardType(possibleCardNumber);
      final expire = getExpiryDate(elements);
      cardOption = CardInfo(
        number: possibleCardNumber,
        type: cardType,
        expiry: expire,
      );
    } catch (e, _) {
      cardOption = null;
    }

    if (cardOption != null && cardOption.isValid()) {
      print('cardOption: ${cardOption.toString()}');
      _recognizedVariants.add(cardOption);
    }

    if (_recognizedVariants.length == cardScanTries) {
      final cardNumber = _recognizedVariants.getCardNumber();
      final cardDate = _recognizedVariants.getCardDate();
      final cardType = getCardType(cardNumber);
      _recognizedVariants.clear();

      return CardInfo(
        number: cardNumber,
        type: cardType,
        expiry: cardDate.possibleDateFormatted(),
      );
    }
    return null;
  }

  @override
  String getCardNumber(List<String> inputs) {
    return inputs.firstWhere(
      (input) {
        final cleanValue = input.fixPossibleMisspells();
        return (cleanValue.length == CardParserConst.cardNumberLength) &&
            (int.tryParse(cleanValue) ?? -1) != -1;
      },
      orElse: () => '',
    );
  }

  @override
  String getExpiryDate(List<String> inputs) {
    try {
      final possibleDate = inputs.firstWhere((input) {
        final cleanValue = input.fixPossibleMisspells();
        if (cleanValue.length == 4) {
          final m = cleanValue.getDateMonthNumber();
          final y = cleanValue.getDateYearNumber();
          if (m.validateDateMonth() && y.validateDateYear()) {
            return true;
          }
        }
        return false;
      });
      return possibleDate.fixPossibleMisspells();
    } catch (e, _) {
      return '';
    }
  }
}
