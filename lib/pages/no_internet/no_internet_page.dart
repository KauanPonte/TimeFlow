import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class NoInternetPage extends StatefulWidget {
  final Future<void> Function()? onRetry;

  const NoInternetPage({
    super.key,
    this.onRetry,
  });

  @override
  State<NoInternetPage> createState() => _NoInternetPageState();
}

class _NoInternetPageState extends State<NoInternetPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    if (_retrying || widget.onRetry == null) return;

    setState(() => _retrying = true);
    try {
      await widget.onRetry!.call();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgLight,
              Color(0xFFDCE3F8),
              Color(0xFFD3DCF7),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -90,
                left: -70,
                child: Container(
                  width: 230,
                  height: 230,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -70,
                right: -60,
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface90,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.primaryLight20),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowMedium,
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                final scale =
                                    1.0 + (_pulseController.value * 0.08);
                                return Transform.scale(
                                  scale: scale,
                                  child: child,
                                );
                              },
                              child: Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight10,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryLight30,
                                    width: 1.2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.wifi_off_rounded,
                                  size: 46,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Sem internet no momento',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.h2.copyWith(
                                color: AppColors.primary,
                                fontSize: 30,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Sua sessão permanece ativa. Assim que a conexão voltar, o TimeFlow retoma automaticamente.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: [
                                _StatusChip(
                                  icon: Icons.cloud_off_rounded,
                                  label: 'Conexão indisponível',
                                ),
                                _StatusChip(
                                  icon: Icons.sync_problem_rounded,
                                  label: 'Sincronização pausada',
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: widget.onRetry == null
                                    ? null
                                    : _handleRetry,
                                icon: _retrying
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.refresh_rounded),
                                label: Text(
                                  _retrying
                                      ? 'Verificando conexão...'
                                      : 'Tentar novamente',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Dica: confira Wi-Fi ou dados móveis.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatusChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight10,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primaryLight20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
