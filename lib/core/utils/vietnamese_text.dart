/// Normalizes Vietnamese text for case and accent insensitive search.
String foldVietnamese(String input) {
  const groups = <String, String>{
    'a': 'àáảãạăằắẳẵặâầấẩẫậ',
    'e': 'èéẻẽẹêềếểễệ',
    'i': 'ìíỉĩị',
    'o': 'òóỏõọôồốổỗộơờớởỡợ',
    'u': 'ùúủũụưừứửữự',
    'y': 'ỳýỷỹỵ',
    'd': 'đ',
  };
  var value = input.toLowerCase();
  for (final entry in groups.entries) {
    for (final character in entry.value.split('')) {
      value = value.replaceAll(character, entry.key);
    }
  }
  return value;
}
