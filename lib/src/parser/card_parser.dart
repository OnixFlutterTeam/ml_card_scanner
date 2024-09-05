import 'dart:core';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ml_card_scanner/src/model/card_info.dart';
import 'package:ml_card_scanner/src/parser/card_parser_const.dart';
import 'package:ml_card_scanner/src/utils/card_info_variants_extension.dart';
import 'package:ml_card_scanner/src/utils/int_extension.dart';
import 'package:ml_card_scanner/src/utils/string_extension.dart';

class CardParser {
  final int cardScanTries;
  final List<CardInfo> _recognizedVariants = List.empty(growable: true);
  final _textDetector = TextRecognizer(script: TextRecognitionScript.latin);

  CardParser({
    required this.cardScanTries,
  });

  Future<CardInfo?> detectCardContent(
    InputImage inputImage,
  ) async {
    CardInfo? cardOption;
    var input = await _textDetector.processImage(inputImage);

    var clearElements = input.blocks.map((e) => e.text.clean()).toList();

    try {
      var possibleCardNumber = clearElements.firstWhere((input) {
        final cleanValue = input.fixPossibleMisspells();
        return (cleanValue.length == CardParserConst.cardNumberLength) &&
            (int.tryParse(cleanValue) ?? -1) != -1;
      });
      var cardType = _getCardType(possibleCardNumber);
      var expire = _getExpireDate(clearElements);
      cardOption = CardInfo(
        number: possibleCardNumber,
        type: cardType,
        expiry: expire,
      );
    } catch (e, _) {
      cardOption = null;
    }
    if (cardOption != null) {
      _recognizedVariants.add(cardOption);
    }

    if (_recognizedVariants.length == cardScanTries) {
      final cardNumber = _recognizedVariants.getCardNumber();
      final cardDate = _recognizedVariants.getCardDate();
      final cardType = _recognizedVariants.getCardType();
      _recognizedVariants.clear();

      return CardInfo(
        number: cardNumber,
        type: cardType,
        expiry: cardDate.possibleDateFormatted(),
      );
    }
    return null;
  }

  String _getExpireDate(List<String> input) {
    try {
      final possibleDate = input.firstWhere((input) {
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

  String _getCardType(String input) {
    if (input[0] == CardParserConst.cardVisaParam) {
      return CardParserConst.cardVisa;
    }
    if (input[0] == CardParserConst.cardMasterCardParam) {
      return CardParserConst.cardMasterCard;
    }
    return CardParserConst.cardUnknown;
  }
}
