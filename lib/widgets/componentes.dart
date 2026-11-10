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
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Cores.borda),
      ),
      child: child,
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
