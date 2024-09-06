import 'dart:async';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ml_card_scanner/src/model/card_info.dart';
import 'package:ml_card_scanner/src/parser/card_parser_const.dart';

abstract class ParserAlgorithm {
  FutureOr<CardInfo?> parse(RecognizedText recognizedText);

  String getCardNumber(List<String> inputs);

  String getExpiryDate(List<String> inputs);

  String getCardType(String input) {
    if (input.isEmpty) return CardParserConst.cardUnknown;

    if (input[0] == CardParserConst.cardVisaParam) {
      return CardParserConst.cardVisa;
    }
    if (input[0] == CardParserConst.cardMasterCardParam) {
      return CardParserConst.cardMasterCard;
    }
    return CardParserConst.cardUnknown;
  }
}
