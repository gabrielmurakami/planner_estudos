import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/cores.dart';
import '../utils/datas.dart';

/// Tipo de avaliação, usado no grupo de Radio do formulário (aula 08).
/// Cada tipo já carrega o texto e as cores da sua etiqueta.
enum TipoAvaliacao {
  np1('NP1', Cores.gelo, Cores.marinho),
  np2('NP2', Cores.celeste, Cores.marinho),
  exame('Exame', Cores.marinho, Colors.white);

  const TipoAvaliacao(this.rotulo, this.corFundo, this.corTexto);

  final String rotulo;
  final Color corFundo;
  final Color corTexto;

  /// Converte o texto gravado no Firestore ("np1", "np2"...) de volta no enum.
  static TipoAvaliacao doNome(String? nome) =>
      TipoAvaliacao.values.firstWhere((t) => t.name == nome, orElse: () => TipoAvaliacao.np2);
}

/// Um item do conteúdo da prova ("o que preciso estudar").
///
/// É imutável: para marcar como estudado, crie uma cópia com [copyWith].
class Topico {
  const Topico({required this.titulo, this.estudado = false});

  final String titulo;
  final bool estudado;

  Topico copyWith({bool? estudado}) => Topico(titulo: titulo, estudado: estudado ?? this.estudado);

  Map<String, dynamic> toMap() => {'titulo': titulo, 'estudado': estudado};

  factory Topico.fromMap(Map<String, dynamic> mapa) => Topico(
    titulo: (mapa['titulo'] ?? '') as String,
    estudado: (mapa['estudado'] ?? false) as bool,
  );
}

/// Documento da coleção "provas" no Cloud Firestore.
class Prova {
  const Prova({
    this.id,
    required this.disciplina,
    required this.professor,
    required this.sala,
    required this.data,
    required this.tipo,
    required this.topicos,
  });

  /// ID do documento no Firestore (null enquanto a prova não foi salva).
  final String? id;
  final String disciplina;
  final String professor;
  final String sala;
  final DateTime data;
  final TipoAvaliacao tipo;
  final List<Topico> topicos;

  // ---------- Valores calculados ----------

  int get estudados => contarEstudados(topicos);

  /// De 0 a 1, para a barra de progresso.
  double get progresso => topicos.isEmpty ? 0 : estudados / topicos.length;

  /// O primeiro tópico ainda não estudado (null = tudo estudado).
  Topico? get proximoTopico {
    for (final t in topicos) {
      if (!t.estudado) return t;
    }
    return null;
  }

  /// Negativo quando a prova já passou.
  int get diasRestantes => diasAte(data);

  String get local => descreverLocal(professor, sala);

  /// Lista de tópicos com o tópico [indice] marcado (ou desmarcado).
  List<Topico> topicosComMarcacao(int indice, bool estudado) => [
    for (var i = 0; i < topicos.length; i++)
      i == indice ? topicos[i].copyWith(estudado: estudado) : topicos[i],
  ];

  // ---------- Funções auxiliares (também usadas no formulário) ----------

  static int contarEstudados(List<Topico> topicos) => topicos.where((t) => t.estudado).length;

  /// "Prof. Ana · Sala 12", omitindo o que estiver vazio.
  static String descreverLocal(String professor, String sala) =>
      [if (professor.isNotEmpty) 'Prof. $professor', if (sala.isNotEmpty) sala].join(' · ');

  // ---------- Conversão de/para o Firestore ----------

  Map<String, dynamic> toMap() => {
    'disciplina': disciplina,
    'professor': professor,
    'sala': sala,
    // Meio-dia evita que o fuso horário "pule" a data para o dia anterior.
    'data': Timestamp.fromDate(DateTime(data.year, data.month, data.day, 12)),
    'tipo': tipo.name,
    'topicos': topicos.map((t) => t.toMap()).toList(),
    'criadoEm': FieldValue.serverTimestamp(),
  };

  factory Prova.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final mapa = doc.data() ?? <String, dynamic>{};
    final valorData = mapa['data'];
    final topicos = (mapa['topicos'] as List<dynamic>? ?? const [])
        .map((e) => Topico.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return Prova(
      id: doc.id,
      disciplina: (mapa['disciplina'] ?? '') as String,
      professor: (mapa['professor'] ?? '') as String,
      sala: (mapa['sala'] ?? '') as String,
      data: valorData is Timestamp ? valorData.toDate() : DateTime.now(),
      tipo: TipoAvaliacao.doNome(mapa['tipo'] as String?),
      topicos: topicos,
    );
  }
}
