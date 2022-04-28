class CardInfo {
  final String number;
  final String type;
  final String expiry;

  CardInfo({required this.number, required this.type, required this.expiry});

  bool isValid() => number.isNotEmpty && number.length == 16;

  @override
  String toString() {
    return 'CadrInfo\nnumber: $number\ntype: $type\nexpiry: $expiry';
  }
}
