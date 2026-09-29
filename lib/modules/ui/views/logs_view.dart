// lib/modules/ui/views/logs_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../localization.dart';
import '../../logger_config.dart';
import '../../logic.dart';
import '../../native_bridge.dart';
import '../theme/theme_provider.dart';
import '../theme/language_provider.dart';
import '../widgets/app_toast.dart';
import '../widgets/glass_widgets.dart';

class LogsView extends StatefulWidget {
  final RouteFixerLogic logic;

  const LogsView({super.key, required this.logic});

  @override
  State<LogsView> createState() => _LogsViewState();
}

class _LogsViewState extends State<LogsView> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  String _searchQuery = '';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final language = context.watch<LanguageProvider>();
    final loc = AppLocalizations(language.currentLanguage.code);
    final allLogs = logMessages;
    final filtered = allLogs
        .where(
          (l) =>
              _searchQuery.isEmpty ||
              l.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return BentoCard(
      colors: colors,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.terminal_rounded,
                    color: colors.accentAmber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${loc.get('logs_title')} (${filtered.length})',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Auto-scroll toggle
                  InkWell(
                    onTap: () => setState(() => _autoScroll = !_autoScroll),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _autoScroll
                            ? colors.accentCyan.withValues(alpha: 0.12)
                            : colors.subCardBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _autoScroll
                              ? colors.accentCyan.withValues(alpha: 0.3)
                              : colors.subCardBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.vertical_align_bottom_rounded,
                            size: 13,
                            color: _autoScroll
                                ? colors.accentCyan
                                : colors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            loc.get('logs_auto_scroll'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _autoScroll
                                  ? colors.accentCyan
                                  : colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Export log
                  OutlinedButton.icon(
                    icon: Icon(
                      Icons.file_download_outlined,
                      size: 13,
                      color: colors.accentCyan,
                    ),
                    label: Text(
                      loc.get('logs_btn_export'),
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.accentCyan,
                      side: BorderSide(
                        color: colors.accentCyan.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: allLogs.isEmpty
                        ? null
                        : () async {
                            final now = DateTime.now();
                            String pad(int n) => n.toString().padLeft(2, '0');
                            final defName =
                                'ja_route_logs_${now.year}${pad(now.month)}${pad(now.day)}_${pad(now.hour)}${pad(now.minute)}${pad(now.second)}.log';
                            final path = await nativeBridge.engine
                                ?.selectSaveFilePath(defName);
                            if (path != null) {
                              try {
                                final f = File(path);
                                f.writeAsStringSync(allLogs.join('\n'));
                                if (context.mounted) {
                                  showAppToast(
                                    context,
                                    colors: colors,
                                    message:
                                        '${loc.get('logs_export_success_toast')}$path',
                                    icon: Icons.check_circle_rounded,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  showAppToast(
                                    context,
                                    colors: colors,
                                    message:
                                        '${loc.get('logs_export_fail_toast')}: $e',
                                    icon: Icons.error_rounded,
                                  );
                                }
                              }
                            }
                          },
                  ),
                  const SizedBox(width: 8),

                  // Clear log
                  OutlinedButton.icon(
                    icon: Icon(
                      Icons.delete_sweep_rounded,
                      size: 13,
                      color: colors.accentRose,
                    ),
                    label: Text(
                      loc.get('logs_btn_clear'),
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.accentRose,
                      side: BorderSide(
                        color: colors.accentRose.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {
                      logMessages.clear();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Bar
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: colors.subCardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.subCardBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 16, color: colors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (q) => setState(() => _searchQuery = q),
                    style: TextStyle(color: colors.textPrimary, fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: loc.get('logs_search_hint'),
                      hintStyle: TextStyle(
                        color: colors.textMuted.withValues(alpha: 0.6),
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Terminal Viewer
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.subCardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.subCardBorder),
              ),
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? loc.get('logs_empty_placeholder')
                            : loc.getWithParams('logs_no_match', {
                                'query': _searchQuery,
                              }),
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final line = filtered[index];
                          final isErr =
                              line.contains('[SEVERE]') ||
                              line.contains('Lỗi') ||
                              line.contains('Failed');
                          final isWarn =
                              line.contains('[WARNING]') ||
                              line.contains('Cảnh báo');
                          final isOk =
                              line.contains('[OK]') ||
                              line.contains('thành công') ||
                              line.contains('Enabled');

                          Color lineColor = colors.textPrimary;
                          if (isErr) {
                            lineColor = colors.accentRose;
                          } else if (isWarn) {
                            lineColor = colors.accentAmber;
                          } else if (isOk) {
                            lineColor = colors.accentEmerald;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: SelectableText(
                              line,
                              style: TextStyle(
                                fontFamily: 'Consolas',
                                fontSize: 11.5,
                                color: lineColor,
                                height: 1.4,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
