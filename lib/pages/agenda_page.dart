import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/prova.dart';
import '../services/feriados_service.dart';
import '../theme/cores.dart';
import '../utils/datas.dart';
import '../widgets/componentes.dart';
import 'nova_prova_page.dart';

/// Tela 3 — Agenda de provas em tempo real (aula 09).
///
/// Recebe [filtroInicial] da tela anterior (passagem de parâmetro, aula 05).
class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key, this.filtroInicial});

  final TipoAvaliacao? filtroInicial;

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  late TipoAvaliacao? _filtro = widget.filtroInicial;
  final Set<String> _abertas = {};
  List<Feriado> _feriados = const [];

  final _colecao = FirebaseFirestore.instance.collection('provas');

  @override
  void initState() {
    super.initState();
    _carregarFeriados();
  }

  Future<void> _carregarFeriados() async {
    final ano = DateTime.now().year;
    final lista = <Feriado>[];
    for (final a in [ano, ano + 1]) {
      try {
        lista.addAll(await FeriadosService.doAno(a));
      } catch (_) {
        // Sem internet: a agenda funciona, só sem a etiqueta de feriado.
      }
    }
    if (mounted) setState(() => _feriados = lista);
  }

  Feriado? _feriadoEm(DateTime data) {
    for (final f in _feriados) {
      if (mesmoDia(f.data, data)) return f;
    }
    return null;
  }

  Future<void> _marcarTopico(Prova prova, int indice, bool valor) async {
    final topicos = [
      for (var i = 0; i < prova.topicos.length; i++)
        Topico(
          titulo: prova.topicos[i].titulo,
          estudado: i == indice ? valor : prova.topicos[i].estudado,
        ),
    ];
    // Atualiza o documento; o StreamBuilder redesenha sozinho.
    await _colecao.doc(prova.id).update({
      'topicos': topicos.map((t) => t.toMap()).toList(),
    });
  }

  Future<void> _excluir(Prova prova) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir prova?'),
        content: Text('${prova.disciplina} (${prova.tipo.rotulo}) será removida para todo o grupo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await _colecao.doc(prova.id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agenda de provas',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Cores.royal,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Cadastrar prova',
        backgroundColor: Cores.royal,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NovaProvaPage()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                _chip('Todas', null),
                for (final t in TipoAvaliacao.values) _chip(t.rotulo, t),
              ],
            ),
          ),
          Expanded(
            // Aula 09: lista em tempo real com snapshots() + StreamBuilder.
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _colecao.orderBy('data').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Erro ao ler o Firestore:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                // Indicador de carregamento enquanto os dados não chegam.
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final todas = snapshot.data!.docs.map(Prova.fromDoc).toList();
                final visiveis =
                    _filtro == null ? todas : todas.where((p) => p.tipo == _filtro).toList();

                if (visiveis.isEmpty) {
                  return _AgendaVazia(filtrada: _filtro != null);
                }

                final estudados = visiveis.fold<int>(0, (s, p) => s + p.estudados);
                final total = visiveis.fold<int>(0, (s, p) => s + p.topicos.length);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                      child: Text(
                        '${visiveis.length} avaliações · $estudados de $total tópicos',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 12, color: Cores.textoSuave),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: visiveis.length,
                        separatorBuilder: (context, i) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final prova = visiveis[i];
                          final aberta = _abertas.contains(prova.id);
                          return _CartaoProva(
                            prova: prova,
                            feriado: _feriadoEm(prova.data),
                            aberta: aberta,
                            onAlternar: () => setState(() {
                              aberta ? _abertas.remove(prova.id) : _abertas.add(prova.id!);
                            }),
                            onMarcarTopico: (indice, valor) => _marcarTopico(prova, indice, valor),
                            onExcluir: () => _excluir(prova),
                          );
                        },
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

  Widget _chip(String rotulo, TipoAvaliacao? valor) {
    final selecionado = _filtro == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(rotulo),
        selected: selecionado,
        showCheckmark: false,
        onSelected: (_) => setState(() => _filtro = valor),
        selectedColor: Cores.marinho,
        backgroundColor: Colors.white,
        side: BorderSide(color: selecionado ? Cores.marinho : Cores.bordaCampo),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: selecionado ? Colors.white : Cores.marinho,
        ),
        shape: const StadiumBorder(),
      ),
    );
  }
}

class _CartaoProva extends StatelessWidget {
  const _CartaoProva({
    required this.prova,
    required this.feriado,
    required this.aberta,
    required this.onAlternar,
    required this.onMarcarTopico,
    required this.onExcluir,
  });

  final Prova prova;
  final Feriado? feriado;
  final bool aberta;
  final VoidCallback onAlternar;
  final void Function(int indice, bool valor) onMarcarTopico;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final dias = prova.diasRestantes;
    final proximo = prova.proximoTopico;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Cores.borda),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onAlternar,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlocoData(data: prova.data, escuro: dias >= 0 && dias <= 10),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Etiqueta(
                              texto: prova.tipo.rotulo,
                              corFundo: prova.tipo.corFundo,
                              corTexto: prova.tipo.corTexto,
                            ),
                            Text(
                              textoContagem(dias),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Cores.textoSuave,
                              ),
                            ),
                            if (feriado != null)
                              const Etiqueta(
                                texto: 'Feriado',
                                corFundo: Cores.alertaFundo,
                                corTexto: Cores.alertaTexto,
                                corBorda: Cores.alertaBorda,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          prova.disciplina,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Cores.texto,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(fontSize: 12, color: Cores.textoSuave),
                            children: proximo == null
                                ? const [TextSpan(text: 'Tudo estudado para esta prova')]
                                : [
                                    const TextSpan(text: 'Próximo tópico: '),
                                    TextSpan(
                                      text: proximo.titulo,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Cores.marinho,
                                      ),
                                    ),
                                  ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: BarraProgresso(valor: prova.progresso)),
                            const SizedBox(width: 10),
                            Text(
                              '${prova.estudados} de ${prova.topicos.length} tópicos',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Cores.textoSuave,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    aberta ? Icons.expand_less : Icons.expand_more,
                    color: Cores.textoSuave,
                  ),
                ],
              ),
            ),
          ),
          if (aberta) ...[
            const Divider(height: 1, color: Cores.trilho),
            if (prova.local.isNotEmpty || feriado != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Text(
                  [
                    if (prova.local.isNotEmpty) prova.local,
                    if (feriado != null) 'Atenção: ${feriado!.nome}',
                  ].join('\n'),
                  style: const TextStyle(fontSize: 13, color: Cores.textoSuave, height: 1.4),
                ),
              ),
            for (var i = 0; i < prova.topicos.length; i++)
              CheckboxListTile(
                value: prova.topicos[i].estudado,
                onChanged: (valor) => onMarcarTopico(i, valor ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Cores.royal,
                dense: true,
                title: Text(
                  prova.topicos[i].titulo,
                  style: TextStyle(
                    fontSize: 14,
                    color: prova.topicos[i].estudado ? Cores.textoSuave : Cores.texto,
                    decoration: prova.topicos[i].estudado ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                child: TextButton.icon(
                  onPressed: onExcluir,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Excluir prova'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFB42318)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AgendaVazia extends StatelessWidget {
  const _AgendaVazia({required this.filtrada});

  final bool filtrada;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/agenda_vazia.png', height: 150, fit: BoxFit.contain),
            const SizedBox(height: 12),
            Text(
              filtrada ? 'Nenhuma prova deste tipo' : 'Agenda vazia',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Cores.texto),
            ),
            const SizedBox(height: 4),
            const Text(
              'Toque em + para cadastrar uma avaliação.',
              style: TextStyle(color: Cores.textoSuave),
            ),
          ],
        ),
      ),
    );
  }
}
