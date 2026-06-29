String normalizeStockCode(String raw) {
  return raw.replaceAll(RegExp(r'\D'), '');
}

bool isValidStockCode(String raw) {
  return RegExp(r'^\d{6}$').hasMatch(normalizeStockCode(raw));
}

String? stockCodeValidationMessage(String raw) {
  final code = normalizeStockCode(raw);
  if (code.isEmpty) return '종목 코드를 입력하세요';
  if (!isValidStockCode(code)) return '6자리 숫자로 입력하세요';
  return null;
}
