import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/cores.dart';
import '../utils/datas.dart';

/// Tipo de avaliação, usado no grupo de Radio do formulário (aula 08).
enum TipoAvaliacao {
  np1('NP1', Cores.gelo, Cores.marinho),
  np2('NP2', Cores.celeste, Cores.marinho),
  exame('Exame', Cores.marinho, Colors.white);

  const TipoAvaliacao(this.rotulo, this.corFundo, this.corTexto);

  final String rotulo;
  final Color corFundo;
  final Color corTexto;

  static TipoAvaliacao doNome(String? nome) => TipoAvaliacao.values.firstWhere(
        (t) => t.name == nome,
        orElse: () => TipoAvaliacao.np2,
      );
}

/// Um item do conteúdo da prova ("o que preciso estudar").
class Topico {
  Topico({required this.titulo, this.estudado = false});

  final String titulo;
  bool estudado;

  Map<String, dynamic> toMap() => {'titulo': titulo, 'estudado': estudado};

  factory Topico.fromMap(Map<String, dynamic> mapa) => Topico(
        titulo: (mapa['titulo'] ?? '') as String,
        estudado: (mapa['estudado'] ?? false) as bool,
      );
}

/// Documento da coleção "provas" no Cloud Firestore.
class Prova {
  Prova({
    this.id,
    required this.disciplina,
    required this.professor,
    required this.sala,
    required this.data,
    required this.tipo,
    required this.topicos,
  });

  final String? id;
  final String disciplina;
  final String professor;
  final String sala;
  final DateTime data;
  final TipoAvaliacao tipo;
  final List<Topico> topicos;

  int get estudados => topicos.where((t) => t.estudado).length;

  double get progresso => topicos.isEmpty ? 0 : estudados / topicos.length;

  Topico? get proximoTopico {
    for (final t in topicos) {
      if (!t.estudado) return t;
    }
    return null;
  }

  int get diasRestantes => diasAte(data);

  String get local => [
        if (professor.isNotEmpty) 'Prof. $professor',
        if (sala.isNotEmpty) sala,
      ].join(' · ');

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
    final lista = (mapa['topicos'] as List<dynamic>? ?? const [])
        .map((e) => Topico.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return Prova(
      id: doc.id,
      disciplina: (mapa['disciplina'] ?? '') as String,
      professor: (mapa['professor'] ?? '') as String,
      sala: (mapa['sala'] ?? '') as String,
      data: valorData is Timestamp ? valorData.toDate() : DateTime.now(),
      tipo: TipoAvaliacao.doNome(mapa['tipo'] as String?),
      topicos: lista,
    );
  }
}
