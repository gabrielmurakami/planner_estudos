import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/datas.dart';

class Feriado {
  const Feriado(this.data, this.nome);

  final DateTime data;
  final String nome;
}

/// Recurso adicional (RF09): consulta os feriados nacionais na BrasilAPI
/// usando o pacote http. Documentação: https://brasilapi.com.br/docs#tag/Feriados-Nacionais
///
/// Exemplo de resposta de GET /api/feriados/v1/2026:
/// [ {"date": "2026-11-20", "name": "Dia da Consciência Negra", "type": "national"}, ... ]
class FeriadosService {
  FeriadosService._();

  static final Map<int, Future<List<Feriado>>> _cache = {};

  /// Lista de feriados do ano (cada ano é consultado uma única vez).
  static Future<List<Feriado>> doAno(int ano) =>
      _cache.putIfAbsent(ano, () => _buscar(ano));

  static Future<List<Feriado>> _buscar(int ano) async {
    try {
      final url = Uri.parse('https://brasilapi.com.br/api/feriados/v1/$ano');
      final resposta = await http.get(url).timeout(const Duration(seconds: 8));
      if (resposta.statusCode != 200) {
        throw Exception('BrasilAPI respondeu ${resposta.statusCode}');
      }
      final lista = jsonDecode(utf8.decode(resposta.bodyBytes)) as List<dynamic>;
      return lista.map((item) {
        final mapa = item as Map<String, dynamic>;
        final partes = (mapa['date'] as String).split('-');
        final data = DateTime(
          int.parse(partes[0]),
          int.parse(partes[1]),
          int.parse(partes[2]),
        );
        return Feriado(data, mapa['name'] as String);
      }).toList();
    } catch (_) {
      // Se falhar (sem internet, por exemplo), permite tentar de novo depois.
      _cache.remove(ano);
      rethrow;
    }
  }

  /// O feriado que cai em [data], ou null se for dia comum.
  static Future<Feriado?> naData(DateTime data) async {
    final lista = await doAno(data.year);
    for (final f in lista) {
      if (mesmoDia(f.data, data)) return f;
    }
    return null;
  }

  /// O próximo feriado a partir de hoje.
  static Future<Feriado?> proximo() async {
    final hoje = DateTime.now();
    for (final ano in [hoje.year, hoje.year + 1]) {
      final lista = await doAno(ano);
      for (final f in lista) {
        if (diasAte(f.data, hoje) >= 0) return f;
      }
    }
    return null;
  }
}
