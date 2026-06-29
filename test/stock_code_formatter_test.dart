import 'package:flutter_test/flutter_test.dart';
import 'package:stock_monitor/utils/stock_code_formatter.dart';

void main() {
  test('normalizes pasted Korean stock codes to six digits', () {
    expect(normalizeStockCode(' 005930 '), '005930');
    expect(normalizeStockCode('005930.KS'), '005930');
    expect(normalizeStockCode('005-930'), '005930');
  });

  test('validates only six digit Korean stock codes', () {
    expect(isValidStockCode('005930'), isTrue);
    expect(isValidStockCode('5930'), isFalse);
    expect(isValidStockCode('0059307'), isFalse);
    expect(isValidStockCode('ABCDEF'), isFalse);
  });

  test('returns user-facing validation messages for invalid codes', () {
    expect(stockCodeValidationMessage(''), '종목 코드를 입력하세요');
    expect(stockCodeValidationMessage('5930'), '6자리 숫자로 입력하세요');
    expect(stockCodeValidationMessage('005930'), isNull);
  });
}
