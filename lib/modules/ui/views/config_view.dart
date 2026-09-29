// lib/modules/ui/views/config_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../localization.dart';
import '../../logic.dart';
import '../../native_bridge.dart';
import '../../utils.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../theme/language_provider.dart';
import '../widgets/app_toast.dart';
import '../widgets/glass_dialog.dart';
import '../widgets/glass_widgets.dart';

class ConfigView extends StatefulWidget {
  final RouteFixerLogic logic;

  const ConfigView({super.key, required this.logic});

  @override
  State<ConfigView> createState() => _ConfigViewState();
}

class _ConfigViewState extends State<ConfigView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _internetGwController;
  late TextEditingController _backupGwController;
  late TextEditingController _lanGwController;
  late TextEditingController _lanNetController;
  late TextEditingController _lanMaskController;
  late TextEditingController _logFilePathController;

  List<TextEditingController> _lanRouteControllers = [];
  List<TextEditingController> _internetRouteControllers = [];

  String? _selectedBackupTimestamp;

  @override
  void initState() {
    super.initState();
    final cfg = widget.logic.config;
    _internetGwController = TextEditingController(text: cfg.internetGateway);
    _backupGwController = TextEditingController(text: cfg.backupGateway);
    _lanGwController = TextEditingController(text: cfg.lanGateway);
    _lanNetController = TextEditingController(text: cfg.lanNetwork);
    _lanMaskController = TextEditingController(text: cfg.lanMask);
    _logFilePathController = TextEditingController(text: cfg.logFilePath);

    _lanRouteControllers = cfg.customLanRoutes
        .map((r) => TextEditingController(text: r))
        .toList();
    _internetRouteControllers = cfg.customInternetRoutes
        .map((r) => TextEditingController(text: r))
        .toList();

    widget.logic.scanBackups();
  }

  @override
  void dispose() {
    _internetGwController.dispose();
    _backupGwController.dispose();
    _lanGwController.dispose();
    _lanNetController.dispose();
    _lanMaskController.dispose();
    _logFilePathController.dispose();
    for (final c in _lanRouteControllers) {
      c.dispose();
    }
    for (final c in _internetRouteControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _disposeRouteControllers(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  void _syncControllers() {
    final cfg = widget.logic.config;
    _internetGwController.text = cfg.internetGateway;
    _backupGwController.text = cfg.backupGateway;
    _lanGwController.text = cfg.lanGateway;
    _lanNetController.text = cfg.lanNetwork;
    _lanMaskController.text = cfg.lanMask;
    _logFilePathController.text = cfg.logFilePath;

    final oldLanControllers = _lanRouteControllers;
    final oldInternetControllers = _internetRouteControllers;

    setState(() {
      _lanRouteControllers = cfg.customLanRoutes
          .map((r) => TextEditingController(text: r))
          .toList();
      _internetRouteControllers = cfg.customInternetRoutes
          .map((r) => TextEditingController(text: r))
          .toList();
    });

    _disposeRouteControllers(oldLanControllers);
    _disposeRouteControllers(oldInternetControllers);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final language = context.watch<LanguageProvider>();
    final loc = AppLocalizations(language.currentLanguage.code);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final profileCard = _buildProfileCard(colors, loc);
        final gatewaysCard = _buildGatewaysCard(colors, loc);
        final subnetsCard = _buildSubnetsCard(colors, loc);
        final routesCard = _buildCustomRoutesCard(colors, loc);
        final backupCard = _buildBackupRestoreCard(colors, loc);
        final saveButton = _buildSaveButton(colors, loc);

        if (isWide) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cột trái (flex: 6): Hồ sơ mạng, Gateway, Dải mạng & Log
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            profileCard,
                            const SizedBox(height: 14),
                            gatewaysCard,
                            const SizedBox(height: 14),
                            subnetsCard,
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Cột phải (flex: 6): Định tuyến tùy chỉnh, Điểm khôi phục, Nút Lưu
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            routesCard,
                            const SizedBox(height: 14),
                            backupCard,
                            const SizedBox(height: 14),
                            saveButton,
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          );
        } else {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  profileCard,
                  const SizedBox(height: 14),
                  gatewaysCard,
                  const SizedBox(height: 14),
                  subnetsCard,
                  const SizedBox(height: 14),
                  routesCard,
                  const SizedBox(height: 14),
                  backupCard,
                  const SizedBox(height: 14),
                  saveButton,
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildProfileCard(AppColors colors, AppLocalizations loc) {
    return BentoCard(
      colors: colors,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge_rounded, color: colors.accentCyan, size: 18),
              const SizedBox(width: 8),
              Text(
                loc.get('profile_title'),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GlassDropdown<String>(
                  items: widget.logic.config.profiles.keys.map((name) {
                    final displayName = name == 'Mặc định'
                        ? loc.get('profile_default')
                        : name;
                    return GlassDropdownItem<String>(
                      value: name,
                      label: displayName,
                      icon: name == 'Mặc định'
                          ? Icons.home_rounded
                          : Icons.work_outline_rounded,
                      badge: name == widget.logic.config.activeProfile
                          ? 'ACTIVE'
                          : null,
                    );
                  }).toList(),
                  value: widget.logic.config.activeProfile,
                  onChanged: (val) {
                    widget.logic.switchProfile(val);
                    _syncControllers();
                  },
                  colors: colors,
                  enableSearch: widget.logic.config.profiles.length > 5,
                  borderRadius: 10,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline_rounded,
                  color: colors.accentEmerald,
                  size: 22,
                ),
                tooltip: loc.get('profile_tooltip_add'),
                onPressed: () => _showAddProfileDialog(context, colors, loc),
              ),
              if (widget.logic.config.activeProfile != 'Mặc định')
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: colors.accentRose,
                    size: 22,
                  ),
                  tooltip: loc.get('profile_tooltip_delete'),
                  onPressed: () {
                    widget.logic.deleteProfile(
                      widget.logic.config.activeProfile,
                    );
                    _syncControllers();
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: colors.subCardBorder, height: 1),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text(
              loc.get('auto_heal_title'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            subtitle: Text(
              loc.get('auto_heal_desc'),
              style: TextStyle(fontSize: 11, color: colors.textMuted),
            ),
            value: widget.logic.config.autoFixEnabled,
            activeThumbColor: colors.accentCyan,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              final newConfig = widget.logic.config.copyWith(
                autoFixEnabled: val,
              );
              widget.logic.saveConfig(newConfig);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGatewaysCard(AppColors colors, AppLocalizations loc) {
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
                    Icons.router_rounded,
                    color: colors.accentEmerald,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loc.get('gateways_card_title'),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                icon: Icon(
                  Icons.autorenew_rounded,
                  size: 14,
                  color: colors.accentEmerald,
                ),
                label: Text(
                  loc.get('config_btn_detect'),
                  style: TextStyle(fontSize: 11, color: colors.accentEmerald),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: colors.accentEmerald.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  final detected = await nativeBridge.engine
                      ?.detectActiveGateways();
                  if (detected != null && mounted) {
                    var didUpdate = false;
                    setState(() {
                      final internetGateway = detected['internetGateway'] ?? '';
                      final lanGateway = detected['lanGateway'] ?? '';

                      if (internetGateway.isNotEmpty) {
                        _internetGwController.text = internetGateway;
                        didUpdate = true;
                      }
                      if (lanGateway.isNotEmpty) {
                        _lanGwController.text = lanGateway;
                        didUpdate = true;
                      }
                    });
                    showAppToast(
                      context,
                      message: didUpdate
                          ? loc.get('config_detect_success')
                          : loc.get('config_detect_fail'),
                      colors: colors,
                      icon: didUpdate
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _internetGwController,
            label: loc.get('config_internet_gw'),
            hint: '192.168.100.1',
            colors: colors,
            validator: (v) => (v == null || !isValidIPv4(v))
                ? loc.get('config_ipv4_invalid')
                : null,
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _backupGwController,
            label: loc.get('config_backup_gw'),
            hint: '192.168.1.1',
            colors: colors,
            validator: (v) {
              final value = v?.trim() ?? '';
              return value.isNotEmpty && !isValidIPv4(value)
                  ? loc.get('config_ipv4_invalid')
                  : null;
            },
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _lanGwController,
            label: loc.get('config_lan_gw'),
            hint: '172.21.168.1',
            colors: colors,
            validator: (v) => (v == null || !isValidIPv4(v))
                ? loc.get('config_ipv4_invalid')
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSubnetsCard(AppColors colors, AppLocalizations loc) {
    return BentoCard(
      colors: colors,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hub_rounded, color: colors.accentPurple, size: 18),
              const SizedBox(width: 8),
              Text(
                loc.get('subnets_card_title'),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _lanNetController,
                  label: loc.get('config_lan_net'),
                  hint: '10.0.0.0',
                  colors: colors,
                  validator: (v) => (v == null || !isValidIPv4(v))
                      ? loc.get('config_ipv4_invalid')
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  controller: _lanMaskController,
                  label: loc.get('config_lan_mask'),
                  hint: '255.0.0.0',
                  colors: colors,
                  validator: (v) => (v == null || !isValidSubnetMask(v))
                      ? loc.get('config_subnet_invalid')
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _logFilePathController,
            label: loc.get('config_log_path'),
            hint: 'logs/ja_route.log',
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomRoutesCard(AppColors colors, AppLocalizations loc) {
    return BentoCard(
      colors: colors,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.linear_scale_rounded,
                color: colors.accentAmber,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                loc.get('config_custom_routes'),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildRouteSection(
            title: loc.get('config_lan_dest'),
            desc: loc.get('config_lan_dest_desc'),
            controllers: _lanRouteControllers,
            onAdd: () => setState(
              () => _lanRouteControllers.add(TextEditingController()),
            ),
            onRemove: (idx) =>
                setState(() => _lanRouteControllers.removeAt(idx).dispose()),
            colors: colors,
            loc: loc,
          ),
          const SizedBox(height: 16),
          Divider(color: colors.subCardBorder, height: 1),
          const SizedBox(height: 14),

          _buildRouteSection(
            title: loc.get('config_internet_dest'),
            desc: loc.get('config_internet_dest_desc'),
            controllers: _internetRouteControllers,
            onAdd: () => setState(
              () => _internetRouteControllers.add(TextEditingController()),
            ),
            onRemove: (idx) => setState(
              () => _internetRouteControllers.removeAt(idx).dispose(),
            ),
            colors: colors,
            loc: loc,
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSection({
    required String title,
    required String desc,
    required List<TextEditingController> controllers,
    required VoidCallback onAdd,
    required ValueChanged<int> onRemove,
    required AppColors colors,
    required AppLocalizations loc,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(fontSize: 10.5, color: colors.textMuted),
                ),
              ],
            ),
            OutlinedButton.icon(
              icon: Icon(Icons.add_rounded, size: 13, color: colors.accentCyan),
              label: Text(
                loc.get('add_btn'),
                style: TextStyle(fontSize: 11, color: colors.accentCyan),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: colors.accentCyan.withValues(alpha: 0.35),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: onAdd,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (controllers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              loc.get('no_custom_routes'),
              style: TextStyle(
                fontSize: 11,
                color: colors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...controllers.asMap().entries.map((entry) {
            final idx = entry.key;
            final ctrl = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: ctrl,
                      label: loc.getWithParams('config_subnet_item', {
                        'index': '${idx + 1}',
                      }),
                      hint: loc.get('config_subnet_hint'),
                      colors: colors,
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        return value.isNotEmpty && !isValidRouteSpec(value)
                            ? loc.get('config_subnet_invalid')
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline_rounded,
                      color: colors.accentRose,
                      size: 20,
                    ),
                    onPressed: () => onRemove(idx),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildBackupRestoreCard(AppColors colors, AppLocalizations loc) {
    return BentoCard(
      colors: colors,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, color: colors.accentPurple, size: 18),
              const SizedBox(width: 8),
              Text(
                loc.get('config_recovery_title'),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.get('config_recovery_win'),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    loc.get('config_recovery_win_desc'),
                    style: TextStyle(fontSize: 10.5, color: colors.textMuted),
                  ),
                ],
              ),
              OutlinedButton.icon(
                icon: Icon(
                  Icons.add_rounded,
                  size: 14,
                  color: colors.accentEmerald,
                ),
                label: Text(
                  loc.get('config_btn_create'),
                  style: TextStyle(fontSize: 11, color: colors.accentEmerald),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: colors.accentEmerald.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  final ok = await widget.logic.runBackup();
                  if (mounted) {
                    showAppToast(
                      context,
                      colors: colors,
                      message: ok
                          ? loc.get('config_dialog_backup_success')
                          : loc.get('config_dialog_backup_fail'),
                      icon: ok
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                    );
                    setState(() {});
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (widget.logic.availableBackups.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: GlassDropdown<String>(
                    items: widget.logic.availableBackups
                        .map(
                          (ts) => GlassDropdownItem<String>(
                            value: ts,
                            label: ts,
                            icon: Icons.history_rounded,
                          ),
                        )
                        .toList(),
                    value:
                        _selectedBackupTimestamp ??
                        widget.logic.availableBackups.first,
                    onChanged: (val) =>
                        setState(() => _selectedBackupTimestamp = val),
                    colors: colors,
                    enableSearch: false,
                    borderRadius: 8,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  icon: Icon(
                    Icons.restore_rounded,
                    size: 14,
                    color: colors.accentAmber,
                  ),
                  label: Text(
                    loc.get('config_btn_restore'),
                    style: TextStyle(fontSize: 11, color: colors.accentAmber),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: colors.accentAmber.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final ts =
                        _selectedBackupTimestamp ??
                        (widget.logic.availableBackups.isNotEmpty
                            ? widget.logic.availableBackups.first
                            : null);
                    if (ts != null) {
                      final ok = await widget.logic.runRestore(ts);
                      if (mounted) {
                        _syncControllers();
                        showAppToast(
                          context,
                          colors: colors,
                          message: ok
                              ? loc.get('config_dialog_restore_success')
                              : loc.get('config_dialog_restore_fail'),
                          icon: ok
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                        );
                      }
                    }
                  },
                ),
              ],
            ),

          const SizedBox(height: 16),
          Divider(color: colors.subCardBorder, height: 1),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(
                    Icons.file_upload_outlined,
                    size: 15,
                    color: colors.accentCyan,
                  ),
                  label: Text(
                    loc.get('config_btn_export'),
                    style: TextStyle(fontSize: 12, color: colors.accentCyan),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: colors.accentCyan.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final now = DateTime.now();
                    String pad(int n) => n.toString().padLeft(2, '0');
                    final defName =
                        'ja_route_config_${now.year}${pad(now.month)}${pad(now.day)}_${pad(now.hour)}${pad(now.minute)}${pad(now.second)}.json';
                    final path = await nativeBridge.engine?.selectSaveFilePath(
                      defName,
                    );
                    final outPath = await widget.logic.exportConfiguration(
                      customPath: path,
                    );
                    if (mounted && outPath != null) {
                      showAppToast(
                        context,
                        colors: colors,
                        message: loc.getWithParams('config_toast_exported', {
                          'path': outPath,
                        }),
                        icon: Icons.check_circle_rounded,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(
                    Icons.file_download_outlined,
                    size: 15,
                    color: colors.accentPurple,
                  ),
                  label: Text(
                    loc.get('config_btn_import'),
                    style: TextStyle(fontSize: 12, color: colors.accentPurple),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: colors.accentPurple.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final path = await nativeBridge.engine?.pickConfigFile();
                    if (path != null) {
                      final ok = await widget.logic.importConfigurationFile(
                        path,
                      );
                      if (mounted) {
                        if (ok) _syncControllers();
                        showAppToast(
                          context,
                          colors: colors,
                          message: ok
                              ? loc.get('config_dialog_import_success')
                              : loc.get('config_dialog_import_fail'),
                          icon: ok
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(AppColors colors, AppLocalizations loc) {
    return SizedBox(
      width: double.infinity,
      child: GlowingActionButton(
        height: 48,
        colors: colors,
        isDestructive: false,
        icon: Icons.save_rounded,
        label: loc.get('config_btn_save'),
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            final lanRoutes = _lanRouteControllers
                .map((c) => c.text.trim())
                .where((e) => e.isNotEmpty)
                .map(normalizeRouteSpec)
                .whereType<String>()
                .toList();
            final internetRoutes = _internetRouteControllers
                .map((c) => c.text.trim())
                .where((e) => e.isNotEmpty)
                .map(normalizeRouteSpec)
                .whereType<String>()
                .toList();

            final newConfig = widget.logic.config.copyWith(
              internetGateway: _internetGwController.text.trim(),
              backupGateway: _backupGwController.text.trim(),
              lanGateway: _lanGwController.text.trim(),
              lanNetwork: _lanNetController.text.trim(),
              lanMask: _lanMaskController.text.trim(),
              logFilePath: _logFilePathController.text.trim(),
              customLanRoutes: lanRoutes,
              customInternetRoutes: internetRoutes,
            );

            widget.logic.saveConfig(newConfig);
            showAppToast(
              context,
              colors: colors,
              message: loc.get('config_dialog_save_success'),
              icon: Icons.check_circle_rounded,
            );
          }
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required AppColors colors,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: colors.textPrimary, fontSize: 12.5),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textMuted, fontSize: 11),
        hintText: hint,
        hintStyle: TextStyle(
          color: colors.textMuted.withValues(alpha: 0.5),
          fontSize: 11,
        ),
        filled: true,
        fillColor: colors.subCardBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.subCardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.subCardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.accentCyan, width: 1.5),
        ),
      ),
    );
  }

  void _showAddProfileDialog(
    BuildContext context,
    AppColors colors,
    AppLocalizations loc,
  ) {
    final nameCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        isDark: isDark,
        title: loc.get('profile_dialog_new_title'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.get('profile_dialog_new_desc'),
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: TextStyle(color: colors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: loc.get('profile_dialog_hint'),
                hintStyle: TextStyle(
                  color: colors.textMuted.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                filled: true,
                fillColor: colors.subCardBg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.subCardBorder),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    loc.get('btn_cancel'),
                    style: TextStyle(color: colors.textMuted),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentCyan,
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isNotEmpty) {
                      widget.logic.createNewProfile(name);
                      Navigator.pop(ctx);
                      _syncControllers();
                    }
                  },
                  child: Text(
                    loc.get('config_btn_create'),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).whenComplete(nameCtrl.dispose);
  }
}
