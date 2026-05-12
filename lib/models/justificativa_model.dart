import 'dart:typed_data';
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
  final String? fileName;
  final Uint8List? fileBytes;
  final String? dataInicio;
  final String? dataFim;

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
    this.fileName,
    this.fileBytes,
    this.dataInicio,
    this.dataFim,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'employeeName': employeeName,
        'diaId': diaId,
        'justificativa': justificativa,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'resolvedAt':
            resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
        'resolvedBy': resolvedBy,
        'reason': reason,
        'seenByEmployee': seenByEmployee,
        'fileName': fileName,
        'fileBytes': fileBytes,
        'dataInicio': dataInicio,
        'dataFim': dataFim,
      };

  factory JustificativaModel.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
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
      fileName: data['fileName'] as String?,
      fileBytes: data['fileBytes'] as Uint8List?,
      dataInicio: data['dataInicio'] as String?,
      dataFim: data['dataFim'] as String?,
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
    String? fileName,
    Uint8List? fileBytes,
    String? dataInicio,
    String? dataFim,
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
      fileName: fileName ?? this.fileName,
      fileBytes: fileBytes ?? this.fileBytes,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
    );
  }
}
