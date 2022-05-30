extension StringExtension on String {
  String clean() => replaceAll(RegExp(r'\D'), '');
}
