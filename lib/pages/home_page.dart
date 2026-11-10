import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/prova.dart';
import '../services/exemplos.dart';
import '../services/feriados_service.dart';
import '../theme/cores.dart';
import '../utils/datas.dart';
import '../widgets/componentes.dart';
import 'agenda_page.dart';
import 'nova_prova_page.dart';

/// Tela 1 — Início: próxima prova, o que falta estudar, próximas avaliações
/// e o próximo feriado (BrasilAPI).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Aula 05: navegação com passagem de parâmetro (o filtro da agenda).
  void _abrirAgenda(BuildContext context, {TipoAvaliacao? filtro}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AgendaPage(filtroInicial: filtro)),
    );
  }

  // A tela Nova prova devolve o nome da disciplina salva (dado de volta).
  Future<void> _abrirNovaProva(BuildContext context) async {
    final disciplina = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const NovaProvaPage()),
    );
    if (disciplina != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$disciplina foi salva na agenda.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Planner de Estudos',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Cores.royal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Agenda de provas',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => _abrirAgenda(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirNovaProva(context),
        backgroundColor: Cores.royal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova prova'),
      ),
      // Aula 09: leitura em tempo real da coleção "provas".
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('provas').orderBy('data').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MensagemErro(erro: snapshot.error);
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final provas = snapshot.data!.docs
              .map(Prova.fromDoc)
              .where((p) => p.diasRestantes >= 0)
              .toList();

          // Aula 04: tela longa com SingleChildScrollView + Column.
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (provas.isEmpty)
                  _EstadoVazio(onCadastrar: () => _abrirNovaProva(context))
                else ...[
                  _CartaoProximaProva(
                    prova: provas.first,
                    onTap: () => _abrirAgenda(context),
                  ),
                  const SizedBox(height: 18),
                  _CartaoOQueFaltaEstudar(provas: provas.take(4).toList()),
                  const SizedBox(height: 18),
                  _ProximasAvaliacoes(
                    provas: provas.skip(1).take(3).toList(),
                    onVerAgenda: () => _abrirAgenda(context),
                    onTapProva: (p) => _abrirAgenda(context, filtro: p.tipo),
                  ),
                ],
                const SizedBox(height: 18),
                const _CartaoFeriado(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Aula 04: Stack com Positioned — imagem de capa (aula 03, BoxFit.cover)
/// com textos e o selo de contagem regressiva por cima.
class _CartaoProximaProva extends StatelessWidget {
  const _CartaoProximaProva({required this.prova, required this.onTap});

  final Prova prova;
  final VoidCallback onTap;

  String get _textoFaltam {
    final n = prova.diasRestantes;
    if (n == 0) return 'É hoje!';
    if (n == 1) return 'Falta 1 dia';
    return 'Faltam $n dias';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 176,
        child: Material(
          color: Cores.marinho,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/capa_estudos.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                  ),
                ),
                Positioned(
                  left: 20,
                  top: 22,
                  right: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PRÓXIMA PROVA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: Cores.celeste,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prova.disciplina,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${prova.tipo.rotulo} · ${diaSemanaEData(prova.data)}',
                        style: const TextStyle(fontSize: 14, color: Cores.gelo),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Cores.celeste,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _textoFaltam,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Cores.marinho,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartaoOQueFaltaEstudar extends StatelessWidget {
  const _CartaoOQueFaltaEstudar({required this.provas});

  final List<Prova> provas;

  @override
  Widget build(BuildContext context) {
    final estudados = provas.fold<int>(0, (soma, p) => soma + p.estudados);
    final total = provas.fold<int>(0, (soma, p) => soma + p.topicos.length);

    return CartaoBranco(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const RotuloSecao('O que falta estudar'),
              Text(
                '$estudados de $total tópicos',
                style: const TextStyle(fontSize: 13, color: Cores.textoSuave),
              ),
            ],
          ),
          for (final p in provas) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.disciplina,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Cores.texto),
                  ),
                ),
                Text(
                  '${p.estudados} de ${p.topicos.length}',
                  style: const TextStyle(fontSize: 13, color: Cores.textoSuave),
                ),
              ],
            ),
            const SizedBox(height: 6),
            BarraProgresso(valor: p.progresso),
          ],
        ],
      ),
    );
  }
}

class _ProximasAvaliacoes extends StatelessWidget {
  const _ProximasAvaliacoes({
    required this.provas,
    required this.onVerAgenda,
    required this.onTapProva,
  });

  final List<Prova> provas;
  final VoidCallback onVerAgenda;
  final ValueChanged<Prova> onTapProva;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const RotuloSecao('Próximas avaliações'),
            TextButton(onPressed: onVerAgenda, child: const Text('Ver agenda')),
          ],
        ),
        const SizedBox(height: 6),
        if (provas.isEmpty)
          const CartaoBranco(
            child: Text(
              'Nenhuma outra avaliação cadastrada.',
              style: TextStyle(color: Cores.textoSuave),
            ),
          )
        else
          CartaoBranco(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < provas.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: Cores.trilho),
                  InkWell(
                    onTap: () => onTapProva(provas[i]),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          BlocoData(data: provas[i].data, escuro: false, largura: 44, altura: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provas[i].disciplina,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Cores.texto,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${provas[i].tipo.rotulo} · ${textoContagem(provas[i].diasRestantes)}',
                                  style: const TextStyle(fontSize: 12, color: Cores.textoSuave),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Cores.textoSuave),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Recurso adicional: próximo feriado nacional consultado na BrasilAPI.
class _CartaoFeriado extends StatefulWidget {
  const _CartaoFeriado();

  @override
  State<_CartaoFeriado> createState() => _CartaoFeriadoState();
}

class _CartaoFeriadoState extends State<_CartaoFeriado> {
  late final Future<Feriado?> _proximo = FeriadosService.proximo();

  @override
  Widget build(BuildContext context) {
    return CartaoBranco(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Cores.gelo,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.wb_sunny_outlined, color: Cores.royal, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FutureBuilder<Feriado?>(
              future: _proximo,
              builder: (context, snapshot) {
                final String linha;
                if (snapshot.connectionState != ConnectionState.done) {
                  linha = 'Consultando…';
                } else if (snapshot.hasError) {
                  linha = 'Não foi possível consultar agora';
                } else if (snapshot.data == null) {
                  linha = 'Nenhum feriado encontrado';
                } else {
                  final f = snapshot.data!;
                  linha = '${diaSemanaEData(f.data)} · ${f.nome}';
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Próximo feriado · BrasilAPI',
                      style: TextStyle(fontSize: 12, color: Cores.textoSuave),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      linha,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Cores.marinho,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoVazio extends StatefulWidget {
  const _EstadoVazio({required this.onCadastrar});

  final VoidCallback onCadastrar;

  @override
  State<_EstadoVazio> createState() => _EstadoVazioState();
}

class _EstadoVazioState extends State<_EstadoVazio> {
  bool _adicionando = false;

  Future<void> _adicionarExemplos() async {
    setState(() => _adicionando = true);
    try {
      await adicionarProvasDeExemplo();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível salvar: $e')),
        );
      }
    }
    if (mounted) setState(() => _adicionando = false);
  }

  @override
  Widget build(BuildContext context) {
    return CartaoBranco(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Image.asset('assets/images/agenda_vazia.png', height: 140, fit: BoxFit.contain),
          const SizedBox(height: 12),
          const Text(
            'Nenhuma prova cadastrada',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Cores.texto),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cadastre a próxima avaliação e liste o que precisa estudar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Cores.textoSuave),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: widget.onCadastrar,
            icon: const Icon(Icons.add),
            label: const Text('Cadastrar prova'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Cores.royal,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _adicionando ? null : _adicionarExemplos,
            child: Text(_adicionando ? 'Adicionando…' : 'Adicionar 3 provas de exemplo'),
          ),
        ],
      ),
    );
  }
}

class _MensagemErro extends StatelessWidget {
  const _MensagemErro({required this.erro});

  final Object? erro;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Erro ao ler o Firestore:\n$erro',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Cores.textoSuave),
        ),
      ),
    );
  }
}
