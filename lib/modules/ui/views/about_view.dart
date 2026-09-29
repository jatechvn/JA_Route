// lib/modules/ui/views/about_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../build_info.dart';
import '../../constants.dart';
import '../../localization.dart';
import '../../logic.dart';
import '../../native_bridge.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../theme/language_provider.dart';
import '../widgets/glass_widgets.dart';

class AboutView extends StatelessWidget {
  final RouteFixerLogic logic;

  const AboutView({super.key, required this.logic});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = context.watch<ThemeProvider>();
    final language = context.watch<LanguageProvider>();
    final loc = AppLocalizations(language.currentLanguage.code);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 860;
        final appCard = _buildAppCard(colors, loc);
        final licenseCard = _buildLicenseCard(colors, loc);
        final systemCard = _buildSystemCard(colors, theme, loc);

        if (isWide) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cột trái (flex: 6): Thông tin định danh ứng dụng & Bản quyền
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      appCard,
                      const SizedBox(height: 14),
                      licenseCard,
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Cột phải (flex: 6): Môi trường hệ thống & Đồ họa
                Expanded(flex: 6, child: systemCard),
              ],
            ),
          );
        } else {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                appCard,
                const SizedBox(height: 14),
                systemCard,
                const SizedBox(height: 14),
                licenseCard,
                const SizedBox(height: 20),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildAppCard(AppColors colors, AppLocalizations loc) {
    return BentoCard(
      colors: colors,
      isFeatured: true,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.accentCyan, colors.accentPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: colors.accentCyan.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'JA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          appName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PillBadge(
                          label: 'v$appVersion',
                          color: colors.accentCyan,
                          bg: colors.accentCyan.withValues(alpha: 0.12),
                          border: colors.accentCyan.withValues(alpha: 0.35),
                          fontSize: 10,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                        ),
                        if (BuildInfo.isDebug) ...[
                          const SizedBox(width: 6),
                          PillBadge(
                            label: 'DEBUG MODE',
                            color: colors.accentAmber,
                            bg: colors.accentAmber.withValues(alpha: 0.15),
                            border: colors.accentAmber.withValues(alpha: 0.4),
                            icon: Icons.bug_report_rounded,
                            fontSize: 9.5,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.get('about_subtitle'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.accentCyan,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            loc.get('about_app_desc'),
            style: TextStyle(
              fontSize: 12.5,
              color: colors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Divider(color: colors.subCardBorder, height: 1),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: Icon(
                  Icons.language_rounded,
                  size: 15,
                  color: colors.accentCyan,
                ),
                label: Text(
                  loc.get('about_btn_website'),
                  style: const TextStyle(fontSize: 11.5),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.accentCyan,
                  side: BorderSide(
                    color: colors.accentCyan.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () =>
                    nativeBridge.engine?.openUrl('https://jatechvn.github.io/'),
              ),
              OutlinedButton.icon(
                icon: Icon(
                  Icons.code_rounded,
                  size: 15,
                  color: colors.accentPurple,
                ),
                label: Text(
                  loc.get('about_btn_github'),
                  style: const TextStyle(fontSize: 11.5),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.accentPurple,
                  side: BorderSide(
                    color: colors.accentPurple.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => nativeBridge.engine?.openUrl(
                  'https://github.com/jatechvn/JA_Route',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemCard(
    AppColors colors,
    ThemeProvider theme,
    AppLocalizations loc,
  ) {
    return BentoCard(
      colors: colors,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.memory_rounded, color: colors.accentEmerald, size: 18),
              const SizedBox(width: 8),
              Text(
                loc.get('about_sys_info'),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            loc.get('about_os'),
            Platform.operatingSystemVersion,
            colors,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            loc.get('about_native_graphics'),
            theme.isWin11
                ? 'Windows 11 Acrylic / Mica (Build >= 22000)'
                : 'Windows 10 Aero Glass Blur',
            colors,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            loc.get('about_privilege'),
            logic.isAdmin ? 'Administrator' : 'User Mode',
            colors,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            loc.get('about_build_time'),
            BuildInfo.debugTimestamp,
            colors,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            loc.get('about_cpu_cores'),
            '${theme.cpuCores} Cores',
            colors,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            loc.get('about_hw_score'),
            '${theme.hardwareScore}/100',
            colors,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            loc.get('about_graphic_tier'),
            '${theme.effectiveTier.label} (${theme.effectiveTier.desc})',
            colors,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            loc.get('about_debug_mode'),
            BuildInfo.isDebug ? 'ON' : 'OFF',
            colors,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colors.subCardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.subCardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseCard(AppColors colors, AppLocalizations loc) {
    return BentoCard(
      colors: colors,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user_rounded,
                color: colors.accentAmber,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                loc.get('about_license_title'),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            loc.get('about_license_desc'),
            style: TextStyle(
              fontSize: 12,
              color: colors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
