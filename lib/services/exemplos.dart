import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/prova.dart';

/// Cadastra três provas de exemplo na coleção "provas", para a lista já
/// nascer populada na apresentação (seção 10 do PDF).
Future<void> adicionarProvasDeExemplo() async {
  final colecao = FirebaseFirestore.instance.collection('provas');
  final hoje = DateTime.now();

  final exemplos = [
    Prova(
      disciplina: 'Banco de Dados',
      professor: '',
      sala: 'Lab 2',
      data: hoje.add(const Duration(days: 9)),
      tipo: TipoAvaliacao.np2,
      topicos: [
        Topico(titulo: 'Modelo entidade-relacionamento', estudado: true),
        Topico(titulo: 'Normalização', estudado: true),
        Topico(titulo: 'Consultas com JOIN'),
        Topico(titulo: 'GROUP BY e funções de agregação'),
      ],
    ),
    Prova(
      disciplina: 'Estatística',
      professor: '',
      sala: 'Sala 12',
      data: hoje.add(const Duration(days: 11)),
      tipo: TipoAvaliacao.np2,
      topicos: [
        Topico(titulo: 'Média, moda e mediana', estudado: true),
        Topico(titulo: 'Desvio padrão e variância', estudado: true),
        Topico(titulo: 'Distribuição normal'),
        Topico(titulo: 'Probabilidade básica'),
      ],
    ),
    Prova(
      disciplina: 'Desenvolvimento Mobile',
      professor: '',
      sala: 'Laboratório',
      data: hoje.add(const Duration(days: 14)),
      tipo: TipoAvaliacao.np2,
      topicos: [
        Topico(titulo: 'Widgets e layouts', estudado: true),
        Topico(titulo: 'Navegação entre páginas', estudado: true),
        Topico(titulo: 'TextField, Checkbox e Radio'),
        Topico(titulo: 'Firestore com StreamBuilder'),
      ],
    ),
  ];

  for (final prova in exemplos) {
    await colecao.add(prova.toMap());
  }
}
