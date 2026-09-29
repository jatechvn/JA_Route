// lib/modules/ui/views/diagnostics_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../localization.dart';
import '../../logic.dart';
import '../../models/verification_model.dart';
import '../../native_bridge.dart';
import '../../services/verification_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../theme/language_provider.dart';
import '../widgets/app_toast.dart';
import '../widgets/glass_dialog.dart';
import '../widgets/glass_widgets.dart';

class DiagnosticsView extends StatefulWidget {
  final RouteFixerLogic logic;

  const DiagnosticsView({super.key, required this.logic});

  @override
  State<DiagnosticsView> createState() => _DiagnosticsViewState();
}

class _DiagnosticsViewState extends State<DiagnosticsView> {
  String _diagOutput = '';
  bool _diagRunning = false;
  String _currentTask = '';

  late final VerificationService _verificationService;
  VerifyResult? _lastVerifyResult;
  ExpectedRoute _selectedExpectedRoute = ExpectedRoute.auto;

  final TextEditingController _verifyTargetController = TextEditingController(
    text: '1.1.1.1',
  );
  List<Map<String, String>> _parsedRoutes = [];
  String _routeSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _verificationService = VerificationService(
      nativeBridge: nativeBridge,
      logic: widget.logic,
    );
    _fetchRoutes();
  }

  @override
  void dispose() {
    _verifyTargetController.dispose();
    super.dispose();
  }

  Future<void> _fetchRoutes() async {
    final engine = nativeBridge.engine;
    if (engine != null) {
      final raw = await engine.getRoutingTable();
      if (mounted) {
        setState(() {
          _parsedRoutes = _parseRouteTable(raw);
        });
      }
    }
  }

  List<Map<String, String>> _parseRouteTable(String rawOutput) {
    final List<Map<String, String>> list = [];
    final lines = rawOutput.split('\n');
    bool inIPv4Table = false;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.contains('Active Routes:') ||
          line.contains('Các tuyến đường hiện hoạt:')) {
        inIPv4Table = true;
        continue;
      }
      if (inIPv4Table &&
          (line.contains('Persistent Routes:') ||
              line.contains('Tuyến cố định:'))) {
        inIPv4Table = false;
        break;
      }
      if (inIPv4Table) {
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 5 &&
            RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(parts[0])) {
          list.add({
            'destination': parts[0],
            'netmask': parts[1],
            'gateway': parts[2],
            'interface': parts[3],
            'metric': parts[4],
          });
        }
      }
    }
    return list;
  }

  Future<void> _runDiagTask(
    String taskName,
    Future<String> Function() action,
  ) async {
    final langCode = context.read<LanguageProvider>().currentLanguage.code;
    final loc = AppLocalizations(langCode);

    setState(() {
      _diagRunning = true;
      _currentTask = taskName;
      _lastVerifyResult = null;
      _diagOutput = loc.getWithParams('diag_executing', {'task': taskName});
    });

    try {
      final result = await action();
      if (mounted) {
        setState(() {
          _diagOutput =
              '${loc.getWithParams('diag_result_title', {'task': taskName})}$result';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _diagOutput = loc.getWithParams('diag_error_executing', {
            'task': taskName,
            'err': e.toString(),
          });
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _diagRunning = false;
        });
      }
    }
  }

  Future<void> _runVerification([String? directTarget]) async {
    final input = directTarget ?? _verifyTargetController.text.trim();
    if (input.isEmpty) return;
    if (directTarget != null) {
      _verifyTargetController.text = directTarget;
    }

    final langCode = context.read<LanguageProvider>().currentLanguage.code;
    final loc = AppLocalizations(langCode);

    setState(() {
      _diagRunning = true;
      _currentTask = 'Verify: $input';
      _diagOutput = loc.getWithParams('diag_verifying_target', {
        'target': input,
      });
    });

    try {
      final target = VerifyTarget.parse(
        input,
        expectedRoute: _selectedExpectedRoute,
      );
      final result = await _verificationService.verify(target);
      if (mounted) {
        setState(() {
          _lastVerifyResult = result;
          _diagOutput = result.logs.join('\n');
          _diagRunning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _diagOutput = loc.getWithParams('diag_input_parse_error', {
            'err': e.toString(),
          });
          _diagRunning = false;
        });
      }
    }
  }

  Future<void> _handleQuickFix() async {
    if (_lastVerifyResult == null || _diagRunning) return;
    final langCode = context.read<LanguageProvider>().currentLanguage.code;
    final loc = AppLocalizations(langCode);
    final colors = context.appColors;

    if (!widget.logic.isAdmin) {
      showAppToast(
        context,
        colors: colors,
        message: loc.get('diag_admin_required_task'),
        icon: Icons.shield_outlined,
      );
      return;
    }

    setState(() => _diagRunning = true);
    bool ok;
    try {
      ok = await _verificationService.executeQuickFix(_lastVerifyResult!);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() => _diagRunning = false);

    if (mounted) {
      if (ok) {
        showAppToast(
          context,
          colors: colors,
          message: loc.get('verify_quick_fix_success'),
          icon: Icons.check_circle_rounded,
        );
        // Tự động verify lại để cập nhật trạng thái đã sửa
        await _runVerification();
        await _fetchRoutes();
      } else {
        showAppToast(
          context,
          colors: colors,
          message: loc.get('verify_quick_fix_fail'),
          icon: Icons.error_rounded,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final language = context.watch<LanguageProvider>();
    final loc = AppLocalizations(language.currentLanguage.code);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final quickCard = _buildQuickActionsCard(colors, loc);
        final outputCard = _buildOutputCard(colors, loc);
        final routingCard = _buildRoutingTableCard(colors, loc);

        if (isWide) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cột trái (flex: 5): Công cụ chẩn đoán nhanh & Màn hình Output
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      quickCard,
                      const SizedBox(height: 14),
                      outputCard,
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Cột phải (flex: 7): Bảng định tuyến IPv4
                Expanded(flex: 7, child: routingCard),
              ],
            ),
          );
        } else {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                quickCard,
                const SizedBox(height: 14),
                outputCard,
                const SizedBox(height: 14),
                routingCard,
                const SizedBox(height: 20),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildQuickActionsCard(AppColors colors, AppLocalizations loc) {
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
                    Icons.travel_explore_rounded,
                    color: colors.accentCyan,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loc.get('verify_suite_title'),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              // Expected Route Mode Selector
              GlassDropdown<ExpectedRoute>(
                items: [
                  GlassDropdownItem(
                    value: ExpectedRoute.auto,
                    label: loc.get('verify_route_auto'),
                    icon: Icons.auto_mode_rounded,
                  ),
                  GlassDropdownItem(
                    value: ExpectedRoute.lan,
                    label: loc.get('verify_route_lan'),
                    icon: Icons.lan_rounded,
                  ),
                  GlassDropdownItem(
                    value: ExpectedRoute.internet,
                    label: loc.get('verify_route_internet'),
                    icon: Icons.public_rounded,
                  ),
                ],
                value: _selectedExpectedRoute,
                onChanged: (val) =>
                    setState(() => _selectedExpectedRoute = val),
                colors: colors,
                enableSearch: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                borderRadius: 8,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Smart Verify Input Bar
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _verifyTargetController,
                    onSubmitted: (_) => _runVerification(),
                    style: TextStyle(color: colors.textPrimary, fontSize: 12),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: colors.accentCyan,
                      ),
                      hintText: loc.get('verify_input_hint'),
                      hintStyle: TextStyle(
                        color: colors.textMuted.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                      filled: true,
                      fillColor: colors.subCardBg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colors.subCardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colors.subCardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colors.accentCyan,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: _diagRunning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(
                        Icons.bolt_rounded,
                        size: 16,
                        color: Colors.black,
                      ),
                label: Text(
                  loc.get('verify_btn'),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentCyan,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _diagRunning ? null : () => _runVerification(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 1-Click Quick Target Presets
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildPresetChip('Google (8.8.8.8)', '8.8.8.8', colors),
              _buildPresetChip('Cloudflare (1.1.1.1)', '1.1.1.1', colors),
              if (widget.logic.config.lanGateway.isNotEmpty)
                _buildPresetChip(
                  loc.getWithParams('preset_lan_gw', {
                    'ip': widget.logic.config.lanGateway,
                  }),
                  widget.logic.config.lanGateway,
                  colors,
                ),
              if (widget.logic.config.internetGateway.isNotEmpty)
                _buildPresetChip(
                  loc.getWithParams('preset_internet_gw', {
                    'ip': widget.logic.config.internetGateway,
                  }),
                  widget.logic.config.internetGateway,
                  colors,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: colors.subCardBorder, height: 1),
          const SizedBox(height: 10),

          // Action Grid Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDiagButton(
                label: loc.get('diag_btn_tailscale'),
                icon: Icons.vpn_lock_rounded,
                color: colors.accentPurple,
                onTap: () => _runDiagTask('Tailscale Status', () async {
                  final res = await nativeBridge.engine?.getTailscaleStatus();
                  return res ?? loc.get('diag_tailscale_not_found');
                }),
                colors: colors,
              ),
              _buildDiagButton(
                label: loc.get('diag_port_test'),
                icon: Icons.electrical_services_rounded,
                color: colors.accentEmerald,
                onTap: () => _runDiagTask(loc.get('diag_port_test'), () async {
                  final gw = widget.logic.config.lanGateway.isNotEmpty
                      ? widget.logic.config.lanGateway
                      : '172.21.168.1';
                  final res = await nativeBridge.engine?.testConnection(gw, 80);
                  return res ?? loc.get('diag_port_check_failed');
                }),
                colors: colors,
              ),
              _buildDiagButton(
                label: loc.get('diag_btn_flush'),
                icon: Icons.cleaning_services_rounded,
                color: colors.accentAmber,
                onTap: () => _runDiagTask(loc.get('diag_btn_flush'), () async {
                  if (!widget.logic.isAdmin) {
                    return loc.get('diag_admin_required_task');
                  }
                  final ok = await nativeBridge.engine?.flushArpDns();
                  return (ok ?? false)
                      ? loc.get('diag_flush_success')
                      : loc.get('diag_task_failed');
                }),
                colors: colors,
              ),
              _buildDiagButton(
                label: loc.get('diag_restore_defaults'),
                icon: Icons.settings_backup_restore_rounded,
                color: colors.accentRose,
                onTap: () => _showRestoreDefaultsDialog(context, colors, loc),
                colors: colors,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, String targetIp, AppColors colors) {
    return InkWell(
      onTap: () => _runVerification(targetIp),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.subCardBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.subCardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_outlined, size: 12, color: colors.accentCyan),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required AppColors colors,
  }) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 15, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        backgroundColor: color.withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: _diagRunning ? null : onTap,
    );
  }

  Widget _buildOutputCard(AppColors colors, AppLocalizations loc) {
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
                    Icons.terminal_rounded,
                    size: 16,
                    color: colors.accentCyan,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentTask.isNotEmpty
                        ? '${loc.get('diag_terminal_output_title')}: $_currentTask'
                        : loc.get('diag_terminal_output_title'),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_diagOutput.isNotEmpty)
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _diagOutput));
                        showAppToast(
                          context,
                          colors: colors,
                          message: loc.get('verify_logs_copied'),
                          icon: Icons.check_circle_rounded,
                        );
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              size: 12,
                              color: colors.accentCyan,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              loc.get('verify_copy_logs'),
                              style: TextStyle(
                                fontSize: 10.5,
                                color: colors.accentCyan,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (_diagOutput.isNotEmpty || _lastVerifyResult != null)
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: colors.textMuted,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() {
                        _diagOutput = '';
                        _lastVerifyResult = null;
                      }),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_lastVerifyResult != null) ...[
            _buildSmartDiagnosisCard(colors, loc, _lastVerifyResult!),
            const SizedBox(height: 12),
          ],
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 85),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.subCardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.subCardBorder),
            ),
            child: _diagRunning
                ? Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.accentCyan,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        loc.get('diag_terminal_running'),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  )
                : (_diagOutput.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              loc.get('diag_terminal_idle_hint'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textMuted,
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                          ),
                        )
                      : SelectableText(
                          _diagOutput,
                          style: TextStyle(
                            fontFamily: 'Consolas',
                            fontSize: 11,
                            color: colors.textPrimary,
                            height: 1.4,
                          ),
                        )),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartDiagnosisCard(
    AppColors colors,
    AppLocalizations loc,
    VerifyResult result,
  ) {
    Color statusColor;
    IconData statusIcon;
    String statusTitle;

    switch (result.status) {
      case VerifyStatus.pass:
        statusColor = colors.accentEmerald;
        statusIcon = Icons.check_circle_rounded;
        statusTitle = loc.get('verify_status_pass');
        break;
      case VerifyStatus.warning:
        statusColor = colors.accentAmber;
        statusIcon = Icons.warning_amber_rounded;
        statusTitle = loc.get(
          result.isMisrouted
              ? 'verify_status_misrouted'
              : 'verify_status_warning',
        );
        break;
      case VerifyStatus.fail:
        statusColor = colors.accentRose;
        statusIcon = Icons.error_outline_rounded;
        statusTitle = loc.get('verify_status_unreachable');
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusTitle,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (result.pingLatencyMs != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.subCardBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.subCardBorder),
                  ),
                  child: Text(
                    '${result.pingLatencyMs}ms',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Metrics Tiles Row
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.subCardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.subCardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricTile(
                  loc.get('metric_destination'),
                  result.resolvedIp ?? result.target.host,
                  colors.accentCyan,
                  colors,
                ),
                _buildMetricTile(
                  loc.get('metric_active_gateway'),
                  result.activeGateway?.isEmpty ?? true
                      ? 'On-link'
                      : result.activeGateway!,
                  result.isMisrouted
                      ? colors.accentAmber
                      : colors.accentEmerald,
                  colors,
                ),
                _buildMetricTile(
                  loc.get('metric_interface'),
                  result.activeInterface ?? 'Auto',
                  colors.textPrimary,
                  colors,
                ),
                if (result.dnsTimeMs != null)
                  _buildMetricTile(
                    loc.get('metric_dns'),
                    '${result.dnsTimeMs}ms',
                    colors.accentPurple,
                    colors,
                  ),
              ],
            ),
          ),

          // Root Cause Box if warning/fail
          if (result.rootCause != null) ...[
            const SizedBox(height: 10),
            Text(
              loc.get('verify_root_cause_title'),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              result.rootCause!,
              style: TextStyle(
                fontSize: 11,
                color: colors.textPrimary,
                height: 1.35,
              ),
            ),
          ],

          // Recommendations List
          if (result.recommendations.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              loc.get('verify_fix_advice_title'),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            ...result.recommendations.map(
              (rec) => _buildRecommendationItem(rec, colors, loc),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    Color valColor,
    AppColors colors,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            color: colors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            color: valColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationItem(
    FixRecommendation rec,
    AppColors colors,
    AppLocalizations loc,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.subCardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.subCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 14,
                color: colors.accentAmber,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  rec.title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            rec.description,
            style: TextStyle(
              fontSize: 10.5,
              color: colors.textMuted,
              height: 1.3,
            ),
          ),
          if (rec.isQuickFixable) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 30,
              child: ElevatedButton.icon(
                icon: const Icon(
                  Icons.bolt_rounded,
                  size: 14,
                  color: Colors.black,
                ),
                label: Text(
                  loc.get('verify_btn_quick_fix'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentAmber,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: _diagRunning ? null : _handleQuickFix,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoutingTableCard(AppColors colors, AppLocalizations loc) {
    final filtered = _parsedRoutes.where((r) {
      if (_routeSearchQuery.isEmpty) return true;
      final q = _routeSearchQuery.toLowerCase();
      return (r['destination']?.toLowerCase().contains(q) ?? false) ||
          (r['gateway']?.toLowerCase().contains(q) ?? false) ||
          (r['interface']?.toLowerCase().contains(q) ?? false);
    }).toList();

    return BentoCard(
      colors: colors,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.table_chart_rounded,
                    color: colors.accentCyan,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loc.getWithParams('diag_routing_table_title', {
                      'count': '${filtered.length}',
                    }),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: colors.accentCyan,
                ),
                tooltip: loc.get('diag_refresh_tooltip'),
                onPressed: _fetchRoutes,
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                    onChanged: (q) => setState(() => _routeSearchQuery = q),
                    style: TextStyle(color: colors.textPrimary, fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: loc.get('diag_search_placeholder'),
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
          const SizedBox(height: 14),

          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text(
                loc.get('diag_no_routes_found'),
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final minWidth = constraints.maxWidth < 600
                    ? 600.0
                    : constraints.maxWidth;
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.subCardBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: minWidth),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2.6),
                          1: FlexColumnWidth(2.3),
                          2: FlexColumnWidth(2.4),
                          3: FlexColumnWidth(2.4),
                          4: FlexColumnWidth(1.2),
                        },
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: colors.subCardBg),
                            children: [
                              _buildTableHeaderCell(
                                loc.get('table_dest'),
                                colors.accentCyan,
                              ),
                              _buildTableHeaderCell(
                                loc.get('table_netmask'),
                                colors.textPrimary,
                              ),
                              _buildTableHeaderCell(
                                loc.get('table_gateway'),
                                colors.accentEmerald,
                              ),
                              _buildTableHeaderCell(
                                loc.get('table_interface'),
                                colors.textPrimary,
                              ),
                              _buildTableHeaderCell(
                                loc.get('table_metric'),
                                colors.accentPurple,
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                          ...filtered.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final row = entry.value;
                            final isDefault = row['destination'] == '0.0.0.0';
                            final isLan =
                                row['gateway'] ==
                                widget.logic.config.lanGateway;
                            final isInternet =
                                row['gateway'] ==
                                widget.logic.config.internetGateway;
                            final isEven = idx % 2 == 0;

                            return TableRow(
                              decoration: BoxDecoration(
                                color: isEven
                                    ? Colors.transparent
                                    : colors.subCardBg.withValues(alpha: 0.35),
                                border: Border(
                                  bottom: BorderSide(
                                    color: colors.subCardBorder.withValues(
                                      alpha: 0.35,
                                    ),
                                    width: 0.8,
                                  ),
                                ),
                              ),
                              children: [
                                _buildTableCell(
                                  row['destination'] ?? '',
                                  color: isDefault
                                      ? colors.accentCyan
                                      : colors.textPrimary,
                                  isBold: isDefault,
                                ),
                                _buildTableCell(
                                  row['netmask'] ?? '',
                                  color: colors.textMuted,
                                ),
                                _buildTableCell(
                                  row['gateway'] ?? '',
                                  color: isLan
                                      ? colors.accentAmber
                                      : (isInternet
                                            ? colors.accentEmerald
                                            : colors.textPrimary),
                                  isBold: isLan || isInternet,
                                ),
                                _buildTableCell(
                                  row['interface'] ?? '',
                                  color: colors.textMuted,
                                ),
                                _buildTableCell(
                                  row['metric'] ?? '',
                                  color: colors.accentPurple,
                                  isBold: true,
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(
    String label,
    Color color, {
    TextAlign textAlign = TextAlign.left,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        label,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTableCell(
    String text, {
    required Color color,
    bool isBold = false,
    TextAlign textAlign = TextAlign.left,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  void _showRestoreDefaultsDialog(
    BuildContext context,
    AppColors colors,
    AppLocalizations loc,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        isDark: isDark,
        title: loc.get('diag_restore_dialog_title'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.get('diag_restore_dialog_desc'),
              style: TextStyle(
                fontSize: 12.5,
                color: colors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    loc.get('diag_restore_cancel'),
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentRose,
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    _runDiagTask(loc.get('diag_restore_defaults'), () async {
                      if (!widget.logic.isAdmin) {
                        return loc.get('diag_admin_required_task');
                      }
                      final ok = await nativeBridge.engine
                          ?.restoreSystemDefaults();
                      return (ok ?? false)
                          ? loc.get('diag_restore_success')
                          : loc.get('diag_task_failed');
                    });
                  },
                  child: Text(
                    loc.get('diag_restore_confirm'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
