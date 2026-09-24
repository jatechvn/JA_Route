// lib/modules/ui/main_window.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic.dart';
import 'layout/dashboard_shell.dart';
import 'theme/language_provider.dart';
import 'theme/theme_provider.dart';
import 'widgets/app_toast.dart';
import 'widgets/command_palette.dart';

class MainWindow extends StatelessWidget {
  final RouteFixerLogic logic;

  const MainWindow({super.key, required this.logic});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final language = context.watch<LanguageProvider>();
    final colors = theme.colors;

    return CommandPaletteShortcut(
      items: () => [
        CommandPaletteItem(
          label: 'Tối ưu hóa định tuyến ngay',
          subtitle: 'Chạy quy trình fix route 9 bước tự động',
          icon: Icons.bolt_rounded,
          onSelect: () => logic.runOptimization(),
        ),
        CommandPaletteItem(
          label: 'Chuyển Theme Sáng / Tối',
          subtitle: 'Đổi chế độ giao diện 1-Click (Shift+L)',
          icon: Icons.brightness_4_rounded,
          onSelect: () => theme.toggleTheme(),
        ),
        CommandPaletteItem(
          label: 'Chuyển Đổi Ngôn Ngữ',
          subtitle: 'Đổi nhanh giữa Tiếng Việt, English, 中文',
          icon: Icons.language_rounded,
          onSelect: () {
            final nextLang = switch (language.currentLanguage) {
              AppLanguage.vi => AppLanguage.en,
              AppLanguage.en => AppLanguage.zh,
              AppLanguage.zh => AppLanguage.vi,
            };
            final nextCode = switch (nextLang) {
              AppLanguage.vi => 'vi',
              AppLanguage.en => 'en',
              AppLanguage.zh => 'zh',
            };
            language.cycleLanguage();
            logic.setLanguage(nextCode);
            showAppToast(
              context,
              colors: colors,
              message: language.t('lang_changed_msg'),
              icon: Icons.language_rounded,
            );
          },
        ),
        CommandPaletteItem(
          label: 'Khôi phục Glass Tuning',
          subtitle: 'Đặt lại Blur và Opacity về chuẩn mặc định',
          icon: Icons.refresh_rounded,
          onSelect: () {
            theme.resetToDefaults();
            showAppToast(
              context,
              colors: colors,
              message: 'Đã khôi phục Glass Tuning!',
              icon: Icons.check_circle_rounded,
              accentColor: colors.accentCyan,
            );
          },
        ),
      ],
      child: DashboardShell(logic: logic),
    );
  }
}
