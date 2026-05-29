import 'package:flutter/foundation.dart';

@immutable
abstract class AbonoEvent {
  const AbonoEvent();
}

class LoadAbonosEvent extends AbonoEvent {
  final bool isAdmin;
  const LoadAbonosEvent({required this.isAdmin});
}

class SilentLoadAbonosEvent extends AbonoEvent {
  final bool isAdmin;
  const SilentLoadAbonosEvent({required this.isAdmin});
}

class SubscribeAdminAbonosEvent extends AbonoEvent {
  const SubscribeAdminAbonosEvent();
}

class SubmitAbonoEvent extends AbonoEvent {
  final String diaId;
  final String observacao;
  final String? dataInicio;
  final String? dataFim;
  final int? abonoMinutes;
  final bool isFullDay;
  final String? fileName;
  final Uint8List? fileBytes;

  const SubmitAbonoEvent({
    required this.diaId,
    required this.observacao,
    this.dataInicio,
    this.dataFim,
    this.abonoMinutes,
    this.isFullDay = false,
    this.fileName,
    this.fileBytes,
  });
}

class ApproveAbonoEvent extends AbonoEvent {
  final String abonoId;
  const ApproveAbonoEvent(this.abonoId);
}

class RejectAbonoEvent extends AbonoEvent {
  final String abonoId;
  final String? reason;
  const RejectAbonoEvent(this.abonoId, {this.reason});
}

class DeleteAbonoEvent extends AbonoEvent {
  final String abonoId;
  const DeleteAbonoEvent(this.abonoId);
}

class DismissReviewedAbonoEvent extends AbonoEvent {
  final String abonoId;
  const DismissReviewedAbonoEvent(this.abonoId);
}

class ResetAbonosEvent extends AbonoEvent {
  const ResetAbonosEvent();
}
