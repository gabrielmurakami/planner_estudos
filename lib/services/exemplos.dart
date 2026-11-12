import '../models/prova.dart';
import 'provas_service.dart';

/// Cadastra três provas de exemplo na coleção "provas", para a lista já
/// nascer populada na apresentação (seção 10 do PDF).
Future<void> adicionarProvasDeExemplo() async {
  final hoje = DateTime.now();

  final exemplos = [
    Prova(
      disciplina: 'Banco de Dados',
      professor: '',
      sala: 'Lab 2',
      data: hoje.add(const Duration(days: 9)),
      tipo: TipoAvaliacao.np2,
      topicos: const [
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
      topicos: topicosDeEstatistica,
    ),
    Prova(
      disciplina: 'Desenvolvimento Mobile',
      professor: '',
      sala: 'Laboratório',
      data: hoje.add(const Duration(days: 14)),
      tipo: TipoAvaliacao.np2,
      topicos: const [
        Topico(titulo: 'Widgets e layouts', estudado: true),
        Topico(titulo: 'Navegação entre páginas', estudado: true),
        Topico(titulo: 'TextField, Checkbox e Radio'),
        Topico(titulo: 'Firestore com StreamBuilder'),
      ],
    ),
  ];

  for (final prova in exemplos) {
    await ProvasService.adicionar(prova);
  }
}

/// Tópicos de Estatística: usados num exemplo acima e no formulário,
/// que já abre preenchido para agilizar a demonstração.
const topicosDeEstatistica = [
  Topico(titulo: 'Média, moda e mediana', estudado: true),
  Topico(titulo: 'Desvio padrão e variância', estudado: true),
  Topico(titulo: 'Distribuição normal'),
  Topico(titulo: 'Probabilidade básica'),
];
