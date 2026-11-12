import 'package:flutter/material.dart';

import '../theme/cores.dart';
import '../utils/datas.dart';

/// Bloco com dia e mês (ex.: 20 / NOV) usado nos cards de prova.
class BlocoData extends StatelessWidget {
  const BlocoData({
    super.key,
    required this.data,
    this.escuro = true,
    this.largura = 52,
    this.altura = 56,
  });

  final DateTime? data;
  final bool escuro;
  final double largura;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final d = data;
    return Container(
      width: largura,
      height: altura,
      decoration: BoxDecoration(
        color: escuro ? Cores.marinho : Cores.gelo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            d == null ? '--' : doisDigitos(d.day),
            style: TextStyle(
              fontSize: largura > 50 ? 20 : 16,
              fontWeight: FontWeight.w700,
              height: 1,
              color: escuro ? Colors.white : Cores.marinho,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            d == null ? '---' : mesAbreviado(d),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: escuro ? Cores.celeste : Cores.marinho,
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta arredondada (NP1, NP2, Exame, Feriado...).
class Etiqueta extends StatelessWidget {
  const Etiqueta({
    super.key,
    required this.texto,
    required this.corFundo,
    required this.corTexto,
    this.corBorda,
  });

  final String texto;
  final Color corFundo;
  final Color corTexto;
  final Color? corBorda;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(999),
        border: corBorda == null ? null : Border.all(color: corBorda!),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: corTexto),
      ),
    );
  }
}

/// Card branco com borda azul-clara, padrão das telas.
class CartaoBranco extends StatelessWidget {
  const CartaoBranco({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    // O Material transparente dá aos ListTile/InkWell filhos uma superfície
    // própria para desenhar o splash por cima do fundo branco do Container.
    return Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Cores.borda),
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

/// Barra de progresso de tópicos estudados.
class BarraProgresso extends StatelessWidget {
  const BarraProgresso({super.key, required this.valor});

  final double valor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: valor,
        minHeight: 6,
        backgroundColor: Cores.trilho,
        color: Cores.vivo,
      ),
    );
  }
}

/// Título pequeno de seção (ex.: "Conteúdo da prova").
class RotuloSecao extends StatelessWidget {
  const RotuloSecao(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Cores.texto),
    );
  }
}

/// AppBar padrão das telas: título em branco, centralizado, fundo azul royal.
AppBar barraDoApp(String titulo, {List<Widget>? actions}) {
  return AppBar(
    title: Text(
      titulo,
      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: Colors.white),
    ),
    centerTitle: true,
    backgroundColor: Cores.royal,
    foregroundColor: Colors.white,
    actions: actions,
  );
}

/// Linha de tópico com Checkbox; riscada quando o tópico já foi estudado.
/// [acaoExtra] aparece à direita (ex.: botão de remover no formulário).
class ItemTopico extends StatelessWidget {
  const ItemTopico({
    super.key,
    required this.titulo,
    required this.estudado,
    required this.onChanged,
    this.acaoExtra,
    this.tamanhoFonte = 15,
  });

  final String titulo;
  final bool estudado;
  final ValueChanged<bool> onChanged;
  final Widget? acaoExtra;
  final double tamanhoFonte;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: estudado,
      onChanged: (valor) => onChanged(valor ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Cores.royal,
      dense: true,
      secondary: acaoExtra,
      title: Text(
        titulo,
        style: TextStyle(
          fontSize: tamanhoFonte,
          color: estudado ? Cores.textoSuave : Cores.texto,
          decoration: estudado ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }
}

/// Mensagem centralizada para quando a leitura do Firestore falha.
class MensagemErro extends StatelessWidget {
  const MensagemErro({super.key, required this.erro});

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

/// Mostra uma mensagem rápida na parte de baixo da tela.
void mostrarAviso(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
}
