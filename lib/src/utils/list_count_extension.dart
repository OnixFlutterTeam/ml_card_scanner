extension ListCountExtension on List<String> {
  String getMostFrequentChar() {
    //get char counts
    Map<String, int> charCountMap = {};
    for (var e in this) {
      if (charCountMap.containsKey(e)) {
        charCountMap[e] = (charCountMap[e] ?? 0) + 1;
      } else {
        charCountMap[e] = 1;
      }
    }
    int max = -1;
    String char = '';
    charCountMap.forEach(
      (k, v) {
        if (max == -1) {
          max = v;
          char = k;
        } else {
          if (v > max) {
            max = v;
            char = k;
          }
        }
      },
    );
    return char;
  }
}
