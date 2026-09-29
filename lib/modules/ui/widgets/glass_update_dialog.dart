import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/language_provider.dart';
import '../../constants.dart';
import '../../ota_update_service.dart';
import 'glass_dialog.dart';
import 'glass_widgets.dart';

/// Hiển thị hộp thoại cập nhật OTA chuẩn Bento Frosted Glass
Future<bool?> showGlassUpdateDialog({
  required BuildContext context,
  required UpdatePackageInfo packageInfo,
}) {
  final theme = context.read<ThemeProvider>();
  final isDark = theme.isDark;

  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'GlassUpdateDialog',
    barrierColor: isDark
        ? Colors.black.withValues(alpha: 0.65)
        : Colors.black.withValues(alpha: 0.40),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, anim1, anim2) =>
        GlassUpdateDialog(packageInfo: packageInfo),
    transitionBuilder: (ctx, anim1, anim2, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.94,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
    },
  );
}

/// Hộp thoại thông báo cập nhật Bento Frosted Glass
class GlassUpdateDialog extends StatefulWidget {
  final UpdatePackageInfo packageInfo;

  const GlassUpdateDialog({super.key, required this.packageInfo});

  @override
  State<GlassUpdateDialog> createState() => _GlassUpdateDialogState();
}

class _GlassUpdateDialogState extends State<GlassUpdateDialog> {
  bool _isUpdating = false;
  double _progress = 0.0;
  String _statusText = '';
  String? _errorMessage;

  Future<void> _startUpdate() async {
    setState(() {
      _isUpdating = true;
      _errorMessage = null;
      _progress = 0.05;
      _statusText = 'Đang khởi tạo...';
    });

    try {
      await OtaUpdateService().performUpdate(
        widget.packageInfo,
        onProgress: (prog, status) {
          if (mounted) {
            setState(() {
              _progress = prog;
              _statusText = status;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final lang = context.watch<LanguageProvider>();
    final colors = theme.colors;
    final isDark = theme.isDark;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (!_isUpdating &&
            event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop(false);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GlassDialog(
        title: lang.t('ota_dialog_title'),
        icon: Icons.system_update_alt_rounded,
        isDark: isDark,
        width: 520,
        blurSigma: theme.dialogBlur,
        bgOpacity: theme.dialogOpacity,
        actions: [
          if (!_isUpdating) ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                lang.t('ota_update_later'),
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            const SizedBox(width: 8),
            GlowingActionButton(
              height: 38,
              colors: colors,
              icon: Icons.download_rounded,
              label: lang.t('ota_update_now'),
              onPressed: _startUpdate,
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.subCardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.subCardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colors.accentEmerald,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    lang.t('ota_downloading'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.accentEmerald,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Info: Version Badge & Package Size
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.subCardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.subCardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.accentEmerald.withValues(alpha: 0.25),
                          colors.accentCyan.withValues(alpha: 0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.accentEmerald.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      color: colors.accentEmerald,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              appName,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.accentEmerald.withValues(
                                  alpha: 0.16,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: colors.accentEmerald.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Text(
                                widget.packageInfo.version.displayVersion,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colors.accentEmerald,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          lang.t('ota_package_size', [
                            widget.packageInfo.formattedSize,
                          ]),
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Release Notes Header
            Row(
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 15,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  lang.t('ota_release_notes'),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Release Notes Content Box
            Container(
              height: 150,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.subCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.subCardBorder),
              ),
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: SelectableText(
                    widget.packageInfo.releaseNotes ??
                        _generateFallbackReleaseNotes(lang),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),

            // Error message if any
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.accentRose.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.accentRose.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: colors.accentRose,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.accentRose,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Progress Bar & Status Text during update
            if (_isUpdating) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 6,
                  backgroundColor: colors.subCardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colors.accentEmerald,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _statusText,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: colors.accentEmerald,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _generateFallbackReleaseNotes(LanguageProvider lang) {
    return '''- Phiên bản mới: ${widget.packageInfo.version.displayVersion}
- Cập nhật tự động thông qua mạng nội bộ LAN (SMB/UNC)
- Tối ưu hóa hiệu năng, sửa lỗi và nâng cao độ mượt giao diện Bento Glassmorphism.''';
  }
}
