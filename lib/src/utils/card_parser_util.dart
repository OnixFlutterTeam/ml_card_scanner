import 'dart:core';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ml_card_scanner/src/model/card_info.dart';
import 'package:ml_card_scanner/src/utils/string_extension.dart';

class CardParserUtil {
  final int _cardNumberLength = 16;
  final String _cardVisa = 'Visa';
  final String _cardMasterCard = 'MasterCard';
  final String _cardUnknown = 'Unknown';
  final String _cardVisaParam = '4';
  final String _cardMasterCardParam = '5';
  final _expiryDateRegEx = r'/^(0[1-9]|1[0-2])\/?([0-9]{4}|[0-9]{2})$/;';
  final _textDetector = TextRecognizer(script: TextRecognitionScript.latin);

  Future<CardInfo?> detectCardContent(InputImage inputImage) async {
    var input = await _textDetector.processImage(inputImage);

    var clearElements = input.blocks
        .map(
          (e) => e.text.clean(),
        )
        .toList();

    try {
      var possibleCardNumber = clearElements.firstWhere((e) =>
          (e.length == _cardNumberLength) && (int.tryParse(e) ?? -1) != -1);
      var cardType = _getCardType(possibleCardNumber);
      var expire = _getExpireDate(clearElements);
      return CardInfo(
          number: possibleCardNumber, type: cardType, expiry: expire);
    } catch (e, _) {}

    try {
      var possibleCardNumbers = clearElements
          .where((e) => (e.length == 4) && (int.tryParse(e) ?? -1) != -1);
      if (possibleCardNumbers.length == 4) {
        var cardNumber = possibleCardNumbers.join('');
        var cardType = _getCardType(cardNumber);
        var expire = _getExpireDate(clearElements);
        return CardInfo(number: cardNumber, type: cardType, expiry: expire);
      }
    } catch (e, _) {}

    return null;
  }

  String _getExpireDate(List<String> input) {
    try {
      return input
          .firstWhere((element) => RegExp(_expiryDateRegEx).hasMatch(element));
    } catch (e, _) {
      return '';
    }
  }

  String _getCardType(String input) {
    if (input[0] == _cardVisaParam) {
      return _cardVisa;
    }
    if (input[0] == _cardMasterCardParam) {
      return _cardMasterCard;
    }
    return _cardUnknown;
  }
}
