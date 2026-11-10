import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/prova.dart';
import '../services/feriados_service.dart';
import '../theme/cores.dart';
import '../utils/datas.dart';
import '../widgets/componentes.dart';

/// Tela 2 — Nova prova (aulas 05 a 09).
///
/// StatefulWidget com setState (aula 06), TextFields com controller, label,
/// hint e onChanged (aula 07), Checkbox e grupo de Radio com enum (aula 08)
/// e gravação no Firestore com add() (aula 09).
class NovaProvaPage extends StatefulWidget {
  const NovaProvaPage({super.key});

  @override
  State<NovaProvaPage> createState() => _NovaProvaPageState();
}

class _NovaProvaPageState extends State<NovaProvaPage> {
  // Valores iniciais prontos agilizam a demonstração (seção 10 do PDF).
  final _disciplinaCtrl = TextEditingController(text: 'Estatística');
  final _professorCtrl = TextEditingController();
  final _salaCtrl = TextEditingController(text: 'Sala 12');
  final _dataCtrl = TextEditingController(
    text: formatarDataCompleta(DateTime.now().add(const Duration(days: 10))),
  );
  final _topicoCtrl = TextEditingController();

  final List<Topico> _topicos = [
    Topico(titulo: 'Média, moda e mediana', estudado: true),
    Topico(titulo: 'Desvio padrão e variância', estudado: true),
    Topico(titulo: 'Distribuição normal'),
    Topico(titulo: 'Probabilidade básica'),
  ];

  TipoAvaliacao _tipo = TipoAvaliacao.np2;
  Feriado? _feriado;
  bool _salvando = false;
  int _consultaFeriado = 0;

  @override
  void initState() {
    super.initState();
    _verificarFeriado();
  }

  @override
  void dispose() {
    _disciplinaCtrl.dispose();
    _professorCtrl.dispose();
    _salaCtrl.dispose();
    _dataCtrl.dispose();
    _topicoCtrl.dispose();
    super.dispose();
  }

  // ---------- Ações ----------

  void _aoDigitar(String _) => setState(() {});

  void _aoMudarData(String _) {
    setState(() {});
    _verificarFeriado();
  }

  /// Consulta a BrasilAPI e mostra o aviso se a data cair num feriado.
  Future<void> _verificarFeriado() async {
    final data = lerData(_dataCtrl.text);
    final consulta = ++_consultaFeriado;
    if (data == null) {
      if (_feriado != null) setState(() => _feriado = null);
      return;
    }
    try {
      final feriado = await FeriadosService.naData(data);
      if (!mounted || consulta != _consultaFeriado) return;
      setState(() => _feriado = feriado);
    } catch (_) {
      if (!mounted || consulta != _consultaFeriado) return;
      setState(() => _feriado = null);
    }
  }

  Future<void> _escolherNoCalendario() async {
    final hoje = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: lerData(_dataCtrl.text) ?? hoje,
      firstDate: DateTime(hoje.year - 1),
      lastDate: DateTime(hoje.year + 2, 12, 31),
    );
    if (escolhida == null || !mounted) return;
    _dataCtrl.text = formatarDataCompleta(escolhida);
    _aoMudarData(_dataCtrl.text);
  }

  void _adicionarTopico() {
    final texto = _topicoCtrl.text.trim();
    if (texto.isEmpty) return;
    setState(() {
      _topicos.add(Topico(titulo: texto));
      _topicoCtrl.clear();
    });
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _salvar() async {
    // Leitura dos valores dos TextFields com .text (aula 07).
    final disciplina = _disciplinaCtrl.text.trim();
    final data = lerData(_dataCtrl.text);

    if (disciplina.isEmpty) {
      _avisar('Informe a disciplina.');
      return;
    }
    if (data == null) {
      _avisar('Data inválida. Use o formato dd/mm/aaaa.');
      return;
    }
    if (_topicos.isEmpty) {
      _avisar('Adicione pelo menos um tópico do conteúdo.');
      return;
    }

    final prova = Prova(
      disciplina: disciplina,
      professor: _professorCtrl.text.trim(),
      sala: _salaCtrl.text.trim(),
      data: data,
      tipo: _tipo,
      topicos: _topicos,
    );

    setState(() => _salvando = true);
    try {
      // Aula 09: gravação de um novo documento com add().
      await FirebaseFirestore.instance.collection('provas').add(prova.toMap());
      if (!mounted) return;
      Navigator.pop(context, disciplina); // devolve um dado para a tela anterior
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      _avisar('Não foi possível salvar: $e');
    }
  }

  // ---------- Interface ----------

  @override
  Widget build(BuildContext context) {
    final data = lerData(_dataCtrl.text);
    final estudados = _topicos.where((t) => t.estudado).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nova prova',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Cores.royal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/banner_nova_prova.png',
                height: 110,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 18),

            const Text(
              'PRÉ-VISUALIZAÇÃO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: Cores.textoSuave,
              ),
            ),
            const SizedBox(height: 8),
            _PreVisualizacao(
              disciplina: _disciplinaCtrl.text.trim(),
              professor: _professorCtrl.text.trim(),
              sala: _salaCtrl.text.trim(),
              data: data,
              tipo: _tipo,
              estudados: estudados,
              total: _topicos.length,
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _disciplinaCtrl,
              onChanged: _aoDigitar,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Disciplina',
                hintText: 'Ex.: Banco de Dados',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _professorCtrl,
                    onChanged: _aoDigitar,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Professor(a)',
                      hintText: 'Nome',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _salaCtrl,
                    onChanged: _aoDigitar,
                    decoration: const InputDecoration(
                      labelText: 'Sala',
                      hintText: 'Ex.: Lab 3',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const RotuloSecao('Conteúdo da prova'),
            const SizedBox(height: 8),
            _ListaTopicos(
              topicos: _topicos,
              controller: _topicoCtrl,
              onMarcar: (i, valor) => setState(() => _topicos[i].estudado = valor),
              onRemover: (i) => setState(() => _topicos.removeAt(i)),
              onAdicionar: _adicionarTopico,
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _dataCtrl,
              onChanged: _aoMudarData,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                labelText: 'Data da prova',
                hintText: 'dd/mm/aaaa',
                suffixIcon: IconButton(
                  tooltip: 'Escolher no calendário',
                  icon: const Icon(Icons.event_outlined),
                  onPressed: _escolherNoCalendario,
                ),
              ),
            ),
            if (_feriado != null) ...[
              const SizedBox(height: 10),
              _AvisoFeriado(feriado: _feriado!),
            ],
            const SizedBox(height: 20),

            const RotuloSecao('Tipo de avaliação'),
            const SizedBox(height: 8),
            // Aula 08: grupo de Radio com enum, usando RadioGroup.
            RadioGroup<TipoAvaliacao>(
              groupValue: _tipo,
              onChanged: (valor) {
                if (valor != null) setState(() => _tipo = valor);
              },
              child: Row(
                children: [
                  for (final t in TipoAvaliacao.values) ...[
                    if (t != TipoAvaliacao.values.first) const SizedBox(width: 8),
                    Expanded(
                      child: _OpcaoTipo(
                        tipo: t,
                        selecionado: t == _tipo,
                        onTap: () => setState(() => _tipo = t),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Cores.royal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Cores.royal.withValues(alpha: 0.6),
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                icon: _salvando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(_salvando ? 'Salvando…' : 'Salvar na agenda'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card que se atualiza enquanto o aluno digita (setState).
class _PreVisualizacao extends StatelessWidget {
  const _PreVisualizacao({
    required this.disciplina,
    required this.professor,
    required this.sala,
    required this.data,
    required this.tipo,
    required this.estudados,
    required this.total,
  });

  final String disciplina;
  final String professor;
  final String sala;
  final DateTime? data;
  final TipoAvaliacao tipo;
  final int estudados;
  final int total;

  @override
  Widget build(BuildContext context) {
    final local = [
      if (professor.isNotEmpty) 'Prof. $professor',
      if (sala.isNotEmpty) sala,
    ].join(' · ');
    final d = data;

    return CartaoBranco(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          BlocoData(data: d, largura: 56, altura: 60),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Etiqueta(texto: tipo.rotulo, corFundo: tipo.corFundo, corTexto: tipo.corTexto),
                    Etiqueta(
                      texto: d == null ? 'Data inválida' : textoContagem(diasAte(d)),
                      corFundo: Cores.trilho,
                      corTexto: Cores.texto,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  disciplina.isEmpty ? 'Disciplina' : disciplina,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Cores.texto),
                ),
                if (local.isNotEmpty)
                  Text(
                    local,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Cores.textoSuave),
                  ),
                Text(
                  '$estudados de $total tópicos estudados',
                  style: const TextStyle(fontSize: 13, color: Cores.textoSuave),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Conteúdo da prova como lista de Checkbox + campo para novos tópicos.
class _ListaTopicos extends StatelessWidget {
  const _ListaTopicos({
    required this.topicos,
    required this.controller,
    required this.onMarcar,
    required this.onRemover,
    required this.onAdicionar,
  });

  final List<Topico> topicos;
  final TextEditingController controller;
  final void Function(int indice, bool valor) onMarcar;
  final ValueChanged<int> onRemover;
  final VoidCallback onAdicionar;

  @override
  Widget build(BuildContext context) {
    final estudados = topicos.where((t) => t.estudado).length;

    return CartaoBranco(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Marque o que já estudou',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Cores.textoSuave),
                ),
                Text(
                  '$estudados de ${topicos.length}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Cores.marinho),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Cores.trilho),
          for (var i = 0; i < topicos.length; i++)
            CheckboxListTile(
              value: topicos[i].estudado,
              onChanged: (valor) => onMarcar(i, valor ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Cores.royal,
              dense: true,
              title: Text(
                topicos[i].titulo,
                style: TextStyle(
                  fontSize: 15,
                  color: topicos[i].estudado ? Cores.textoSuave : Cores.texto,
                  decoration: topicos[i].estudado ? TextDecoration.lineThrough : null,
                ),
              ),
              secondary: IconButton(
                tooltip: 'Remover tópico',
                icon: const Icon(Icons.close, size: 18, color: Cores.textoSuave),
                onPressed: () => onRemover(i),
              ),
            ),
          const Divider(height: 1, color: Cores.trilho),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onSubmitted: (_) => onAdicionar(),
                    decoration: const InputDecoration(
                      labelText: 'Novo tópico',
                      hintText: 'Ex.: Consultas com JOIN',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Adicionar tópico',
                  onPressed: onAdicionar,
                  style: IconButton.styleFrom(
                    backgroundColor: Cores.gelo,
                    foregroundColor: Cores.marinho,
                  ),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Uma opção do grupo de Radio (o Radio pega o valor do RadioGroup acima).
class _OpcaoTipo extends StatelessWidget {
  const _OpcaoTipo({required this.tipo, required this.selecionado, required this.onTap});

  final TipoAvaliacao tipo;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionado ? Cores.gelo : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selecionado ? Cores.royal : Cores.bordaCampo,
          width: selecionado ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Radio<TipoAvaliacao>(
                value: tipo,
                activeColor: Cores.royal,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Text(
                tipo.rotulo,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Cores.texto),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvisoFeriado extends StatelessWidget {
  const _AvisoFeriado({required this.feriado});

  final Feriado feriado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Cores.alertaFundo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Cores.alertaBorda),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 20, color: Cores.alertaTexto),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${formatarDiaMes(feriado.data)} é feriado nacional (${feriado.nome}), '
              'segundo a BrasilAPI. Confirme a data com o professor.',
              style: const TextStyle(fontSize: 13, height: 1.4, color: Cores.alertaTexto),
            ),
          ),
        ],
      ),
    );
  }
}
