part of 'dashboard_shell.dart';

class TopBarExpandingButton extends StatefulWidget {
  final Widget icon;
  final String? collapsedLabel;
  final String expandedLabel;
  final Color? textColor;
  final VoidCallback onTap;
  final String tooltip;
  final AppColors colors;
  final bool isCompact;

  const TopBarExpandingButton({
    super.key,
    required this.icon,
    this.collapsedLabel,
    required this.expandedLabel,
    this.textColor,
    required this.onTap,
    required this.tooltip,
    required this.colors,
    this.isCompact = false,
  });

  @override
  State<TopBarExpandingButton> createState() => _TopBarExpandingButtonState();
}

class _TopBarExpandingButtonState extends State<TopBarExpandingButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final showLabel =
        _isHovered || (!widget.isCompact && widget.collapsedLabel != null);
    final currentLabel = _isHovered
        ? widget.expandedLabel
        : (widget.collapsedLabel ?? '');

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(100),
              splashFactory: NoSplash.splashFactory,
              hoverColor: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: showLabel ? 11 : 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? colors.cardHoverBg.withValues(alpha: 0.35)
                      : colors.subCardBg,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: _isHovered
                        ? (widget.textColor ?? colors.accentCyan).withValues(
                            alpha: 0.65,
                          )
                        : colors.subCardBorder,
                    width: _isHovered ? 1.2 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isHovered
                          ? (widget.textColor ?? colors.primaryGlow).withValues(
                              alpha: 0.25,
                            )
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: _isHovered ? 10 : 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    widget.icon,
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      clipBehavior: Clip.none,
                      child: showLabel && currentLabel.isNotEmpty
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 6),
                                Text(
                                  currentLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  style: TextStyle(
                                    color:
                                        widget.textColor ?? colors.textPrimary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Backward compatibility alias
typedef TopBarPillButton = TopBarExpandingButton;

class _SettingsTabSelector extends StatelessWidget {
  const _SettingsTabSelector({
    required this.activeTab,
    required this.colors,
    required this.language,
    required this.onTabSelected,
  });

  final int activeTab;
  final AppColors colors;
  final LanguageProvider language;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.subCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.subCardBorder),
      ),
      child: Row(
        children: [
          _buildItem(0, Icons.tune_rounded, language.t('tab_settings_ui')),
          _buildItem(
            1,
            Icons.system_update_alt_rounded,
            language.t('tab_ota_update'),
          ),
          _buildItem(2, Icons.menu_book_rounded, language.t('tab_user_guide')),
          _buildItem(3, Icons.info_outline_rounded, language.t('tab_about')),
        ],
      ),
    );
  }

  Widget _buildItem(int index, IconData icon, String label) {
    final isSelected = activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      colors.accentColor,
                      colors.accentCyan.withValues(alpha: 0.85),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : colors.textSecondary,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : colors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
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

class _SettingsGlassTuningTab extends StatelessWidget {
  const _SettingsGlassTuningTab({
    required this.colors,
    required this.theme,
    required this.language,
    required this.localCardBlur,
    required this.localCardOpacity,
    required this.localDialogBlur,
    required this.localDialogOpacity,
    required this.localDropdownBlur,
    required this.localDropdownOpacity,
    required this.onCardBlurChanged,
    required this.onCardOpacityChanged,
    required this.onDialogBlurChanged,
    required this.onDialogOpacityChanged,
    required this.onDropdownBlurChanged,
    required this.onDropdownOpacityChanged,
    required this.onResetDefaults,
  });

  final AppColors colors;
  final ThemeProvider theme;
  final LanguageProvider language;
  final double localCardBlur;
  final double localCardOpacity;
  final double localDialogBlur;
  final double localDialogOpacity;
  final double localDropdownBlur;
  final double localDropdownOpacity;
  final ValueChanged<double> onCardBlurChanged;
  final ValueChanged<double> onCardOpacityChanged;
  final ValueChanged<double> onDialogBlurChanged;
  final ValueChanged<double> onDialogOpacityChanged;
  final ValueChanged<double> onDropdownBlurChanged;
  final ValueChanged<double> onDropdownOpacityChanged;
  final VoidCallback onResetDefaults;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: BentoCard(
        colors: colors,
        blurSigma: localCardBlur,
        bgOpacity: localCardOpacity,
        padding: const EdgeInsets.all(16),
        borderRadius: 14,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.blur_on_rounded,
                        size: 18,
                        color: colors.accentPurple,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          language.t('settings_card_header'),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onResetDefaults,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    child: Text(
                      language.t('settings_default'),
                      style: TextStyle(
                        color: colors.accentCyan,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SettingsGlassSlider(
              label: language.t('settings_card_blur'),
              value: localCardBlur,
              min: 0,
              max: 40,
              colors: colors,
              onChanged: onCardBlurChanged,
            ),
            _SettingsGlassSlider(
              label: language.t('settings_card_opacity'),
              value: localCardOpacity,
              min: 0.05,
              max: 1.0,
              isPercent: true,
              colors: colors,
              onChanged: onCardOpacityChanged,
            ),
            const SizedBox(height: 6),
            Divider(color: colors.subCardBorder, height: 1),
            const SizedBox(height: 6),
            _SettingsGlassSlider(
              label: language.t('settings_dialog_blur'),
              value: localDialogBlur,
              min: 0,
              max: 40,
              colors: colors,
              onChanged: onDialogBlurChanged,
            ),
            _SettingsGlassSlider(
              label: language.t('settings_dialog_opacity'),
              value: localDialogOpacity,
              min: 0.1,
              max: 1.0,
              isPercent: true,
              colors: colors,
              onChanged: onDialogOpacityChanged,
            ),
            const SizedBox(height: 6),
            Divider(color: colors.subCardBorder, height: 1),
            const SizedBox(height: 6),
            _SettingsGlassSlider(
              label: language.t('settings_dropdown_blur'),
              value: localDropdownBlur,
              min: 0,
              max: 40,
              colors: colors,
              onChanged: onDropdownBlurChanged,
            ),
            _SettingsGlassSlider(
              label: language.t('settings_dropdown_opacity'),
              value: localDropdownOpacity,
              min: 0.1,
              max: 1.0,
              isPercent: true,
              colors: colors,
              onChanged: onDropdownOpacityChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGlassSlider extends StatelessWidget {
  const _SettingsGlassSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.isPercent = false,
    required this.colors,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final bool isPercent;
  final AppColors colors;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final display = isPercent
        ? '${(value * 100).round()}%'
        : '${value.toStringAsFixed(0)}px';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                display,
                style: TextStyle(
                  color: colors.accentCyan,
                  fontSize: 11,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              activeTrackColor: colors.accentColor,
              inactiveTrackColor: colors.subCardBorder,
              thumbColor: colors.accentCyan,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: isPercent ? 19 : 40,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsOtaUpdateTab extends StatefulWidget {
  const _SettingsOtaUpdateTab({
    required this.colors,
    required this.theme,
    required this.language,
    required this.appVersion,
    this.onUpdateFound,
  });

  final AppColors colors;
  final ThemeProvider theme;
  final LanguageProvider language;
  final String appVersion;
  final ValueChanged<UpdatePackageInfo?>? onUpdateFound;

  @override
  State<_SettingsOtaUpdateTab> createState() => _SettingsOtaUpdateTabState();
}

class _SettingsOtaUpdateTabState extends State<_SettingsOtaUpdateTab> {
  final _serverPathController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _checkInterval = 'daily';
  DateTime? _lastCheckTime;
  bool _obscurePassword = true;
  bool _isLoading = true;
  bool _isTestingConnection = false;
  bool? _connectionSuccess;
  String? _connectionMessage;
  bool _isCheckingUpdates = false;
  UpdateCheckResult? _checkResult;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _serverPathController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final config = await OtaUpdateService().getConfig();
    if (mounted) {
      setState(() {
        _serverPathController.text = config.serverPath;
        _usernameController.text = config.username;
        _checkInterval = config.checkInterval;
        _lastCheckTime = config.lastCheckTime;
        _isLoading = false;
      });
    }
  }

  Future<bool> _saveConfig({bool notify = true}) async {
    setState(() => _isSaving = true);
    final config = OtaUpdateConfig(
      serverPath: _serverPathController.text.trim(),
      username: _usernameController.text.trim(),
      checkInterval: _checkInterval,
      lastCheckTime: _lastCheckTime,
    );
    final password = _passwordController.text;
    try {
      await OtaUpdateService().saveConfig(config);
      if (password.isNotEmpty) {
        await OtaUpdateService().saveSmbCredential(
          serverPath: config.serverPath,
          username: config.username,
          password: password,
        );
        if (mounted) _passwordController.clear();
      }
      if (mounted && notify) {
        showAppToast(
          context,
          message: widget.language.t('action_save'),
          colors: widget.colors,
          icon: Icons.check_circle_rounded,
        );
      }
      return true;
    } catch (error) {
      if (mounted) {
        showAppToast(
          context,
          message: error.toString(),
          colors: widget.colors,
          icon: Icons.error_outline_rounded,
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionSuccess = null;
      _connectionMessage = null;
    });

    try {
      if (!await _saveConfig(notify: false)) {
        if (mounted) setState(() => _isTestingConnection = false);
        return;
      }
      final success = await OtaUpdateService().connectSmbShare(
        path: _serverPathController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
          _connectionSuccess = success;
          _connectionMessage = success
              ? widget.language.t('ota_connection_success')
              : widget.language.t('ota_connection_failed', [
                  'Truy cập thất bại / Access denied',
                ]);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
          _connectionSuccess = false;
          _connectionMessage = widget.language.t('ota_connection_failed', [
            e.toString(),
          ]);
        });
      }
    }
  }

  Future<void> _checkUpdatesNow() async {
    setState(() {
      _isCheckingUpdates = true;
      _checkResult = null;
    });

    if (!await _saveConfig(notify: false)) {
      if (mounted) setState(() => _isCheckingUpdates = false);
      return;
    }
    final path = _serverPathController.text.trim();

    try {
      final result = await OtaUpdateService().checkForUpdates(
        overrideServerPath: path,
        isManual: true,
      );
      if (mounted) {
        setState(() {
          _isCheckingUpdates = false;
          _checkResult = result;
          _lastCheckTime = DateTime.now();
        });
        if (result.hasUpdate && result.packageInfo != null) {
          widget.onUpdateFound?.call(result.packageInfo);
          showGlassUpdateDialog(
            context: context,
            packageInfo: result.packageInfo!,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingUpdates = false;
          _checkResult = UpdateCheckResult(
            hasUpdate: false,
            currentVersion: widget.appVersion,
            isConnectionSuccess: false,
            errorMessage: e.toString(),
          );
        });
      }
    }
  }

  void _openConfigFolder() {
    final file = OtaUpdateService().getConfigFile();
    try {
      if (Platform.isWindows) {
        if (file.existsSync()) {
          Process.run('explorer.exe', ['/select,', file.path]);
        } else {
          Process.run('explorer.exe', [file.parent.path]);
        }
      }
    } catch (e) {
      debugPrint('Could not open config folder: $e');
    }
  }

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    return '$h:$m $d/$mo/$y';
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final language = widget.language;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final intervalItems = [
      GlassDropdownItem<String>(
        value: 'daily',
        label: language.t('interval_daily'),
        icon: Icons.calendar_today_rounded,
      ),
      GlassDropdownItem<String>(
        value: 'weekly',
        label: language.t('interval_weekly'),
        icon: Icons.view_week_rounded,
      ),
      GlassDropdownItem<String>(
        value: 'monthly',
        label: language.t('interval_monthly'),
        icon: Icons.date_range_rounded,
      ),
      GlassDropdownItem<String>(
        value: 'off',
        label: language.t('interval_off'),
        icon: Icons.power_settings_new_rounded,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Version Status Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.subCardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colors.accentCyan.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.accentColor, colors.accentCyan],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primaryGlow.withValues(alpha: 0.25),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.system_update_alt_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${language.t('ota_current_version')} v${widget.appVersion}',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _lastCheckTime != null
                                ? '${language.t('ota_last_checked')} ${_formatDateTime(_lastCheckTime!)}'
                                : language.t('ota_never_checked'),
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 11,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                        ],
                      ),
                    ),
                    GlowingActionButton(
                      height: 34,
                      colors: colors,
                      icon: _isCheckingUpdates
                          ? Icons.sync_rounded
                          : Icons.refresh_rounded,
                      label: _isCheckingUpdates
                          ? language.t('ota_checking')
                          : language.t('ota_check_now'),
                      onPressed: _isCheckingUpdates ? null : _checkUpdatesNow,
                    ),
                  ],
                ),
                if (_checkResult != null) ...[
                  const SizedBox(height: 12),
                  if (_checkResult!.hasUpdate &&
                      _checkResult!.packageInfo != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colors.accentEmerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colors.accentEmerald.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: colors.accentEmerald,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              language.t('ota_update_available', [
                                _checkResult!
                                    .packageInfo!
                                    .version
                                    .displayVersion,
                              ]),
                              style: TextStyle(
                                color: colors.accentEmerald,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              showGlassUpdateDialog(
                                context: context,
                                packageInfo: _checkResult!.packageInfo!,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: colors.accentEmerald,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                language.t('ota_update_now'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_checkResult!.isConnectionSuccess)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.accentCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colors.accentCyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: colors.accentCyan,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              language.t('ota_no_updates', [
                                'v${widget.appVersion}',
                              ]),
                              style: TextStyle(
                                color: colors.accentCyan,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.accentAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colors.accentAmber.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: colors.accentAmber,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _checkResult!.errorMessage ?? 'Check failed',
                              style: TextStyle(
                                color: colors.accentAmber,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Server & Schedule Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.subCardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.subCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  language.t('ota_title'),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  language.t('ota_desc'),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInputField(
                  label: language.t('ota_server_path'),
                  controller: _serverPathController,
                  hint: language.t('ota_server_path_hint'),
                  colors: colors,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            language.t('ota_check_interval'),
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          GlassDropdown<String>(
                            items: intervalItems,
                            value: _checkInterval,
                            onChanged: (val) async {
                              setState(() => _checkInterval = val);
                              await _saveConfig(notify: false);
                            },
                            colors: colors,
                            enableSearch: false,
                            borderRadius: 9,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: _openConfigFolder,
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: colors.cardBg.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: colors.subCardBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder_open_rounded,
                              size: 15,
                              color: colors.accentCyan,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              language.t('ota_open_config_folder'),
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Credentials & Connection Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.subCardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.subCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  language.t('ota_auth_title'),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        label: language.t('ota_username'),
                        controller: _usernameController,
                        hint: 'user',
                        colors: colors,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        label: language.t('ota_password'),
                        controller: _passwordController,
                        hint: '••••••',
                        obscureText: _obscurePassword,
                        colors: colors,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 16,
                            color: colors.textMuted,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    InkWell(
                      onTap: _isTestingConnection ? null : _testConnection,
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accentCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: colors.accentCyan.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isTestingConnection)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              Icon(
                                Icons.wifi_find_rounded,
                                size: 15,
                                color: colors.accentCyan,
                              ),
                            const SizedBox(width: 6),
                            Text(
                              _isTestingConnection
                                  ? language.t('ota_testing_connection')
                                  : language.t('ota_test_connection'),
                              style: TextStyle(
                                color: colors.accentCyan,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: _isSaving ? null : () => _saveConfig(notify: true),
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colors.subCardBg,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: colors.subCardBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.save_rounded,
                              size: 15,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              language.t('action_save'),
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_connectionSuccess != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          (_connectionSuccess!
                                  ? colors.accentEmerald
                                  : colors.accentAmber)
                              .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            (_connectionSuccess!
                                    ? colors.accentEmerald
                                    : colors.accentAmber)
                                .withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _connectionSuccess!
                              ? Icons.check_circle_rounded
                              : Icons.error_outline_rounded,
                          size: 15,
                          color: _connectionSuccess!
                              ? colors.accentEmerald
                              : colors.accentAmber,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _connectionMessage ?? '',
                            style: TextStyle(
                              color: _connectionSuccess!
                                  ? colors.accentEmerald
                                  : colors.accentAmber,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required AppColors colors,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: colors.cardBg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: colors.subCardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontFamily: 'JetBrains Mono',
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ),
              ?suffixIcon,
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsUserGuideTab extends StatelessWidget {
  const _SettingsUserGuideTab({required this.colors, required this.language});

  final AppColors colors;
  final LanguageProvider language;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGuideCard(
            icon: Icons.keyboard_rounded,
            accent: colors.accentCyan,
            title: language.t('guide_shortcuts_title'),
            desc: language.t('guide_shortcuts_desc'),
          ),
          const SizedBox(height: 10),
          _buildGuideCard(
            icon: Icons.terminal_rounded,
            accent: colors.accentEmerald,
            title: language.t('guide_terminal_title'),
            desc: language.t('guide_terminal_desc'),
          ),
          const SizedBox(height: 10),
          _buildGuideCard(
            icon: Icons.touch_app_rounded,
            accent: colors.accentAmber,
            title: language.t('guide_topbar_title'),
            desc: language.t('guide_topbar_desc'),
          ),
          const SizedBox(height: 10),
          _buildGuideCard(
            icon: Icons.speed_rounded,
            accent: colors.accentEmerald,
            title: language.t('guide_tier_title'),
            desc: language.t('guide_tier_desc'),
          ),
          const SizedBox(height: 10),
          _buildGuideCard(
            icon: Icons.swap_vert_rounded,
            accent: colors.accentPurple,
            title: language.t('guide_scroll_title'),
            desc: language.t('guide_scroll_desc'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard({
    required IconData icon,
    required Color accent,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.subCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.subCardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    height: 1.45,
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

class _SettingsAboutTab extends StatelessWidget {
  const _SettingsAboutTab({
    required this.colors,
    required this.theme,
    required this.language,
    required this.appVersion,
    required this.isDebug,
  });

  final AppColors colors;
  final ThemeProvider theme;
  final LanguageProvider language;
  final String appVersion;
  final bool isDebug;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.subCardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colors.accentColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.accentColor, colors.accentCyan],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primaryGlow.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'JA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            language.t('about_app_name'),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          PillBadge(
                            label: isDebug ? 'DEBUG' : 'RELEASE',
                            color: isDebug
                                ? colors.accentAmber
                                : colors.accentEmerald,
                            bg:
                                (isDebug
                                        ? colors.accentAmber
                                        : colors.accentEmerald)
                                    .withValues(alpha: 0.12),
                            border:
                                (isDebug
                                        ? colors.accentAmber
                                        : colors.accentEmerald)
                                    .withValues(alpha: 0.3),
                            fontSize: 9.5,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'v$appVersion • Release 2026-09-21',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 11,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            language.t('about_app_desc'),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          // System Runtime Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.subCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.subCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  language.t('about_sys_title'),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                _buildInfoRow(
                  'Hệ điều hành / OS',
                  Platform.operatingSystemVersion,
                  colors,
                ),
                _buildInfoRow('Số nhân CPU', '${theme.cpuCores} Cores', colors),
                _buildInfoRow(
                  'Điểm phần cứng',
                  '${theme.hardwareScore}/100',
                  colors,
                ),
                _buildInfoRow(
                  'Cấu hình đồ họa',
                  '${theme.effectiveTier.label} (${theme.effectiveTier.desc})',
                  colors,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Developer & License Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.subCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.subCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  language.t('about_dev_title'),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                _buildInfoRow(
                  'Tác giả / Author',
                  'John Alaa / JA Tech',
                  colors,
                ),
                _buildInfoRow(
                  'Bản quyền / License',
                  'MIT License (Open Source)',
                  colors,
                ),
                _buildInfoRow(
                  'Bộ quy chuẩn',
                  'flutter-app-blueprint v1.0',
                  colors,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Links Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.subCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.subCardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        _openExternalUrl('https://jatechvn.github.io/'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colors.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colors.accentColor.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.public_rounded,
                            size: 15,
                            color: colors.accentColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Website',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _openExternalUrl(
                      'https://github.com/jatechvn/JA_Mini_Showcase',
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colors.accentCyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colors.accentCyan.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.code_rounded,
                            size: 15,
                            color: colors.accentCyan,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'GitHub',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: colors.textMuted, fontSize: 11),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'JetBrains Mono',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openExternalUrl(String url) async {
  try {
    if (Platform.isWindows) {
      await Process.start('explorer.exe', [url]);
    } else if (Platform.isMacOS) {
      await Process.start('open', [url]);
    } else if (Platform.isLinux) {
      await Process.start('xdg-open', [url]);
    }
  } catch (error) {
    debugPrint('Could not open external URL: $error');
  }
}
