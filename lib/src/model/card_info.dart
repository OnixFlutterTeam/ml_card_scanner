class CardInfo {
  final String number;
  final String type;
  final String expiry;

  const CardInfo({
    required this.number,
    required this.type,
    required this.expiry,
  });

  factory CardInfo.fromJson(Map<String, dynamic> json) => CardInfo(
        number: json['number'],
        type: json['type'],
        expiry: json['expiry'],
      );

  Map<String, dynamic> toJson() => {
        'number': number,
        'type': type,
        'expiry': expiry,
      };

  bool isValid() => number.isNotEmpty && number.length == 16;

  @override
  String toString() {
    return 'Card Info\nnumber: $number\ntype: $type\nexpiry: $expiry';
  }
}
