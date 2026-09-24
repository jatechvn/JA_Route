// lib/modules/ui/views/dashboard_view.dart
import 'package:flutter/material.dart';
import '../../localization.dart';
import '../../logger_config.dart';
import '../../logic.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../widgets/glass_widgets.dart';

class DashboardView extends StatelessWidget {
  final RouteFixerLogic logic;
  final VoidCallback onOpenLogs;

  const DashboardView({
    super.key,
    required this.logic,
    required this.onOpenLogs,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final loc = AppLocalizations(logic.config.language);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Phân 2 cột khi bề ngang màn hình >= 860px để hiển thị trọn vẹn không cần cuộn/expand
        final isWide = constraints.maxWidth >= 860;

        final heroCard = _buildHeroCard(context, colors, loc);
        final stepsCard = _buildStepsCard(context, colors, loc);
        final consoleCard = _buildQuickConsoleCard(context, colors, loc);

        if (isWide) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cột trái (flex: 5): Sơ đồ mạng + Nút bắt đầu fix + Nhật ký tóm tắt
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      heroCard,
                      const SizedBox(height: 12),
                      consoleCard,
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Cột phải (flex: 7): Toàn bộ 9 bước tiến trình hiển thị trực tiếp
                Expanded(flex: 7, child: stepsCard),
              ],
            ),
          );
        } else {
          // Bố cục 1 cột cuộn dọc linh hoạt khi cửa sổ bị thu nhỏ
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                heroCard,
                const SizedBox(height: 12),
                stepsCard,
                const SizedBox(height: 12),
                consoleCard,
                const SizedBox(height: 14),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    AppColors colors,
    AppLocalizations loc,
  ) {
    return BentoCard(
      colors: colors,
      isFeatured: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              PillBadge(
                label: loc.get('badge_dual_routing'),
                color: colors.accentCyan,
                bg: colors.accentCyan.withValues(alpha: 0.12),
                border: colors.accentCyan.withValues(alpha: 0.3),
                icon: Icons.alt_route_rounded,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (logic.isAdmin)
                    PillBadge(
                      label: 'ADMIN',
                      color: colors.accentEmerald,
                      bg: colors.accentEmerald.withValues(alpha: 0.12),
                      border: colors.accentEmerald.withValues(alpha: 0.3),
                      icon: Icons.shield_rounded,
                    )
                  else
                    PillBadge(
                      label: 'USER MODE',
                      color: colors.accentAmber,
                      bg: colors.accentAmber.withValues(alpha: 0.15),
                      border: colors.accentAmber.withValues(alpha: 0.4),
                      icon: Icons.warning_amber_rounded,
                    ),
                  const SizedBox(width: 8),
                  PillBadge(
                    label: logic.isRunning
                        ? loc.get('status_fixing')
                        : loc.get('status_ready'),
                    color: logic.isRunning
                        ? colors.accentCyan
                        : colors.accentEmerald,
                    bg:
                        (logic.isRunning
                                ? colors.accentCyan
                                : colors.accentEmerald)
                            .withValues(alpha: 0.12),
                    border:
                        (logic.isRunning
                                ? colors.accentCyan
                                : colors.accentEmerald)
                            .withValues(alpha: 0.35),
                    showDot: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Network Nodes Map
          _buildNetworkNodesRow(colors, loc),
          const SizedBox(height: 14),

          // Welcome text & Auto-heal badge
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                loc.get('home_welcome'),
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              if (logic.config.autoFixEnabled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accentEmerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: colors.accentEmerald.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    loc.get('auto_heal_badge'),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: colors.accentEmerald,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            loc.get('home_welcome_sub'),
            style: TextStyle(
              fontSize: 11,
              color: colors.textMuted,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: GlowingActionButton(
              height: 44,
              colors: colors,
              isDestructive: false,
              icon: logic.isRunning ? Icons.sync_rounded : Icons.bolt_rounded,
              label: logic.isRunning
                  ? loc.get('status_fixing')
                  : loc.get('home_btn_fix'),
              onPressed: logic.isRunning ? null : () => logic.runOptimization(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkNodesRow(AppColors colors, AppLocalizations loc) {
    final internetGw = logic.config.internetGateway;
    final lanGw = logic.config.lanGateway;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.subCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.subCardBorder),
      ),
      child: Row(
        children: [
          _buildNode(
            title: loc.get('node_internet_gw'),
            ip: internetGw.isNotEmpty ? internetGw : loc.get('not_configured'),
            icon: Icons.public_rounded,
            color: colors.accentEmerald,
            colors: colors,
          ),
          Expanded(
            child: _buildLine(active: internetGw.isNotEmpty, colors: colors),
          ),
          _buildNode(
            title: loc.get('node_this_pc'),
            ip: 'PC / Workstation',
            icon: Icons.computer_rounded,
            color: colors.accentCyan,
            isCenter: true,
            colors: colors,
          ),
          Expanded(
            child: _buildLine(active: lanGw.isNotEmpty, colors: colors),
          ),
          _buildNode(
            title: loc.get('node_lan_gw'),
            ip: lanGw.isNotEmpty ? lanGw : loc.get('not_configured'),
            icon: Icons.lan_rounded,
            color: colors.accentPurple,
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildNode({
    required String title,
    required String ip,
    required IconData icon,
    required Color color,
    required AppColors colors,
    bool isCenter = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            boxShadow: isCenter
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 1),
        Text(ip, style: TextStyle(fontSize: 9.5, color: colors.textMuted)),
      ],
    );
  }

  Widget _buildLine({required bool active, required AppColors colors}) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: active
            ? colors.accentCyan.withValues(alpha: 0.6)
            : colors.subCardBorder,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildStepsCard(
    BuildContext context,
    AppColors colors,
    AppLocalizations loc,
  ) {
    final completedCount = logic.steps
        .where((s) => s.status == StepStatus.success)
        .length;
    final isRunning = logic.steps.any((s) => s.status == StepStatus.running);
    final total = logic.steps.length;

    return BentoCard(
      colors: colors,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.format_list_numbered_rounded,
                    color: colors.accentCyan,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loc.get('home_steps_title'),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              PillBadge(
                label: isRunning
                    ? loc.getWithParams('steps_running_badge', {
                        'done': '$completedCount',
                        'total': '$total',
                      })
                    : (completedCount == total && total > 0
                          ? loc.getWithParams('steps_done_badge', {
                              'total': '$total',
                            })
                          : loc.getWithParams('steps_total_badge', {
                              'total': '$total',
                            })),
                color: isRunning
                    ? colors.accentCyan
                    : (completedCount == total && total > 0
                          ? colors.accentEmerald
                          : colors.textMuted),
                bg:
                    (isRunning
                            ? colors.accentCyan
                            : (completedCount == total && total > 0
                                  ? colors.accentEmerald
                                  : colors.subCardBg))
                        .withValues(alpha: 0.12),
                border:
                    (isRunning
                            ? colors.accentCyan
                            : (completedCount == total && total > 0
                                  ? colors.accentEmerald
                                  : colors.subCardBorder))
                        .withValues(alpha: 0.3),
                fontSize: 9.5,
                showDot: isRunning,
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...logic.steps.asMap().entries.map(
            (entry) => _buildStepRow(entry.value, entry.key, colors, loc),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(
    FixStep step,
    int index,
    AppColors colors,
    AppLocalizations loc,
  ) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (step.status) {
      case StepStatus.idle:
        statusColor = colors.textMuted;
        statusIcon = Icons.hourglass_empty_rounded;
        statusText = loc.get('step_status_idle');
        break;
      case StepStatus.running:
        statusColor = colors.accentCyan;
        statusIcon = Icons.sync_rounded;
        statusText = loc.get('step_status_running');
        break;
      case StepStatus.success:
        statusColor = colors.accentEmerald;
        statusIcon = Icons.check_circle_rounded;
        statusText = loc.get('step_status_success');
        break;
      case StepStatus.warning:
        statusColor = colors.accentAmber;
        statusIcon = Icons.warning_amber_rounded;
        statusText = loc.get('step_status_warning');
        break;
      case StepStatus.error:
        statusColor = colors.accentRose;
        statusIcon = Icons.error_rounded;
        statusText = loc.get('step_status_error');
        break;
    }

    final stepKey = 'step_${step.id}';
    final localizedTitle = loc.get(stepKey);
    final displayTitle =
        (localizedTitle.isNotEmpty && localizedTitle != stepKey)
        ? localizedTitle
        : step.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
      decoration: BoxDecoration(
        color: colors.subCardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: step.status == StepStatus.running
              ? colors.accentCyan.withValues(alpha: 0.45)
              : colors.subCardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(statusIcon, color: statusColor, size: 13.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                if (step.message.isNotEmpty) ...[
                  const SizedBox(height: 1.5),
                  Text(
                    step.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: step.status == StepStatus.error
                          ? colors.accentRose
                          : colors.textMuted,
                      fontFamily: 'Consolas',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          PillBadge(
            label: statusText,
            color: statusColor,
            bg: statusColor.withValues(alpha: 0.12),
            border: statusColor.withValues(alpha: 0.3),
            fontSize: 9,
            padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickConsoleCard(
    BuildContext context,
    AppColors colors,
    AppLocalizations loc,
  ) {
    final recentLogs = logMessages.reversed.take(4).toList().reversed.toList();

    return BentoCard(
      colors: colors,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.terminal_rounded,
                    color: colors.accentAmber,
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    loc.get('dashboard_live_console'),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onOpenLogs,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      Text(
                        loc.get('view_all_logs'),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: colors.accentCyan,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 9,
                        color: colors.accentCyan,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.subCardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.subCardBorder),
            ),
            child: recentLogs.isEmpty
                ? Text(
                    loc.get('no_logs_placeholder'),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: colors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: recentLogs.map((entry) {
                      final isErr =
                          entry.contains('[SEVERE]') || entry.contains('Lỗi');
                      final isWarn = entry.contains('[WARNING]');
                      final color = isErr
                          ? colors.accentRose
                          : (isWarn ? colors.accentAmber : colors.textPrimary);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1.5),
                        child: Text(
                          entry,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Consolas',
                            fontSize: 10.5,
                            color: color,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
