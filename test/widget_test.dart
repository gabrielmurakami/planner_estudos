import 'package:flutter_test/flutter_test.dart';
import 'package:planner_estudos/utils/datas.dart';

void main() {
  test('lerData aceita dd/mm/aaaa e recusa datas inexistentes', () {
    expect(lerData('20/11/2026'), DateTime(2026, 11, 20));
    expect(lerData('31/02/2026'), isNull);
    expect(lerData('2026-11-20'), isNull);
  });

  test('diasAte e textoContagem', () {
    final hoje = DateTime(2026, 11, 9);
    expect(diasAte(DateTime(2026, 11, 18), hoje), 9);
    expect(textoContagem(9), 'em 9 dias');
    expect(textoContagem(1), 'amanhã');
    expect(textoContagem(0), 'hoje');
  });
}
