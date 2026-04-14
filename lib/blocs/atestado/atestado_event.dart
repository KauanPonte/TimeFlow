import 'dart:typed_data';

abstract class AtestadoEvent {
  const AtestadoEvent();
}

class LoadAtestadosEvent extends AtestadoEvent {
  final bool isAdmin;
  final bool includeReviewed;

  const LoadAtestadosEvent({
    this.isAdmin = false,
    this.includeReviewed = false,
  });
}

class SubmitAtestadoEvent extends AtestadoEvent {
  final String dataInicio;
  final String dataFim;
  final String fileName;
  final Uint8List fileBytes;

  const SubmitAtestadoEvent({
    required this.dataInicio,
    required this.dataFim,
    required this.fileName,
    required this.fileBytes,
  });
}

class ApproveAtestadoEvent extends AtestadoEvent {
  final String atestadoId;
  const ApproveAtestadoEvent(this.atestadoId);
}

class RejectAtestadoEvent extends AtestadoEvent {
  final String atestadoId;
  final String? reason;
  const RejectAtestadoEvent(this.atestadoId, {this.reason});
}

class SilentLoadAtestadosEvent extends AtestadoEvent {
  final bool isAdmin;
  final bool includeReviewed;

  const SilentLoadAtestadosEvent({
    this.isAdmin = true,
    this.includeReviewed = false,
  });
}

class ResetAtestadosEvent extends AtestadoEvent {
  const ResetAtestadosEvent();
}

class DismissReviewedAtestadoEvent extends AtestadoEvent {
  final String atestadoId;
  const DismissReviewedAtestadoEvent(this.atestadoId);
}
