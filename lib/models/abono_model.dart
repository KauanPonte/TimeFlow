import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_appdeponto/services/server_time_service.dart';

enum AbonoStatus { pending, approved, rejected }

class AbonoModel {
  final String id;
  final String uid;
  final String employeeName;
  final String diaId;
  final AbonoStatus status;
  final int abonoMinutes;
  final bool isFullDay;
  final String observacao;
  final String? dataInicio;
  final String? dataFim;
  final String? fileName;
  final String? fileUrl;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? rejectionReason;
  final bool seenByEmployee;

  const AbonoModel({
    required this.id,
    required this.uid,
    required this.employeeName,
    required this.diaId,
    this.status = AbonoStatus.pending,
    required this.abonoMinutes,
    this.isFullDay = false,
    required this.observacao,
    this.dataInicio,
    this.dataFim,
    this.fileName,
    this.fileUrl,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.rejectionReason,
    this.seenByEmployee = false,
  });

  factory AbonoModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AbonoModel(
      id: doc.id,
      uid: (data['uid'] ?? '').toString(),
      employeeName: (data['employeeName'] ?? '').toString(),
      diaId: (data['diaId'] ?? '').toString(),
      status: AbonoStatus.values.byName(
        (data['status'] ?? 'pending').toString(),
      ),
      abonoMinutes: (data['abonoMinutes'] as int?) ?? 0,
      isFullDay: (data['isFullDay'] as bool?) ?? false,
      observacao: (data['observacao'] ?? '').toString(),
      dataInicio: data['dataInicio'] as String?,
      dataFim: data['dataFim'] as String?,
      fileName: data['fileName'] as String?,
      fileUrl: data['fileUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          ServerTimeService.nowUtc(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      resolvedBy: data['resolvedBy'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      seenByEmployee: (data['seenByEmployee'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'employeeName': employeeName,
        'diaId': diaId,
        'status': status.name,
        'abonoMinutes': abonoMinutes,
        'isFullDay': isFullDay,
        'observacao': observacao,
        'dataInicio': dataInicio,
        'dataFim': dataFim,
        'fileName': fileName,
        'fileUrl': fileUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
        'resolvedBy': resolvedBy,
        'rejectionReason': rejectionReason,
        'seenByEmployee': seenByEmployee,
      };

  AbonoModel copyWith({
    String? id,
    String? uid,
    String? employeeName,
    String? diaId,
    AbonoStatus? status,
    int? abonoMinutes,
    bool? isFullDay,
    String? observacao,
    String? dataInicio,
    String? dataFim,
    String? fileName,
    String? fileUrl,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? resolvedBy,
    String? rejectionReason,
    bool? seenByEmployee,
  }) {
    return AbonoModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      employeeName: employeeName ?? this.employeeName,
      diaId: diaId ?? this.diaId,
      status: status ?? this.status,
      abonoMinutes: abonoMinutes ?? this.abonoMinutes,
      isFullDay: isFullDay ?? this.isFullDay,
      observacao: observacao ?? this.observacao,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      seenByEmployee: seenByEmployee ?? this.seenByEmployee,
    );
  }
}
