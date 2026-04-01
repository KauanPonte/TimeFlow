import 'package:cloud_firestore/cloud_firestore.dart';

enum JustificativaStatus { pending, approved, rejected }

class JustificativaModel {
  final String id;
  final String uid;
  final String employeeName;
  final String diaId; // 'yyyy-MM-dd'
  final String justificativa; // texto da justificativa
  final JustificativaStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy; // uid do admin
  final String? reason; // observação do admin ao recusar
  final bool seenByEmployee;

  const JustificativaModel({
    required this.id,
    required this.uid,
    required this.employeeName,
    required this.diaId,
    required this.justificativa,
    this.status = JustificativaStatus.pending,
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
        'justificativa': justificativa,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
        'resolvedBy': resolvedBy,
        'reason': reason,
        'seenByEmployee': seenByEmployee,
      };

  factory JustificativaModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return JustificativaModel(
      id: doc.id,
      uid: (data['uid'] ?? '').toString(),
      employeeName: (data['employeeName'] ?? '').toString(),
      diaId: (data['diaId'] ?? '').toString(),
      justificativa: (data['justificativa'] ?? '').toString(),
      status: JustificativaStatus.values.byName(
        (data['status'] ?? 'pending').toString(),
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      resolvedBy: data['resolvedBy'] as String?,
      reason: data['reason'] as String?,
      seenByEmployee: (data['seenByEmployee'] as bool?) ?? false,
    );
  }

  JustificativaModel copyWith({
    String? id,
    String? uid,
    String? employeeName,
    String? diaId,
    String? justificativa,
    JustificativaStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? resolvedBy,
    String? reason,
    bool? seenByEmployee,
  }) {
    return JustificativaModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      employeeName: employeeName ?? this.employeeName,
      diaId: diaId ?? this.diaId,
      justificativa: justificativa ?? this.justificativa,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      reason: reason ?? this.reason,
      seenByEmployee: seenByEmployee ?? this.seenByEmployee,
    );
  }
}
