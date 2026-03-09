/// Validador centralizado de regras de negócio para registros de ponto.
///
/// Regras:
/// 1. O primeiro ponto do dia deve ser "entrada".
/// 2. Após "entrada": "pausa" ou "saída".
/// 3. Após "pausa": obrigatoriamente "retorno" (não pode sair sem retorno).
/// 4. Após "retorno": "pausa" ou "saída".
/// 5. Não pode haver duas pausas seguidas — devem intercalar com retorno.
/// 6. Diferença mínima de 1 minuto entre cada ponto.
/// 7. Horários devem ser cronológicos (saída > entrada, retorno > pausa, etc.).
class PontoValidator {
  static const tiposValidos = ['entrada', 'pausa', 'retorno', 'saida'];

  /// Valida a sequência completa de eventos de um dia.
  /// Retorna `null` se válida ou uma mensagem de erro.
  static String? validarSequenciaCompleta(List<Map<String, dynamic>> eventos) {
    if (eventos.isEmpty) return null;

    // Ordena por horário
    final sorted = List<Map<String, dynamic>>.from(eventos)
      ..sort((a, b) {
        final atA = _toDateTime(a['at']);
        final atB = _toDateTime(b['at']);
        if (atA == null || atB == null) return 0;
        return atA.compareTo(atB);
      });

    // Primeiro evento deve ser "entrada"
    final primeiro = (sorted.first['tipo'] ?? '').toString();
    if (primeiro != 'entrada') {
      return 'O primeiro ponto do dia precisa ser "Entrada".';
    }

    for (int i = 0; i < sorted.length; i++) {
      final tipo = (sorted[i]['tipo'] ?? '').toString();

      if (!tiposValidos.contains(tipo)) {
        return 'Tipo inválido: "$tipo".';
      }

      if (i > 0) {
        final prevTipo = (sorted[i - 1]['tipo'] ?? '').toString();
        final prevAt = _toDateTime(sorted[i - 1]['at']);
        final currAt = _toDateTime(sorted[i]['at']);

        // Regra de transição
        final transErr = _validarTransicao(prevTipo, tipo);
        if (transErr != null) return transErr;

        // Ordem cronológica e intervalo mínimo de 1 minuto
        if (prevAt != null && currAt != null) {
          if (!currAt.isAfter(prevAt)) {
            return 'O horário de "${_label(tipo)}" deve ser posterior '
                'ao de "${_label(prevTipo)}".';
          }
          if (currAt.difference(prevAt).inSeconds < 60) {
            return 'A diferença entre "${_label(prevTipo)}" e '
                '"${_label(tipo)}" deve ser de no mínimo 1 minuto.';
          }
        }
      }
    }

    return null;
  }

  /// Valida a adição de um novo evento à lista existente.
  static String? validarNovoEvento({
    required List<Map<String, dynamic>> eventosExistentes,
    required String novoTipo,
    required DateTime novoHorario,
  }) {
    if (!tiposValidos.contains(novoTipo)) {
      return 'Tipo inválido: "$novoTipo".';
    }

    final novosEventos = [
      ...eventosExistentes.map((e) => Map<String, dynamic>.from(e)),
      {'tipo': novoTipo, 'at': novoHorario},
    ];
    return validarSequenciaCompleta(novosEventos);
  }

  /// Valida a edição de um evento existente (substitui pelo novo tipo/horário).
  static String? validarEdicaoEvento({
    required List<Map<String, dynamic>> eventosExistentes,
    required String eventoId,
    required String novoTipo,
    required DateTime novoHorario,
  }) {
    if (!tiposValidos.contains(novoTipo)) {
      return 'Tipo inválido: "$novoTipo".';
    }

    final novosEventos = eventosExistentes.map((e) {
      if (e['id'] == eventoId) {
        return {
          'id': eventoId,
          'tipo': novoTipo,
          'at': novoHorario,
        };
      }
      return Map<String, dynamic>.from(e);
    }).toList();

    return validarSequenciaCompleta(novosEventos);
  }

  /// Valida se a remoção de um evento deixa a sequência do dia consistente.
  /// Retorna `null` se válida ou uma mensagem de erro.
  static String? validarExclusaoEvento({
    required List<Map<String, dynamic>> eventosExistentes,
    required String eventoId,
  }) {
    final aposExclusao =
        eventosExistentes.where((e) => e['id'] != eventoId).toList();
    // Lista vazia é sempre válida (dia sem registros)
    if (aposExclusao.isEmpty) return null;
    return validarSequenciaCompleta(aposExclusao);
  }

  /// Retorna os tipos de ponto que podem ser registrados em seguida,
  /// dado o último tipo registrado.
  static Set<String> proximosPermitidos(String? ultimoTipo) {
    if (ultimoTipo == null) return {'entrada'};
    switch (ultimoTipo) {
      case 'entrada':
        return {'pausa', 'saida'};
      case 'pausa':
        return {'retorno'}; // obrigatório retornar antes de sair
      case 'retorno':
        return {'pausa', 'saida'};
      case 'saida':
        return {}; // expediente encerrado
      default:
        return {};
    }
  }

  static String? _validarTransicao(String ultimo, String novo) {
    switch (ultimo) {
      case 'entrada':
        if (novo != 'pausa' && novo != 'saida') {
          return 'Após "${_label(ultimo)}", só é possível registrar '
              '"Pausa" ou "Saída".';
        }
        break;
      case 'pausa':
        if (novo != 'retorno') {
          return 'Após "${_label(ultimo)}", é obrigatório registrar '
              '"Retorno" antes de qualquer outro ponto.';
        }
        break;
      case 'retorno':
        if (novo != 'pausa' && novo != 'saida') {
          return 'Após "${_label(ultimo)}", só é possível registrar '
              '"Pausa" ou "Saída".';
        }
        break;
      case 'saida':
        if (novo != 'entrada') {
          return 'O expediente já foi encerrado com "Saída". '
              'Só é possível registrar uma nova "Entrada".';
        }
        break;
      default:
        return 'Tipo anterior inválido: "$ultimo".';
    }
    return null;
  }

  static String _label(String tipo) {
    switch (tipo) {
      case 'entrada':
        return 'Entrada';
      case 'pausa':
        return 'Pausa';
      case 'retorno':
        return 'Retorno';
      case 'saida':
        return 'Saída';
      default:
        return tipo;
    }
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is DateTime) return value;
    return null;
  }
}
