import 'package:cloud_firestore/cloud_firestore.dart';

enum AtestadoStatus { pending, approved, rejected }

class AtestadoModel {
  final String id;
  final String uid;
  final String employeeName;
  final String dataInicio; // 'yyyy-MM-dd'
  final String dataFim; // 'yyyy-MM-dd'
  final String fileName;
  final String? fileUrl;
  final AtestadoStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? reason;
  final bool seenByEmployee;

  const AtestadoModel({
    required this.id,
    required this.uid,
    required this.employeeName,
    required this.dataInicio,
    required this.dataFim,
    required this.fileName,
    this.fileUrl,
    this.status = AtestadoStatus.pending,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.reason,
    this.seenByEmployee = false,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'employeeName': employeeName,
        'dataInicio': dataInicio,
        'dataFim': dataFim,
        'fileName': fileName,
        'fileUrl': fileUrl,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
        'resolvedBy': resolvedBy,
        'reason': reason,
        'seenByEmployee': seenByEmployee,
      };

  factory AtestadoModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AtestadoModel(
      id: doc.id,
      uid: (data['uid'] ?? '').toString(),
      employeeName: (data['employeeName'] ?? '').toString(),
      dataInicio: (data['dataInicio'] ?? '').toString(),
      dataFim: (data['dataFim'] ?? '').toString(),
      fileName: (data['fileName'] ?? '').toString(),
      fileUrl: data['fileUrl'] as String?,
      status: AtestadoStatus.values.byName(
        (data['status'] ?? 'pending').toString(),
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      resolvedBy: data['resolvedBy'] as String?,
      reason: data['reason'] as String?,
      seenByEmployee: (data['seenByEmployee'] as bool?) ?? false,
    );
  }

  AtestadoModel copyWith({
    String? id,
    String? uid,
    String? employeeName,
    String? dataInicio,
    String? dataFim,
    String? fileName,
    String? fileUrl,
    AtestadoStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? resolvedBy,
    String? reason,
    bool? seenByEmployee,
  }) {
    return AtestadoModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      employeeName: employeeName ?? this.employeeName,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      reason: reason ?? this.reason,
      seenByEmployee: seenByEmployee ?? this.seenByEmployee,
    );
  }
}
