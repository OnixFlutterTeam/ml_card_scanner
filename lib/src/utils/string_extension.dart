extension StringExtension on String {
  String clean() {
    return replaceAll(' ', '')
        .replaceAll('|', '')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('{', '')
        .replaceAll('}', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .toLowerCase();
  }
}
