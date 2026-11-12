import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/prova.dart';

/// Único ponto do app que conversa com a coleção "provas" do Cloud Firestore
/// (aula 09). As telas chamam estes métodos em vez de acessar o banco direto.
class ProvasService {
  ProvasService._();

  static final CollectionReference<Map<String, dynamic>> _colecao = FirebaseFirestore.instance
      .collection('provas');

  /// Todas as provas ordenadas por data, atualizadas em tempo real.
  /// Usado com StreamBuilder nas telas Início e Agenda.
  static Stream<List<Prova>> todasEmTempoReal() => _colecao
      .orderBy('data')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Prova.fromDoc).toList());

  /// Grava uma nova prova com add().
  static Future<void> adicionar(Prova prova) => _colecao.add(prova.toMap());

  /// Regrava a lista de tópicos (ex.: ao marcar um tópico como estudado).
  static Future<void> atualizarTopicos(String id, List<Topico> topicos) =>
      _colecao.doc(id).update({'topicos': topicos.map((t) => t.toMap()).toList()});

  static Future<void> excluir(String id) => _colecao.doc(id).delete();
}
