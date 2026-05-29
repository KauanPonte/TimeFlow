import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/repositories/ponto_history_repository.dart';
import 'package:flutter_application_appdeponto/services/analytics_service.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserReportPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserReportPage({
    super.key,
    required this.user,
  });

  @override
  State<UserReportPage> createState() => _UserReportPageState();
}

class _UserReportPageState extends State<UserReportPage> {
  final _repository = PontoHistoryRepository();
  late DateTime _selectedMonth;
  late Future<_RadData> _futureReport;

  int get _workloadMinutes => widget.user['workloadMinutes'] as int? ?? 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _futureReport = _loadReport();
  }

  Future<_RadData> _loadReport() async {
    final targetUserId = widget.user['id']?.toString() ?? '';
    final days = await _repository.loadDaysByMonth(
      uid: targetUserId,
      year: _selectedMonth.year,
      month: _selectedMonth.month,
    );
    final report = _RadData.fromDays(
      days: days,
      workloadMinutes: _workloadMinutes,
      projects: _projectsFromUser(widget.user),
    );
    final prefs = await SharedPreferences.getInstance();

    unawaited(AnalyticsService.logRadReportViewed(
      targetUserId: targetUserId,
      month: DateFormat('yyyy-MM').format(_selectedMonth),
      adminUid: prefs.getString('userUid'),
      daysWithPunches: report.daysWithPunches,
      workedMinutes: report.workedMinutes,
      openDays: report.openDays,
    ));

    return report;
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
      _futureReport = _loadReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user['name']?.toString() ?? 'Usuario';
    final email = widget.user['email']?.toString() ?? '';
    final role = widget.user['role']?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'RDA',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: FutureBuilder<_RadData>(
        future: _futureReport,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: 'Nao foi possivel carregar o RDA.',
              details: snapshot.error.toString(),
              onRetry: () => setState(() => _futureReport = _loadReport()),
            );
          }

          final report = snapshot.data ?? _RadData.empty(_workloadMinutes);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              setState(() => _futureReport = _loadReport());
              await _futureReport;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ReportHeader(
                  name: name,
                  email: email,
                  role: role,
                  selectedMonth: _selectedMonth,
                  onPrevious: () => _changeMonth(-1),
                  onNext: () => _changeMonth(1),
                ),
                const SizedBox(height: 12),
                _StatusBanner(report: report),
                const SizedBox(height: 12),
                _KpiGrid(report: report),
                const SizedBox(height: 12),
                _HoursChartCard(report: report),
                const SizedBox(height: 12),
                _ModeAndProjectsSection(report: report),
                const SizedBox(height: 12),
                _WeeklyTable(report: report),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final DateTime selectedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _ReportHeader({
    required this.name,
    required this.email,
    required this.role,
    required this.selectedMonth,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy', 'pt_BR').format(selectedMonth);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryLight10,
                child: Icon(Icons.badge_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Relatorio de Acompanhamento de Desempenho',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$role - $email',
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                tooltip: 'Mes anterior',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  monthLabel[0].toUpperCase() + monthLabel.substring(1),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Proximo mes',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final _RadData report;

  const _StatusBanner({required this.report});

  @override
  Widget build(BuildContext context) {
    final status = report.status;
    final color = report.statusColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.insights_outlined, color: color, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RDA - $status',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.statusDescription,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final _RadData report;

  const _KpiGrid({required this.report});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.25,
      children: [
        _KpiTile(
          icon: Icons.event_available_outlined,
          label: 'Dias trabalhados',
          value: report.daysWithPunches.toString(),
          accent: AppColors.primary,
        ),
        _KpiTile(
          icon: Icons.schedule_outlined,
          label: 'Horas trabalhadas',
          value: _formatDuration(report.workedMinutes),
          accent: AppColors.accent,
        ),
        _KpiTile(
          icon: Icons.trending_up_outlined,
          label: 'Horas extras',
          value: _formatDuration(math.max(report.balanceMinutes, 0)),
          accent: AppColors.success,
        ),
        _KpiTile(
          icon: Icons.fact_check_outlined,
          label: 'Aderencia',
          value: '${report.adherencePercent}%',
          accent: report.statusColor,
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _KpiTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoursChartCard extends StatelessWidget {
  final _RadData report;

  const _HoursChartCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.bar_chart_outlined,
            title: 'Ritmo semanal',
            subtitle: 'Horas registradas comparadas com a carga esperada',
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 190,
            child: CustomPaint(
              painter: _WeeklyHoursPainter(report.weeklyStats),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _LegendDot(color: AppColors.primary, label: 'Realizado'),
              SizedBox(width: 16),
              _LegendDot(color: AppColors.border, label: 'Esperado'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeAndProjectsSection extends StatelessWidget {
  final _RadData report;

  const _ModeAndProjectsSection({required this.report});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 620;
        final children = [
          Expanded(child: _WorkModeCard(report: report)),
          const SizedBox(width: 12, height: 12),
          Expanded(child: _ProjectsCard(report: report)),
        ];

        if (narrow) {
          return Column(
            children: [
              _WorkModeCard(report: report),
              const SizedBox(height: 12),
              _ProjectsCard(report: report),
            ],
          );
        }

        return Row(
            crossAxisAlignment: CrossAxisAlignment.start, children: children);
      },
    );
  }
}

class _WorkModeCard extends StatelessWidget {
  final _RadData report;

  const _WorkModeCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.workspaces_outline,
            title: 'Modelo de trabalho',
            subtitle: 'Distribuicao por dia com registro',
          ),
          const SizedBox(height: 14),
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: CustomPaint(
                painter: _DonutPainter(
                  firstValue: report.presencialDays,
                  secondValue: report.remoteDays,
                  firstColor: const Color(0xFF178573),
                  secondColor: const Color(0xFFFA8D57),
                ),
                child: Center(
                  child: Text(
                    '${report.remotePercent}%',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 34,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: Color(0xFF178573), label: 'Presencial'),
              SizedBox(width: 16),
              _LegendDot(color: Color(0xFFFA8D57), label: 'Home'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectsCard extends StatelessWidget {
  final _RadData report;

  const _ProjectsCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.account_tree_outlined,
            title: 'Projetos vinculados',
            subtitle: 'Base cadastral do funcionario',
          ),
          const SizedBox(height: 14),
          if (report.projects.isEmpty)
            const _EmptyInline(
              icon: Icons.folder_off_outlined,
              text: 'Nenhum projeto vinculado ao cadastro.',
            )
          else
            ...report.projects.map(
              (project) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ProjectRow(project: project),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Para medir horas por projeto, registre o projeto no momento do ponto ou em lancamentos de atividade.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  final String project;

  const _ProjectRow({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryLight10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_outlined, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              project,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyTable extends StatelessWidget {
  final _RadData report;

  const _WeeklyTable({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.table_chart_outlined,
            title: 'Resumo administrativo',
            subtitle: 'Sem exposicao das batidas individuais',
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.1),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
            },
            children: [
              _tableRow(
                ['Semana', 'Dias', 'Horas', 'Saldo'],
                isHeader: true,
              ),
              ...report.weeklyStats.map(
                (week) => _tableRow([
                  'S${week.weekIndex}',
                  week.days.toString(),
                  _formatDuration(week.workedMinutes),
                  _formatSignedDuration(week.balanceMinutes),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _tableRow(List<String> cells, {bool isHeader = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? AppColors.borderLight : Colors.transparent,
      ),
      children: cells
          .map(
            (cell) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text(
                cell,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: isHeader ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyInline extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyInline({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String details;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.details,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              details,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyHoursPainter extends CustomPainter {
  final List<_WeekStat> weeks;

  _WeeklyHoursPainter(this.weeks);

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    final expectedPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.fill;
    final actualPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    const chartTop = 8.0;
    final chartBottom = size.height - 24;
    final chartHeight = chartBottom - chartTop;
    final maxMinutes = weeks.fold<int>(
      60,
      (maxValue, week) => math.max(
        maxValue,
        math.max(week.workedMinutes, week.expectedMinutes),
      ),
    );

    canvas.drawLine(
        Offset(0, chartBottom), Offset(size.width, chartBottom), axisPaint);

    final slotWidth = size.width / math.max(weeks.length, 1);
    for (var i = 0; i < weeks.length; i++) {
      final week = weeks[i];
      final centerX = slotWidth * i + slotWidth / 2;
      final barWidth = math.min(24.0, slotWidth * 0.22);
      final expectedHeight = chartHeight * (week.expectedMinutes / maxMinutes);
      final actualHeight = chartHeight * (week.workedMinutes / maxMinutes);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX - barWidth - 3,
            chartBottom - expectedHeight,
            barWidth,
            expectedHeight,
          ),
          const Radius.circular(4),
        ),
        expectedPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX + 3,
            chartBottom - actualHeight,
            barWidth,
            actualHeight,
          ),
          const Radius.circular(4),
        ),
        actualPaint,
      );

      textPainter.text = TextSpan(
        text: 'S${week.weekIndex}',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, chartBottom + 7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyHoursPainter oldDelegate) {
    return oldDelegate.weeks != weeks;
  }
}

class _DonutPainter extends CustomPainter {
  final int firstValue;
  final int secondValue;
  final Color firstColor;
  final Color secondColor;

  _DonutPainter({
    required this.firstValue,
    required this.secondValue,
    required this.firstColor,
    required this.secondColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = firstValue + secondValue;
    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.18;
    final bgPaint = Paint()
      ..color = AppColors.borderLight
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    final firstPaint = Paint()
      ..color = firstColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    final secondPaint = Paint()
      ..color = secondColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final arcRect = rect.deflate(strokeWidth / 2);
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2, false, bgPaint);

    if (total == 0) return;
    final firstSweep = math.pi * 2 * (firstValue / total);
    final secondSweep = math.pi * 2 * (secondValue / total);
    canvas.drawArc(arcRect, -math.pi / 2, firstSweep, false, firstPaint);
    canvas.drawArc(
      arcRect,
      -math.pi / 2 + firstSweep,
      secondSweep,
      false,
      secondPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.firstValue != firstValue ||
        oldDelegate.secondValue != secondValue ||
        oldDelegate.firstColor != firstColor ||
        oldDelegate.secondColor != secondColor;
  }
}

class _RadData {
  final int daysWithPunches;
  final int workedMinutes;
  final int expectedMinutes;
  final int balanceMinutes;
  final int openDays;
  final int presencialDays;
  final int remoteDays;
  final int adherencePercent;
  final List<String> projects;
  final List<_WeekStat> weeklyStats;

  const _RadData({
    required this.daysWithPunches,
    required this.workedMinutes,
    required this.expectedMinutes,
    required this.balanceMinutes,
    required this.openDays,
    required this.presencialDays,
    required this.remoteDays,
    required this.adherencePercent,
    required this.projects,
    required this.weeklyStats,
  });

  factory _RadData.empty(int workloadMinutes) {
    return _RadData(
      daysWithPunches: 0,
      workedMinutes: 0,
      expectedMinutes: 0,
      balanceMinutes: 0,
      openDays: 0,
      presencialDays: 0,
      remoteDays: 0,
      adherencePercent: 0,
      projects: const [],
      weeklyStats: List.generate(
        5,
        (index) => _WeekStat(
          weekIndex: index + 1,
          days: 0,
          workedMinutes: 0,
          expectedMinutes: 0,
          balanceMinutes: 0,
        ),
      ),
    );
  }

  factory _RadData.fromDays({
    required Map<String, List<Map<String, dynamic>>> days,
    required int workloadMinutes,
    required List<String> projects,
  }) {
    var workedMinutes = 0;
    var openDays = 0;
    var presencialDays = 0;
    var remoteDays = 0;
    final weekly = <int, _WeekAccumulator>{};

    for (final entry in days.entries) {
      final dayId = entry.key;
      final events = entry.value;
      final dayWorked = _workedMinutes(events);
      final weekIndex = _weekOfMonth(dayId);
      final workMode = _dominantWorkMode(events);

      workedMinutes += dayWorked;
      if (events.isNotEmpty && events.last['tipo'] != 'saida') {
        openDays++;
      }
      if (workMode == 'presencial') {
        presencialDays++;
      } else if (workMode == 'remoto') {
        remoteDays++;
      }

      final acc = weekly.putIfAbsent(weekIndex, () => _WeekAccumulator());
      acc.days += 1;
      acc.workedMinutes += dayWorked;
      acc.expectedMinutes += workloadMinutes;
    }

    final expectedMinutes = workloadMinutes * days.length;
    final balanceMinutes = workedMinutes - expectedMinutes;
    final adherencePercent = expectedMinutes <= 0
        ? 0
        : ((workedMinutes / expectedMinutes) * 100).round();

    final weeklyStats = List.generate(5, (index) {
      final weekIndex = index + 1;
      final acc = weekly[weekIndex] ?? _WeekAccumulator();
      return _WeekStat(
        weekIndex: weekIndex,
        days: acc.days,
        workedMinutes: acc.workedMinutes,
        expectedMinutes: acc.expectedMinutes,
        balanceMinutes: acc.workedMinutes - acc.expectedMinutes,
      );
    });

    return _RadData(
      daysWithPunches: days.length,
      workedMinutes: workedMinutes,
      expectedMinutes: expectedMinutes,
      balanceMinutes: balanceMinutes,
      openDays: openDays,
      presencialDays: presencialDays,
      remoteDays: remoteDays,
      adherencePercent: adherencePercent,
      projects: projects,
      weeklyStats: weeklyStats,
    );
  }

  int get remotePercent {
    final total = presencialDays + remoteDays;
    if (total == 0) return 0;
    return ((remoteDays / total) * 100).round();
  }

  String get status {
    if (daysWithPunches == 0) return 'Sem dados';
    if (openDays > 0) return 'Revisar registros';
    if (adherencePercent >= 95) return 'Em conformidade';
    if (adherencePercent >= 80) return 'Acompanhar';
    return 'Abaixo do esperado';
  }

  Color get statusColor {
    if (daysWithPunches == 0) return AppColors.textSecondary;
    if (openDays > 0) return AppColors.warning;
    if (adherencePercent >= 95) return AppColors.success;
    if (adherencePercent >= 80) return AppColors.info;
    return AppColors.error;
  }

  String get statusDescription {
    if (daysWithPunches == 0) {
      return 'Nenhuma atividade registrada no periodo selecionado.';
    }
    if (openDays > 0) {
      return 'Existem dias sem fechamento; revise antes de consolidar o RDA.';
    }
    if (balanceMinutes > 0) {
      return 'Funcionario com saldo positivo no periodo e ritmo dentro do esperado.';
    }
    return 'Acompanhamento baseado em presenca, horas e modelo de trabalho.';
  }
}

class _WeekStat {
  final int weekIndex;
  final int days;
  final int workedMinutes;
  final int expectedMinutes;
  final int balanceMinutes;

  const _WeekStat({
    required this.weekIndex,
    required this.days,
    required this.workedMinutes,
    required this.expectedMinutes,
    required this.balanceMinutes,
  });
}

class _WeekAccumulator {
  int days = 0;
  int workedMinutes = 0;
  int expectedMinutes = 0;
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppColors.borderLight),
    boxShadow: const [
      BoxShadow(
        color: AppColors.shadow,
        blurRadius: 10,
        offset: Offset(0, 2),
      ),
    ],
  );
}

int _workedMinutes(List<Map<String, dynamic>> events) {
  DateTime? open;
  var total = Duration.zero;

  for (final event in events) {
    final tipo = event['tipo']?.toString() ?? '';
    final at = event['at'];
    if (at is! DateTime) continue;

    if (tipo == 'entrada' || tipo == 'retorno') {
      open = at;
    } else if ((tipo == 'pausa' || tipo == 'saida') &&
        open != null &&
        at.isAfter(open)) {
      total += at.difference(open);
      open = null;
    }
  }

  return total.inMinutes;
}

int _weekOfMonth(String dayId) {
  final date = DateTime.tryParse(dayId);
  if (date == null) return 1;
  return ((date.day - 1) ~/ 7) + 1;
}

String _dominantWorkMode(List<Map<String, dynamic>> events) {
  var presencial = 0;
  var remoto = 0;
  for (final event in events) {
    final mode = event['workMode']?.toString().toLowerCase() ?? '';
    if (mode == 'presencial') presencial++;
    if (mode == 'remoto') remoto++;
  }
  if (presencial == 0 && remoto == 0) return '';
  return presencial >= remoto ? 'presencial' : 'remoto';
}

List<String> _projectsFromUser(Map<String, dynamic> user) {
  final raw = [
    user['projectType'],
    user['project1'],
    user['project2'],
  ];
  return raw
      .map((value) => (value ?? '').toString().trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList();
}

String _formatDuration(int minutes) {
  final sign = minutes < 0 ? '-' : '';
  final value = minutes.abs();
  final hours = value ~/ 60;
  final mins = value % 60;
  return '$sign${hours}h${mins.toString().padLeft(2, '0')}';
}

String _formatSignedDuration(int minutes) {
  if (minutes == 0) return '0h00';
  return _formatDuration(minutes);
}
