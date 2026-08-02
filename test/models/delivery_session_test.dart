import 'package:delivery_profit_v2/models/delivery_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generateSessionId creates non-empty unique values', () {
    final first = DeliverySession.generateSessionId();
    final second = DeliverySession.generateSessionId();

    expect(first, isNotEmpty);
    expect(second, isNotEmpty);
    expect(second, isNot(first));
  });
}
