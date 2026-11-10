/// Funções de data usadas nas três telas.
library;

const _meses = [
  'JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN',
  'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ',
];
const _diasSemana = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

String doisDigitos(int n) => n.toString().padLeft(2, '0');

String mesAbreviado(DateTime d) => _meses[d.month - 1];

/// 20/11
String formatarDiaMes(DateTime d) => '${doisDigitos(d.day)}/${doisDigitos(d.month)}';

/// 20/11/2026
String formatarDataCompleta(DateTime d) => '${formatarDiaMes(d)}/${d.year}';

/// sex, 20/11
String diaSemanaEData(DateTime d) => '${_diasSemana[d.weekday - 1]}, ${formatarDiaMes(d)}';

/// Lê "dd/mm/aaaa". Devolve null se o texto não for uma data válida.
DateTime? lerData(String texto) {
  final m = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(texto.trim());
  if (m == null) return null;
  final dia = int.parse(m.group(1)!);
  final mes = int.parse(m.group(2)!);
  final ano = int.parse(m.group(3)!);
  if (mes < 1 || mes > 12 || dia < 1) return null;
  final data = DateTime(ano, mes, dia);
  // DateTime(2026, 2, 31) vira 03/03: isso indica data inexistente.
  if (data.month != mes || data.day != dia) return null;
  return data;
}

/// Quantos dias faltam de hoje até [data] (negativo = já passou).
int diasAte(DateTime data, [DateTime? agora]) {
  final hoje = agora ?? DateTime.now();
  final a = DateTime.utc(hoje.year, hoje.month, hoje.day);
  final b = DateTime.utc(data.year, data.month, data.day);
  return b.difference(a).inDays;
}

String textoContagem(int dias) {
  if (dias > 1) return 'em $dias dias';
  if (dias == 1) return 'amanhã';
  if (dias == 0) return 'hoje';
  return 'já passou';
}

bool mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
