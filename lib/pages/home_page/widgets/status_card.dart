import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class StatusCard extends StatefulWidget {
  final String statusLabel;
  final String todayWorkedDisplay;
  final double workProgress;
  final int workedMinutes;
  final int monthWorkedMinutes;
  final int monthExpectedMinutes;

  const StatusCard({
    super.key,
    required this.statusLabel,
    required this.todayWorkedDisplay,
    required this.workProgress,
    required this.workedMinutes,
    this.monthWorkedMinutes = 0,
    this.monthExpectedMinutes = 0,
  });

  @override
  State<StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<StatusCard>
    with SingleTickerProviderStateMixin {
  static const Duration _workingAnimationDuration =
      Duration(milliseconds: 6000);
  static const Duration _pauseFlickerDuration = Duration(milliseconds: 600);
  static const Duration _pauseFlickerDelay = Duration(milliseconds: 600);

  late final AnimationController _controller;
  bool _pauseFlickerActive = false;
  int _pauseFlickerCycleId = 0;

  bool get _isWorking => widget.statusLabel == 'Trabalhando...';
  bool get _isPaused => widget.statusLabel == 'Pausado';

  Color get _statusColor {
    switch (widget.statusLabel) {
      case 'Trabalhando...':
        return AppColors.success;
      case 'Pausado':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _workingAnimationDuration,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAnimationState();
    });
  }

  @override
  void didUpdateWidget(covariant StatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statusLabel != widget.statusLabel) {
      _updateAnimationState();
    }
  }

  @override
  void dispose() {
    _pauseFlickerCycleId++;
    _controller.dispose();
    super.dispose();
  }

  void _updateAnimationState() {
    _pauseFlickerCycleId++;

    if (_isWorking) {
      _pauseFlickerActive = false;
      _controller.repeat();
      return;
    }

    if (_isPaused) {
      if (!_pauseFlickerActive) {
        _pauseFlickerActive = true;
        _startPauseFlickerCycle(_pauseFlickerCycleId);
      }
      return;
    }

    _pauseFlickerActive = false;
    _controller.stop(canceled: false);
    _controller.value = 0;
  }

  Future<void> _startPauseFlickerCycle(int cycleId) async {
    while (mounted && _isPaused && cycleId == _pauseFlickerCycleId) {
      await _controller.animateTo(
        0.03,
        duration: _pauseFlickerDuration,
        curve: Curves.easeInOut,
      );

      if (!mounted || !_isPaused || cycleId != _pauseFlickerCycleId) {
        break;
      }

      await _controller.animateBack(
        0.0,
        duration: _pauseFlickerDuration,
        curve: Curves.easeInOut,
      );

      if (!mounted || !_isPaused || cycleId != _pauseFlickerCycleId) {
        break;
      }

      await Future.delayed(_pauseFlickerDelay);
    }

    _pauseFlickerActive = false;
  }

  String _formatMinutesAsHoursLabel(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h horas';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Calcula o primeiro e último dia do mês conforme sua lógica
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final String formattedFirstDay =
        DateFormat('dd/MM/yyyy').format(firstDayOfMonth);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final String formattedLastDay =
        DateFormat('dd/MM/yyyy').format(lastDayOfMonth);

    final hasExpected = widget.monthExpectedMinutes > 0;
    final monthlyProgress = hasExpected
        ? '${_formatMinutesAsHoursLabel(widget.monthWorkedMinutes)} de ${_formatMinutesAsHoursLabel(widget.monthExpectedMinutes)}/mês'
        : '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _statusColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.statusLabel,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.todayWorkedDisplay,
                    style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              Expanded(child: Container()),
              // Bloco da animação Lottie mantido
              SizedBox(
                width: 72,
                height: 72,
                child: FutureBuilder<String>(
                  future: rootBundle
                      .loadString('assets/lottie/gears.json')
                      .catchError((_) => ''),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || (snapshot.data ?? '').isEmpty) {
                      return const Icon(Icons.timer_outlined,
                          size: 40, color: AppColors.primary);
                    }
                    return Lottie.asset(
                      'assets/lottie/gears.json',
                      controller: _controller,
                      fit: BoxFit.contain,
                      animate: false,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          Text(
            'trabalhado hoje',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: widget.workProgress,
              minHeight: 8,
              backgroundColor: AppColors.borderLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(widget.workProgress * 100).toStringAsFixed(0)}% da jornada diária',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),

          // --- SEÇÃO DE DATAS E MÊS ---
          const SizedBox(height: 12),
          Text(
            '$formattedFirstDay à $formattedLastDay',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          if (monthlyProgress.isNotEmpty)
            Text(
              monthlyProgress,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

// Renomeei para evitar conflito com a biblioteca intl se você decidir usá-la no futuro
class CustomDateFormatter {
  CustomDateFormatter(String s);

  String format(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '${day}_${month}_$year';
  }
}
