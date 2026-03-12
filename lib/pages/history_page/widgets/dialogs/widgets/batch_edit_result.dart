/// Resultado retornado pelo diálogo de edição em lote.
class BatchEditResult {
  /// Eventos que devem ser atualizados (id + novo tipo + novo horário).
  final List<Map<String, dynamic>> updates;

  /// Eventos que devem ser removidos (apenas id).
  final List<String> deletes;

  /// Novos eventos a serem adicionados (tipo + horário).
  final List<Map<String, dynamic>> adds;

  const BatchEditResult({
    required this.updates,
    required this.deletes,
    required this.adds,
  });

  bool get isEmpty => updates.isEmpty && deletes.isEmpty && adds.isEmpty;
}
