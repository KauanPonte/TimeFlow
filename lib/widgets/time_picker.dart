import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';

/// Exibe um seletor de horário 24 h com relógio analógico customizado.
///
/// Layout corrigido:
///   Anel externo → 12, 1, 2 … 11
///   Anel interno → 00, 13, 14 … 23
///
/// Retorna o [TimeOfDay] escolhido, ou `null` se o usuário cancelar.
Future<TimeOfDay?> showTimePicker24h(
  BuildContext context,
  TimeOfDay initial,
) {
  return showDialog<TimeOfDay>(
    context: context,
    barrierColor: Colors.black45,
    builder: (_) => _TimePickerDialog(initialTime: initial),
  );
}

//  Dialog

class _TimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  const _TimePickerDialog({required this.initialTime});

  @override
  State<_TimePickerDialog> createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<_TimePickerDialog> {
  late int _hour;
  late int _minute;
  bool _selectingHour = true;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
  }

  String get _hStr => _hour.toString().padLeft(2, '0');
  String get _mStr => _minute.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildClock(),
            _buildModeRow(),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  // Header

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded,
                  size: 15, color: Colors.white.withValues(alpha: 0.75)),
              const SizedBox(width: 6),
              Text(
                'Selecionar horário',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _HeaderUnit(
                text: _hStr,
                label: 'HORA',
                active: _selectingHour,
                onTap: () => setState(() => _selectingHour = true),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w200,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1,
                  ),
                ),
              ),
              _HeaderUnit(
                text: _mStr,
                label: 'MIN',
                active: !_selectingHour,
                onTap: () => setState(() => _selectingHour = false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Clock

  Widget _buildClock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
      child: _ClockDial(
        hour: _hour,
        minute: _minute,
        selectingHour: _selectingHour,
        onHourChanged: (h) {
          HapticFeedback.selectionClick();
          setState(() => _hour = h);
        },
        onMinuteChanged: (m) {
          HapticFeedback.selectionClick();
          setState(() => _minute = m);
        },
        onHourFinished: () {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) setState(() => _selectingHour = false);
          });
        },
      ),
    );
  }

  // Mode row

  Widget _buildModeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ModeChip(
            label: 'Hora',
            active: _selectingHour,
            onTap: () => setState(() => _selectingHour = true),
          ),
          const SizedBox(width: 8),
          _ModeChip(
            label: 'Minuto',
            active: !_selectingHour,
            onTap: () => setState(() => _selectingHour = false),
          ),
        ],
      ),
    );
  }

  // Actions

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 4),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () =>
                Navigator.pop(context, TimeOfDay(hour: _hour, minute: _minute)),
            child:
                const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

//  Header unit widget (HH or MM block)

class _HeaderUnit extends StatelessWidget {
  final String text;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _HeaderUnit({
    required this.text,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withValues(alpha: 0.22)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.w300,
                color: active
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.45),
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.0,
              color: active
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.4),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

//  Mode chip (Hora / Minuto pills)

class _ModeChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.primary.withValues(alpha: 0.5)
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.primary : Colors.grey.shade500,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

//  Clock Dial (gestos + paint)

class _ClockDial extends StatefulWidget {
  final int hour;
  final int minute;
  final bool selectingHour;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;
  final VoidCallback onHourFinished;

  const _ClockDial({
    required this.hour,
    required this.minute,
    required this.selectingHour,
    required this.onHourChanged,
    required this.onMinuteChanged,
    required this.onHourFinished,
  });

  @override
  State<_ClockDial> createState() => _ClockDialState();
}

class _ClockDialState extends State<_ClockDial> with TickerProviderStateMixin {
  static const double _kSize = 260;
  static const double _kMinDist = 18;

  // Hand sweep animation
  late AnimationController _handCtrl;
  double _handFrom = 0;
  double _handTo = 0;

  // Mode fade animation (numbers + hand fade out/in on mode switch)
  late AnimationController _modeCtrl;
  // The mode currently being painted — lags behind widget.selectingHour during transition
  late bool _paintMode;
// whether hand is on inner ring (hour mode only)

  // Ring emphasis animation (0.0 = outer ring ativo, 1.0 = inner ring ativo)
  late AnimationController _ringCtrl;

  @override
  void initState() {
    super.initState();
    _paintMode = widget.selectingHour;

    _handCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _handFrom = _angleFor(widget.selectingHour, widget.hour, widget.minute);
    _handTo = _handFrom;
    _handCtrl.value = 1.0;

    _modeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _modeCtrl.value = 1.0;

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _ringCtrl.value = _isInnerRing(widget.hour) ? 1.0 : 0.0;
  }

  @override
  void dispose() {
    _handCtrl.dispose();
    _modeCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  // Geometry helpers

  static bool _isInnerRing(int h) => h == 0 || h >= 13;

  static int _hourToPos(int h) {
    if (h == 0 || h == 12) return 0;
    return h > 12 ? h - 12 : h;
  }

  static double _angleFor(bool isHour, int hour, int minute) {
    if (isHour) return _hourToPos(hour) * 2 * pi / 12 - pi / 2;
    return minute * 2 * pi / 60 - pi / 2;
  }

  // Hand sweep

  void _animateHandTo(double newAngle) {
    // Current instantaneous angle (mid-animation)
    final current = _handFrom +
        (_handTo - _handFrom) * Curves.easeOut.transform(_handCtrl.value);
    // Shortest angular path
    double delta = newAngle - current;
    while (delta > pi) {
      delta -= 2 * pi;
    }
    while (delta < -pi) {
      delta += 2 * pi;
    }
    _handFrom = current;
    _handTo = current + delta;
    _handCtrl.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant _ClockDial old) {
    super.didUpdateWidget(old);

    final modeChanged = old.selectingHour != widget.selectingHour;
    final valueChanged = old.hour != widget.hour || old.minute != widget.minute;

    if (modeChanged) {
      // Fade out → swap content → fade in
      _modeCtrl.animateTo(0, curve: Curves.easeIn).then((_) {
        if (!mounted) return;
        setState(() {
          _paintMode = widget.selectingHour;
          // Snap ring emphasis sem animação ao trocar modo hora/minuto
          _ringCtrl.value = _isInnerRing(widget.hour) ? 1.0 : 0.0;
          // Jump hand to new mode position (no sweep needed across modes)
          final a = _angleFor(widget.selectingHour, widget.hour, widget.minute);
          _handFrom = a;
          _handTo = a;
          _handCtrl.value = 1.0;
        });
        _modeCtrl.animateTo(1, curve: Curves.easeOut);
      });
    } else if (valueChanged) {
      final newInner = _isInnerRing(widget.hour);
      // Anima a transição de destaque entre anel externo e interno
      _ringCtrl.animateTo(newInner ? 1.0 : 0.0, curve: Curves.easeInOut);
      _animateHandTo(
          _angleFor(widget.selectingHour, widget.hour, widget.minute));
    }
  }

  // Touch handling

  void _handleTouch(Offset local) {
    const center = Offset(_kSize / 2, _kSize / 2);
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < _kMinDist) return;

    var angle = atan2(dx, -dy);
    if (angle < 0) angle += 2 * pi;

    widget.selectingHour ? _pickHour(angle, dist) : _pickMinute(angle);
  }

  void _pickHour(double angle, double dist) {
    final pos = (angle / (2 * pi) * 12).round() % 12;
    final isInner = dist < _kSize / 2 * 0.68;
    final hour = isInner ? (pos == 0 ? 0 : pos + 12) : (pos == 0 ? 12 : pos);
    widget.onHourChanged(hour);
  }

  void _pickMinute(double angle) {
    widget.onMinuteChanged((angle / (2 * pi) * 60).round() % 60);
  }

  // Build

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kSize,
      height: _kSize,
      child: GestureDetector(
        onPanStart: (d) => _handleTouch(d.localPosition),
        onPanUpdate: (d) => _handleTouch(d.localPosition),
        onPanEnd: (_) {
          if (widget.selectingHour) widget.onHourFinished();
        },
        onTapUp: (d) {
          _handleTouch(d.localPosition);
          if (widget.selectingHour) widget.onHourFinished();
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_handCtrl, _modeCtrl, _ringCtrl]),
          builder: (_, __) {
            final handAngle = _handFrom +
                (_handTo - _handFrom) *
                    Curves.easeOut.transform(_handCtrl.value);
            return CustomPaint(
              size: const Size(_kSize, _kSize),
              painter: _ClockPainter(
                hour: widget.hour,
                minute: widget.minute,
                selectingHour: _paintMode,
                handAngle: handAngle,
                ringT: _ringCtrl.value,
                contentAlpha: Curves.easeInOut.transform(_modeCtrl.value),
              ),
            );
          },
        ),
      ),
    );
  }
}

//  Painter

class _ClockPainter extends CustomPainter {
  final int hour;
  final int minute;
  final bool selectingHour;

  /// Pre-computed (animated) angle of the clock hand, in radians.
  final double handAngle;

  /// Valor animado: 0.0 = anel externo (1-12) ativo, 1.0 = anel interno (0, 13-23) ativo.
  final double ringT;

  /// Opacity of the interactive content (numbers, ticks, hand). Face stays solid.
  final double contentAlpha;

  _ClockPainter({
    required this.hour,
    required this.minute,
    required this.selectingHour,
    required this.handAngle,
    required this.ringT,
    this.contentAlpha = 1.0,
  });

  static const _bgColor = Color(0xFFF0F2FF);
  static const _ringColor = Color(0xFFE3E6F8);
  static const _tickMinor = Color(0xFFBDBDBD);
  static const _tickMajor = Color(0xFF9E9E9E);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final outerR = radius * 0.83;
    final innerR = radius * 0.55;

    _drawFace(canvas, center, radius);
    _drawTicks(canvas, center, radius);

    // Raio e posição da ponta da mão (animados)
    final handR = lerpDouble(outerR, innerR, selectingHour ? ringT : 0.0)!;
    final bubbleR = lerpDouble(20.0, 17.0, selectingHour ? ringT : 0.0)!;
    final tip = Offset(
      center.dx + handR * cos(handAngle),
      center.dy + handR * sin(handAngle),
    );

    // Mão desenhada ANTES dos números
    _drawHand(canvas, center, handAngle, handR, bubbleR);

    // Números por cima da bolinha; 2ª passagem em branco clippada à bolinha
    selectingHour
        ? _paintHours(canvas, center, radius, outerR, innerR, tip, bubbleR)
        : _paintMinutes(canvas, center, radius, outerR, tip, bubbleR);
  }

  // Face

  void _drawFace(Canvas canvas, Offset center, double radius) {
    // Sombra suave
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center.translate(0, 3), radius - 1, shadow);

    // Fundo
    canvas.drawCircle(center, radius - 1, Paint()..color = _bgColor);

    // Aro externo
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..color = _ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // Ticks

  void _drawTicks(Canvas canvas, Offset center, double radius) {
    final tickOuter = radius - 4;
    final totalTicks = selectingHour ? 12 : 60;
    for (int i = 0; i < totalTicks; i++) {
      final major = i % (selectingHour ? 1 : 5) == 0;
      final tickLen = major ? 8.0 : 4.0;
      final tickW = major ? 1.8 : 1.0;
      final angle = i * 2 * pi / totalTicks - pi / 2;
      final outer = Offset(
        center.dx + tickOuter * cos(angle),
        center.dy + tickOuter * sin(angle),
      );
      final inner = Offset(
        center.dx + (tickOuter - tickLen) * cos(angle),
        center.dy + (tickOuter - tickLen) * sin(angle),
      );
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color =
              (major ? _tickMajor : _tickMinor).withValues(alpha: contentAlpha)
          ..strokeWidth = tickW
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // Horas

  void _paintHours(Canvas canvas, Offset center, double radius, double outerR,
      double innerR, Offset tip, double bubbleR) {
    final isInner = hour == 0 || hour >= 13;
    final selPos = _hourToPos(hour);

    final outerAlpha = contentAlpha * lerpDouble(1.0, 0.28, ringT)!;
    final innerAlpha = contentAlpha * lerpDouble(0.28, 1.0, ringT)!;

    // Passagem 1: cores normais
    for (int i = 0; i < 12; i++) {
      final value = i == 0 ? 12 : i;
      _drawNumberNode(canvas, center, outerR, i, 12, '$value',
          selected: !isInner && i == selPos,
          fontSize: 15.5,
          ringAlpha: outerAlpha);
    }
    for (int i = 0; i < 12; i++) {
      final value = i == 0 ? 0 : i + 12;
      _drawNumberNode(
          canvas, center, innerR, i, 12, value.toString().padLeft(2, '0'),
          selected: isInner && i == selPos,
          fontSize: 11.5,
          ringAlpha: innerAlpha);
    }

    // Passagem 2: branco clippado à bolinha
    // Qualquer parte do número tocada pela bolinha vira branca, mesmo overlap parcial
    canvas.save();
    canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: tip, radius: bubbleR)));
    for (int i = 0; i < 12; i++) {
      final value = i == 0 ? 12 : i;
      final isSel = !isInner && i == selPos;
      _paintTextAt(canvas, _posAt(center, outerR, i, 12), '$value', 15.5, isSel,
          Colors.white.withValues(alpha: contentAlpha));
    }
    for (int i = 0; i < 12; i++) {
      final value = i == 0 ? 0 : i + 12;
      final isSel = isInner && i == selPos;
      _paintTextAt(
          canvas,
          _posAt(center, innerR, i, 12),
          value.toString().padLeft(2, '0'),
          11.5,
          isSel,
          Colors.white.withValues(alpha: contentAlpha));
    }
    canvas.restore();
  }

  // Minutos

  void _paintMinutes(Canvas canvas, Offset center, double radius, double outerR,
      Offset tip, double bubbleR) {
    // Passagem 1: cores normais
    for (int i = 0; i < 12; i++) {
      final m = i * 5;
      _drawNumberNode(
          canvas, center, outerR, i, 12, m.toString().padLeft(2, '0'),
          selected: minute == m, fontSize: 14, ringAlpha: contentAlpha);
    }

    // Passagem 2: branco clippado à bolinha
    canvas.save();
    canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: tip, radius: bubbleR)));
    for (int i = 0; i < 12; i++) {
      final m = i * 5;
      _paintTextAt(
          canvas,
          _posAt(center, outerR, i, 12),
          m.toString().padLeft(2, '0'),
          14,
          minute == m,
          Colors.white.withValues(alpha: contentAlpha));
    }
    // Dot para minutos não múltiplos de 5 — desenhado em tip para seguir a animação
    if (minute % 5 != 0) {
      canvas.drawCircle(tip, 4.0,
          Paint()..color = Colors.white.withValues(alpha: contentAlpha));
    }
    canvas.restore();
  }

  // Helpers

  void _drawHand(
      Canvas canvas, Offset center, double angle, double r, double bubbleR) {
    final tip = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
    final a = contentAlpha;

    // Sombra da mão
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.22 * a)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    // Linha principal
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = AppColors.primary.withValues(alpha: a)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    // Bolinha na ponta (raio já calculado e animado pelo caller)
    canvas.drawCircle(
        tip, bubbleR, Paint()..color = AppColors.primary.withValues(alpha: a));
    // Hub central
    canvas.drawCircle(
        center, 5, Paint()..color = AppColors.primary.withValues(alpha: a));
  }

  /// Posição cartesiana de um nó no anel.
  Offset _posAt(Offset center, double r, int pos, int divisions) {
    final angle = pos * 2 * pi / divisions - pi / 2;
    return Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
  }

  /// Desenha apenas o texto de um nó (sem glow) — usado na passagem branca.
  void _paintTextAt(Canvas canvas, Offset pt, String text, double fontSize,
      bool bold, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pt.dx - tp.width / 2, pt.dy - tp.height / 2));
  }

  void _drawNumberNode(
    Canvas canvas,
    Offset center,
    double r,
    int pos,
    int divisions,
    String text, {
    required bool selected,
    required double fontSize,
    required double ringAlpha, // alpha efetivo para este anel
  }) {
    final angle = pos * 2 * pi / divisions - pi / 2;
    final pt = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
    final nodeR = r < 100 ? 17.0 : 20.0; // menor no anel interno

    if (selected) {
      // Glow ao redor do nó (a bolinha sólida vem do _drawHand)
      canvas.drawCircle(
        pt,
        nodeR + 5,
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.20 * contentAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }

    // Cor do texto: selecionado = branco (por cima da bolinha do ponteiro)
    final textColor = selected
        ? Colors.white.withValues(alpha: contentAlpha)
        : Colors.black87.withValues(alpha: ringAlpha);

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: textColor,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pt.dx - tp.width / 2, pt.dy - tp.height / 2));
  }

  int _hourToPos(int h) {
    if (h == 0 || h == 12) return 0;
    return h > 12 ? h - 12 : h;
  }

  @override
  bool shouldRepaint(covariant _ClockPainter old) =>
      hour != old.hour ||
      minute != old.minute ||
      selectingHour != old.selectingHour ||
      handAngle != old.handAngle ||
      ringT != old.ringT ||
      contentAlpha != old.contentAlpha;
}
