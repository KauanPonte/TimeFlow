abstract class JustificativaEvent {
  const JustificativaEvent();
}

class LoadJustificativasEvent extends JustificativaEvent {
  final bool isAdmin;
  const LoadJustificativasEvent({this.isAdmin = false});
}

class SilentLoadJustificativasEvent extends JustificativaEvent {
  const SilentLoadJustificativasEvent();
}

class SubmitJustificativaEvent extends JustificativaEvent {
  final String diaId;
  final String justificativa;
  const SubmitJustificativaEvent({
    required this.diaId,
    required this.justificativa,
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
