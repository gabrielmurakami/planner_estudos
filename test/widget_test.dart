import 'package:flutter_test/flutter_test.dart';
import 'package:planner_estudos/models/prova.dart';
import 'package:planner_estudos/utils/datas.dart';

void main() {
  group('datas', () {
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

    test('textoFaltam', () {
      expect(textoFaltam(9), 'Faltam 9 dias');
      expect(textoFaltam(1), 'Falta 1 dia');
      expect(textoFaltam(0), 'É hoje!');
    });
  });

  group('Prova', () {
    final prova = Prova(
      id: 'abc',
      disciplina: 'Estatística',
      professor: 'Ana',
      sala: '',
      data: DateTime(2026, 11, 20),
      tipo: TipoAvaliacao.np2,
      topicos: const [
        Topico(titulo: 'Média', estudado: true),
        Topico(titulo: 'Variância'),
      ],
    );

    test('progresso e próximo tópico', () {
      expect(prova.estudados, 1);
      expect(prova.progresso, 0.5);
      expect(prova.proximoTopico?.titulo, 'Variância');
    });

    test('topicosComMarcacao não altera a prova original', () {
      final novos = prova.topicosComMarcacao(1, true);
      expect(Prova.contarEstudados(novos), 2);
      expect(prova.estudados, 1);
    });

    test('descreverLocal omite campos vazios', () {
      expect(prova.local, 'Prof. Ana');
      expect(Prova.descreverLocal('', 'Lab 2'), 'Lab 2');
      expect(Prova.descreverLocal('Ana', 'Lab 2'), 'Prof. Ana · Lab 2');
      expect(Prova.descreverLocal('', ''), '');
    });
  });
}
