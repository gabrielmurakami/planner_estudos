import 'package:flutter/material.dart';

import '../models/prova.dart';
import '../services/feriados_service.dart';
import '../services/provas_service.dart';
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
  /// Tipo selecionado nos chips (null = "Todas").
  late TipoAvaliacao? _filtro = widget.filtroInicial;

  /// IDs das provas com o card aberto.
  final Set<String> _abertas = {};

  List<Feriado> _feriados = const [];

  // Criado uma única vez: se fosse criado no build, cada setState (abrir um
  // card, trocar o filtro) reabriria a conexão e piscaria o carregamento.
  final _provas = ProvasService.todasEmTempoReal();

  @override
  void initState() {
    super.initState();
    _carregarFeriados();
  }

  // ---------- Ações ----------

  Future<void> _carregarFeriados() async {
    // Sem internet a lista vem vazia: a agenda funciona, só sem a etiqueta.
    final lista = await FeriadosService.desteAnoEDoProximo();
    if (mounted) setState(() => _feriados = lista);
  }

  void _alternarCartao(String id) {
    setState(() {
      if (!_abertas.remove(id)) _abertas.add(id);
    });
  }

  Future<void> _marcarTopico(Prova prova, int indice, bool estudado) async {
    try {
      // Atualiza o documento; o StreamBuilder redesenha sozinho.
      await ProvasService.atualizarTopicos(prova.id!, prova.topicosComMarcacao(indice, estudado));
    } catch (e) {
      if (mounted) mostrarAviso(context, 'Não foi possível atualizar: $e');
    }
  }

  Future<void> _excluir(Prova prova) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir prova?'),
        content: Text(
          '${prova.disciplina} (${prova.tipo.rotulo}) será removida para todo o grupo.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmou != true) return;

    try {
      await ProvasService.excluir(prova.id!);
    } catch (e) {
      if (mounted) mostrarAviso(context, 'Não foi possível excluir: $e');
    }
  }

  void _abrirNovaProva() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const NovaProvaPage()));
  }

  // ---------- Interface ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barraDoApp('Agenda de provas'),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Cadastrar prova',
        backgroundColor: Cores.royal,
        foregroundColor: Colors.white,
        onPressed: _abrirNovaProva,
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FiltrosTipo(
            selecionado: _filtro,
            onSelecionar: (tipo) => setState(() => _filtro = tipo),
          ),
          Expanded(
            // Aula 09: lista em tempo real com snapshots() + StreamBuilder.
            child: StreamBuilder<List<Prova>>(
              stream: _provas,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return MensagemErro(erro: snapshot.error);
                }
                // Indicador de carregamento enquanto os dados não chegam.
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final visiveis = _filtro == null
                    ? snapshot.data!
                    : snapshot.data!.where((p) => p.tipo == _filtro).toList();

                if (visiveis.isEmpty) {
                  return _AgendaVazia(filtrada: _filtro != null);
                }
                return _listaDeProvas(visiveis);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _listaDeProvas(List<Prova> provas) {
    final estudados = provas.fold<int>(0, (soma, p) => soma + p.estudados);
    final total = provas.fold<int>(0, (soma, p) => soma + p.topicos.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Text(
            '${provas.length} avaliações · $estudados de $total tópicos',
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, color: Cores.textoSuave),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            itemCount: provas.length,
            separatorBuilder: (context, i) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final prova = provas[i];
              return _CartaoProva(
                prova: prova,
                feriado: FeriadosService.procurar(_feriados, prova.data),
                aberta: _abertas.contains(prova.id),
                onAlternar: () => _alternarCartao(prova.id!),
                onMarcarTopico: (indice, valor) => _marcarTopico(prova, indice, valor),
                onExcluir: () => _excluir(prova),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Chips de filtro: Todas, NP1, NP2 e Exame.
class _FiltrosTipo extends StatelessWidget {
  const _FiltrosTipo({required this.selecionado, required this.onSelecionar});

  final TipoAvaliacao? selecionado;
  final ValueChanged<TipoAvaliacao?> onSelecionar;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [_chip('Todas', null), for (final t in TipoAvaliacao.values) _chip(t.rotulo, t)],
      ),
    );
  }

  Widget _chip(String rotulo, TipoAvaliacao? valor) {
    final ativo = selecionado == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(rotulo),
        selected: ativo,
        showCheckmark: false,
        onSelected: (_) => onSelecionar(valor),
        selectedColor: Cores.marinho,
        backgroundColor: Colors.white,
        side: BorderSide(color: ativo ? Cores.marinho : Cores.bordaCampo),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: ativo ? Colors.white : Cores.marinho,
        ),
        shape: const StadiumBorder(),
      ),
    );
  }
}

/// Card de uma prova. Fechado mostra o resumo; aberto mostra também os
/// tópicos (com Checkbox) e o botão de excluir.
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
            child: Padding(padding: const EdgeInsets.all(12), child: _resumo()),
          ),
          if (aberta) ..._detalhes(),
        ],
      ),
    );
  }

  /// Parte sempre visível: data, etiquetas, disciplina e progresso.
  Widget _resumo() {
    final dias = prova.diasRestantes;
    final proximo = prova.proximoTopico;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bloco escuro destaca as provas dos próximos 10 dias.
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
        Icon(aberta ? Icons.expand_less : Icons.expand_more, color: Cores.textoSuave),
      ],
    );
  }

  /// Parte que só aparece com o card aberto.
  List<Widget> _detalhes() {
    final observacoes = [
      if (prova.local.isNotEmpty) prova.local,
      if (feriado != null) 'Atenção: ${feriado!.nome}',
    ];

    return [
      const Divider(height: 1, color: Cores.trilho),
      if (observacoes.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(
            observacoes.join('\n'),
            style: const TextStyle(fontSize: 13, color: Cores.textoSuave, height: 1.4),
          ),
        ),
      for (var i = 0; i < prova.topicos.length; i++)
        ItemTopico(
          titulo: prova.topicos[i].titulo,
          estudado: prova.topicos[i].estudado,
          tamanhoFonte: 14,
          onChanged: (valor) => onMarcarTopico(i, valor),
        ),
      Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
          child: TextButton.icon(
            onPressed: onExcluir,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Excluir prova'),
            style: TextButton.styleFrom(foregroundColor: Cores.perigo),
          ),
        ),
      ),
    ];
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
