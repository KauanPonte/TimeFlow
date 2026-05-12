import 'dart:typed_data';

abstract class JustificativaEvent {
  const JustificativaEvent();
}

class LoadJustificativasEvent extends JustificativaEvent {
  final bool isAdmin;
  const LoadJustificativasEvent({this.isAdmin = false});
}

class SilentLoadJustificativasEvent extends JustificativaEvent {
  final bool isAdmin;
  const SilentLoadJustificativasEvent({this.isAdmin = true});
}

class SubmitJustificativaEvent extends JustificativaEvent {
  final String diaId;
  final String justificativa;
  final String? fileName;
  final Uint8List? fileBytes;
  final String? dataInicio;
  final String? dataFim;
  const SubmitJustificativaEvent({
    required this.diaId,
    required this.justificativa,
    this.fileName,
    this.fileBytes,
    this.dataInicio,
    this.dataFim,
  });
}

class ApproveJustificativaEvent extends JustificativaEvent {
  final String justificativaId;
  const ApproveJustificativaEvent(this.justificativaId);
}

class RejectJustificativaEvent extends JustificativaEvent {
  final String justificativaId;
  final String? reason;
  const RejectJustificativaEvent(this.justificativaId, {this.reason});
}

class DismissReviewedJustificativaEvent extends JustificativaEvent {
  final String justificativaId;
  const DismissReviewedJustificativaEvent(this.justificativaId);
}

class ResetJustificativasEvent extends JustificativaEvent {
  const ResetJustificativasEvent();
}
