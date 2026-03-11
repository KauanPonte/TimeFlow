import 'package:cloud_firestore/cloud_firestore.dart';

/// Status possíveis de uma solicitação de alteração de ponto.
enum SolicitationStatus { pending, approved, rejected, cancelled }

/// Status individual de cada item (evento) dentro da solicitação.
enum SolicitationItemStatus { pending, accepted, rejected }

/// Ação solicitada para um evento.
enum SolicitationAction { add, edit, delete }

/// Um item (evento individual) dentro de uma solicitação.
class SolicitationItem {
  final String? eventoId; // null para adição
  final SolicitationAction action;
  final String tipo;
  final DateTime horario;
  // Dados anteriores (para edição / exclusão)
  final String? oldTipo;
  final DateTime? oldHorario;
  SolicitationItemStatus status;

  SolicitationItem({
    this.eventoId,
    required this.action,
    required this.tipo,
    required this.horario,
    this.oldTipo,
    this.oldHorario,
    this.status = SolicitationItemStatus.pending,
  });

  Map<String, dynamic> toMap() => {
        'eventoId': eventoId,
        'action': action.name,
        'tipo': tipo,
        'horario': Timestamp.fromDate(horario),
        'oldTipo': oldTipo,
        'oldHorario':
            oldHorario != null ? Timestamp.fromDate(oldHorario!) : null,
        'status': status.name,
      };

  factory SolicitationItem.fromMap(Map<String, dynamic> map) {
    return SolicitationItem(
      eventoId: map['eventoId'] as String?,
      action: SolicitationAction.values.byName(map['action'] as String),
      tipo: (map['tipo'] ?? '').toString(),
      horario: (map['horario'] as Timestamp).toDate(),
      oldTipo: map['oldTipo'] as String?,
      oldHorario: map['oldHorario'] != null
          ? (map['oldHorario'] as Timestamp).toDate()
          : null,
      status: SolicitationItemStatus.values
          .byName((map['status'] ?? 'pending').toString()),
    );
  }

  SolicitationItem copyWith({
    String? eventoId,
    SolicitationAction? action,
    String? tipo,
    DateTime? horario,
    String? oldTipo,
    DateTime? oldHorario,
    SolicitationItemStatus? status,
  }) {
    return SolicitationItem(
      eventoId: eventoId ?? this.eventoId,
      action: action ?? this.action,
      tipo: tipo ?? this.tipo,
      horario: horario ?? this.horario,
      oldTipo: oldTipo ?? this.oldTipo,
      oldHorario: oldHorario ?? this.oldHorario,
      status: status ?? this.status,
    );
  }
}

/// Modelo completo de uma solicitação.
class SolicitationModel {
  final String id;
  final String uid; // uid do funcionário solicitante
  final String employeeName;
  final String diaId; // ex: '2026-03-10'
  final List<SolicitationItem> items;
  final SolicitationStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy; // uid do admin
  final String? reason; // observação
  final bool seenByEmployee; // funcionário marcou como visto

  SolicitationModel({
    required this.id,
    required this.uid,
    required this.employeeName,
    required this.diaId,
    required this.items,
    this.status = SolicitationStatus.pending,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.reason,
    this.seenByEmployee = false,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'employeeName': employeeName,
        'diaId': diaId,
        'items': items.map((i) => i.toMap()).toList(),
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'resolvedAt':
            resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
        'resolvedBy': resolvedBy,
        'reason': reason,
        'seenByEmployee': seenByEmployee,
      };

  factory SolicitationModel.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SolicitationModel(
      id: doc.id,
      uid: (data['uid'] ?? '').toString(),
      employeeName: (data['employeeName'] ?? '').toString(),
      diaId: (data['diaId'] ?? '').toString(),
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => SolicitationItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      status: SolicitationStatus.values
          .byName((data['status'] ?? 'pending').toString()),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      resolvedBy: data['resolvedBy'] as String?,
      reason: data['reason'] as String?,
      seenByEmployee: (data['seenByEmployee'] as bool?) ?? false,
    );
  }

  SolicitationModel copyWith({
    String? id,
    String? uid,
    String? employeeName,
    String? diaId,
    List<SolicitationItem>? items,
    SolicitationStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? resolvedBy,
    String? reason,
    bool? seenByEmployee,
  }) {
    return SolicitationModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      employeeName: employeeName ?? this.employeeName,
      diaId: diaId ?? this.diaId,
      items: items ?? this.items,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      reason: reason ?? this.reason,
      seenByEmployee: seenByEmployee ?? this.seenByEmployee,
    );
  }
}
