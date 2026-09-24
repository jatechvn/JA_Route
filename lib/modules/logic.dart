// lib/modules/logic.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'logger_config.dart';
import 'localization.dart';
import 'native_bridge.dart';
import 'utils.dart';

final _logger = Logger('RouteFixerLogic');

class AppConfig {
  String internetGateway;
  String backupGateway;
  String lanGateway;
  String lanNetwork;
  String lanMask;
  String logFilePath;
  List<String> customLanRoutes;
  List<String> customInternetRoutes;
  String themeMode;
  String language;
  String activeProfile;
  Map<String, Map<String, dynamic>> profiles;
  bool autoFixEnabled;

  AppConfig({
    required this.internetGateway,
    required this.backupGateway,
    required this.lanGateway,
    required this.lanNetwork,
    required this.lanMask,
    required this.logFilePath,
    required this.customLanRoutes,
    required this.customInternetRoutes,
    required this.themeMode,
    required this.language,
    required this.activeProfile,
    required this.profiles,
    required this.autoFixEnabled,
  });

  static String detectSystemLanguage() {
    try {
      final locale = Platform.localeName.toLowerCase();
      if (locale.startsWith('vi')) return 'vi';
      if (locale.startsWith('zh')) return 'zh';
      if (locale.startsWith('en')) return 'en';
    } catch (_) {}
    return 'en';
  }

  factory AppConfig.defaultConfig() {
    String logPath;
    if (Platform.isWindows) {
      logPath = '${Directory.current.path}\\logs\\ja_route.log';
    } else {
      logPath = '${Directory.current.path}/logs/ja_route.log';
    }

    final defaultProfile = {
      'internetGateway': '192.168.100.1',
      'backupGateway': '192.168.1.1',
      'lanGateway': '172.21.168.1',
      'lanNetwork': '10.0.0.0',
      'lanMask': '255.0.0.0',
      'customLanRoutes': ['10.0.0.0/255.0.0.0'],
      'customInternetRoutes': ['10.191.24.194/255.255.255.255'],
    };

    return AppConfig(
      internetGateway: '192.168.100.1',
      backupGateway: '192.168.1.1',
      lanGateway: '172.21.168.1',
      lanNetwork: '10.0.0.0',
      lanMask: '255.0.0.0',
      logFilePath: logPath,
      customLanRoutes: ['10.0.0.0/255.0.0.0'],
      customInternetRoutes: ['10.191.24.194/255.255.255.255'],
      themeMode: 'system',
      language: detectSystemLanguage(),
      activeProfile: 'Mặc định',
      profiles: {'Mặc định': defaultProfile},
      autoFixEnabled: false,
    );
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final defaults = AppConfig.defaultConfig();

    String readString(
      Map<String, dynamic> source,
      String key,
      String fallback,
    ) {
      final value = source[key];
      return value is String ? value.trim() : fallback;
    }

    List<String> readRoutes(
      Map<String, dynamic> source,
      String key,
      List<String> fallback,
    ) {
      final value = source[key];
      if (value is! List) return List<String>.from(fallback);

      return value
          .whereType<String>()
          .map(normalizeRouteSpec)
          .whereType<String>()
          .toList();
    }

    Map<String, dynamic> sanitizeProfile(Object? value) {
      final source = <String, dynamic>{};
      if (value is Map) {
        value.forEach((key, val) {
          if (key is String) {
            source[key] = val;
          }
        });
      }

      return {
        'internetGateway': readString(
          source,
          'internetGateway',
          defaults.internetGateway,
        ),
        'backupGateway': readString(
          source,
          'backupGateway',
          defaults.backupGateway,
        ),
        'lanGateway': readString(source, 'lanGateway', defaults.lanGateway),
        'lanNetwork': readString(source, 'lanNetwork', defaults.lanNetwork),
        'lanMask': readString(source, 'lanMask', defaults.lanMask),
        'customLanRoutes': readRoutes(
          source,
          'customLanRoutes',
          defaults.customLanRoutes,
        ),
        'customInternetRoutes': readRoutes(
          source,
          'customInternetRoutes',
          defaults.customInternetRoutes,
        ),
      };
    }

    final requestedActiveProfile = readString(
      json,
      'activeProfile',
      defaults.activeProfile,
    );
    final autoFix = json['autoFixEnabled'] is bool
        ? json['autoFixEnabled'] as bool
        : defaults.autoFixEnabled;

    final Map<String, Map<String, dynamic>> profs = {};
    final rawProfiles = json['profiles'];
    if (rawProfiles is Map) {
      rawProfiles.forEach((key, val) {
        if (key is String && key.trim().isNotEmpty) {
          profs[key.trim()] = sanitizeProfile(val);
        }
      });
    }

    if (profs.isEmpty) {
      profs[defaults.activeProfile] = sanitizeProfile(json);
    }

    final activeProfile = profs.containsKey(requestedActiveProfile)
        ? requestedActiveProfile
        : (profs.containsKey(defaults.activeProfile)
              ? defaults.activeProfile
              : profs.keys.first);
    final activeConfig = profs[activeProfile]!;

    final rawThemeMode = readString(json, 'themeMode', defaults.themeMode);
    final themeMode = {'system', 'light', 'dark'}.contains(rawThemeMode)
        ? rawThemeMode
        : defaults.themeMode;

    final rawLanguage = readString(json, 'language', detectSystemLanguage());
    final language = {'vi', 'en', 'zh'}.contains(rawLanguage)
        ? rawLanguage
        : detectSystemLanguage();

    return AppConfig(
      internetGateway: readString(
        activeConfig,
        'internetGateway',
        defaults.internetGateway,
      ),
      backupGateway: readString(
        activeConfig,
        'backupGateway',
        defaults.backupGateway,
      ),
      lanGateway: readString(activeConfig, 'lanGateway', defaults.lanGateway),
      lanNetwork: readString(activeConfig, 'lanNetwork', defaults.lanNetwork),
      lanMask: readString(activeConfig, 'lanMask', defaults.lanMask),
      logFilePath: readString(json, 'logFilePath', defaults.logFilePath),
      customLanRoutes: List<String>.from(
        activeConfig['customLanRoutes'] ?? defaults.customLanRoutes,
      ),
      customInternetRoutes: List<String>.from(
        activeConfig['customInternetRoutes'] ?? defaults.customInternetRoutes,
      ),
      themeMode: themeMode,
      language: language,
      activeProfile: activeProfile,
      profiles: profs,
      autoFixEnabled: autoFix,
    );
  }

  Map<String, dynamic> toJson() => {
    'internetGateway': internetGateway,
    'backupGateway': backupGateway,
    'lanGateway': lanGateway,
    'lanNetwork': lanNetwork,
    'lanMask': lanMask,
    'logFilePath': logFilePath,
    'customLanRoutes': customLanRoutes,
    'customInternetRoutes': customInternetRoutes,
    'themeMode': themeMode,
    'language': language,
    'activeProfile': activeProfile,
    'profiles': profiles,
    'autoFixEnabled': autoFixEnabled,
  };

  AppConfig copyWith({
    String? internetGateway,
    String? backupGateway,
    String? lanGateway,
    String? lanNetwork,
    String? lanMask,
    String? logFilePath,
    List<String>? customLanRoutes,
    List<String>? customInternetRoutes,
    String? themeMode,
    String? language,
    String? activeProfile,
    Map<String, Map<String, dynamic>>? profiles,
    bool? autoFixEnabled,
  }) {
    return AppConfig(
      internetGateway: internetGateway ?? this.internetGateway,
      backupGateway: backupGateway ?? this.backupGateway,
      lanGateway: lanGateway ?? this.lanGateway,
      lanNetwork: lanNetwork ?? this.lanNetwork,
      lanMask: lanMask ?? this.lanMask,
      logFilePath: logFilePath ?? this.logFilePath,
      customLanRoutes: customLanRoutes ?? this.customLanRoutes,
      customInternetRoutes: customInternetRoutes ?? this.customInternetRoutes,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      activeProfile: activeProfile ?? this.activeProfile,
      profiles: profiles ?? this.profiles,
      autoFixEnabled: autoFixEnabled ?? this.autoFixEnabled,
    );
  }

  String toIniString() {
    final lanSection = StringBuffer('[CustomLanRoutes]\n');
    for (int i = 0; i < customLanRoutes.length; i++) {
      lanSection.writeln('route$i = ${customLanRoutes[i]}');
    }
    final internetSection = StringBuffer('[CustomInternetRoutes]\n');
    for (int i = 0; i < customInternetRoutes.length; i++) {
      internetSection.writeln('route$i = ${customInternetRoutes[i]}');
    }

    return '[Gateways]\n'
        'internetGateway = $internetGateway\n'
        'backupGateway = $backupGateway\n'
        'lanGateway = $lanGateway\n\n'
        '[Subnets]\n'
        'lanNetwork = $lanNetwork\n'
        'lanMask = $lanMask\n\n'
        '${lanSection.toString()}\n'
        '${internetSection.toString()}\n'
        '[Logging]\n'
        'logFilePath = $logFilePath\n\n'
        '[Preferences]\n'
        'themeMode = $themeMode\n'
        'language = $language\n';
  }
}

enum StepStatus { idle, running, success, warning, error }

class FixStep {
  final String id;
  final String name;
  StepStatus status;
  String message;

  FixStep({
    required this.id,
    required this.name,
    this.status = StepStatus.idle,
    this.message = '',
  });
}

class RouteFixerLogic extends ChangeNotifier {
  late AppConfig config;
  bool isRunning = false;
  bool isAdmin = false;

  final List<FixStep> steps = [
    FixStep(id: 'admin', name: 'Kiem tra quyen Administrator'),
    FixStep(
      id: 'lan_adapter',
      name: 'Bat IgnoreDefaultRoutes tren LAN card (172.21.x)',
    ),
    FixStep(
      id: 'metrics',
      name: 'Dat Metric uu tien cho Network/Backup (192.168.x)',
    ),
    FixStep(id: 'flush', name: 'Lam moi ARP & DNS Cache'),
    FixStep(id: 'clean', name: 'Don dep cac Route cu/sai'),
    FixStep(id: 'persistent_routes', name: 'Inject cac Route moi vinh vien'),
    FixStep(
      id: 'clean_lan_gw',
      name: 'Chan Default Route qua LAN gateway lan cuoi',
    ),
    FixStep(id: 'verify', name: 'Kiem tra lai bang Route'),
    FixStep(id: 'ping_test', name: 'Kiem tra Ping Internet (1.1.1.1)'),
  ];

  RouteFixerLogic() {
    config = AppConfig.defaultConfig();
    _loadConfig();
    _checkAdminStatus();
    scanBackups();
    _updateAutoFixTimer();
  }

  Future<void> _checkAdminStatus() async {
    isAdmin = await checkIsAdmin();
    notifyListeners();
  }

  List<String> availableBackups = [];

  void scanBackups() {
    availableBackups.clear();
    try {
      final dir = Directory('backups');
      if (dir.existsSync()) {
        final files = dir.listSync();
        for (final file in files) {
          if (file is File) {
            final name = file.path.split(Platform.pathSeparator).last;
            // Match backup_yyyyMMdd_HHmmss.json
            if (name.startsWith('backup_') &&
                name.endsWith('.json') &&
                !name.contains('_config')) {
              final parts = name.split('_');
              if (parts.length == 3) {
                final timestamp = '${parts[1]}_${parts[2].split('.').first}';
                if (!availableBackups.contains(timestamp)) {
                  availableBackups.add(timestamp);
                }
              }
            }
          }
        }
      }
      // Sort descending (newest first)
      availableBackups.sort((a, b) => b.compareTo(a));
    } catch (e) {
      _logger.warning('Failed to scan backups: $e');
    }
  }

  bool get hasBackup => availableBackups.isNotEmpty;

  DateTime? getBackupDate(String timestamp) {
    final file = File('backups/backup_$timestamp.json');
    if (file.existsSync()) {
      try {
        return file.lastModifiedSync();
      } catch (_) {}
    }
    return null;
  }

  Future<bool> runBackup() async {
    final engine = nativeBridge.engine;
    if (engine == null) return false;
    final loc = AppLocalizations(config.language);
    _logger.info(loc.get('log_backup_start'));

    try {
      final dir = Directory('backups');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final now = DateTime.now();
      String pad(int n) => n.toString().padLeft(2, '0');
      final timestamp =
          '${now.year}${pad(now.month)}${pad(now.day)}_${pad(now.hour)}${pad(now.minute)}${pad(now.second)}';

      final regPath = 'backups/backup_$timestamp.reg';
      final jsonPath = 'backups/backup_$timestamp.json';

      final ok = await engine.backupSettings(regPath, jsonPath);
      if (ok) {
        // Also backup the current active config.json for restoration convenience
        final configBackup = File('backups/backup_${timestamp}_config.json');
        if (File('config.json').existsSync()) {
          File('config.json').copySync(configBackup.path);
        }
        _logger.info(
          loc.getWithParams('log_backup_ok', {'timestamp': timestamp}),
        );
      } else {
        _logger.severe(loc.get('log_backup_fail'));
      }
      scanBackups();
      notifyListeners();
      return ok;
    } catch (e) {
      _logger.severe('Failed to execute backup sequence: $e');
      return false;
    }
  }

  Future<bool> runRestore(String timestamp) async {
    final engine = nativeBridge.engine;
    if (engine == null) return false;
    final loc = AppLocalizations(config.language);
    _logger.info(
      loc.getWithParams('log_restore_start', {'timestamp': timestamp}),
    );

    final regPath = 'backups/backup_$timestamp.reg';
    final jsonPath = 'backups/backup_$timestamp.json';
    final configBackupPath = 'backups/backup_${timestamp}_config.json';

    final ok = await engine.restoreSettings(regPath, jsonPath);
    if (ok) {
      // If config backup exists, restore it as active config.json
      try {
        final configBackup = File(configBackupPath);
        if (configBackup.existsSync()) {
          configBackup.copySync('config.json');
          _loadConfig(); // Reload restored configuration into active logic
          _logger.info(loc.get('log_restore_config_ok'));
        }
      } catch (e) {
        _logger.warning('Failed to restore config file from backup: $e');
      }
      _logger.info(loc.get('log_restore_ok'));
    } else {
      _logger.severe(loc.get('log_restore_fail'));
    }
    notifyListeners();
    return ok;
  }

  /// Imports a configuration from a JSON file path and saves it as active
  Future<bool> importConfigurationFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return false;
      final content = file.readAsStringSync();
      final json = jsonDecode(content);
      final newConfig = AppConfig.fromJson(json);
      saveConfig(newConfig);
      final loc = AppLocalizations(config.language);
      _logger.info(loc.getWithParams('log_import_ok', {'path': filePath}));

      // Update the controllers if they are mounted in UI, done via notifier
      notifyListeners();
      return true;
    } catch (e) {
      _logger.severe('Failed to import config file $filePath: $e');
      return false;
    }
  }

  /// Exports the current configuration to a JSON file path
  Future<String?> exportConfiguration({String? customPath}) async {
    try {
      final now = DateTime.now();
      String pad(int n) => n.toString().padLeft(2, '0');
      final timestamp =
          '${now.year}${pad(now.month)}${pad(now.day)}_${pad(now.hour)}${pad(now.minute)}${pad(now.second)}';

      String targetPath =
          customPath ??
          '${Directory.current.path}${Platform.pathSeparator}ja_route_config_$timestamp.json';

      final file = File(targetPath);
      const encoder = JsonEncoder.withIndent('  ');
      file.writeAsStringSync(encoder.convert(config.toJson()));

      final loc = AppLocalizations(config.language);
      _logger.info(loc.getWithParams('log_export_ok', {'path': targetPath}));
      return targetPath;
    } catch (e) {
      _logger.severe('Failed to export configuration: $e');
      return null;
    }
  }

  /// Opens a URL in the user's default browser
  Future<void> openUrl(String url) async {
    final engine = nativeBridge.engine;
    if (engine != null) {
      await engine.openUrl(url);
    }
  }

  void _loadConfig() {
    try {
      final file = File('config.json');
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final json = jsonDecode(content);
        config = AppConfig.fromJson(json);
        final loc = AppLocalizations(config.language);
        _logger.info(loc.get('log_load_config_ok'));

        // Correct logFilePath if it points to non-existent D: drive
        if (Platform.isWindows &&
            config.logFilePath.toLowerCase().startsWith('d:\\') &&
            !Directory('D:\\').existsSync()) {
          final fallbackPath =
              '${Directory.current.path}\\logs\\fix_dual_network_full_v6_dhcp_proof.log';
          _logger.warning(
            'D: drive not found. Overriding log file path to: $fallbackPath',
          );
          config.logFilePath = fallbackPath;
          saveConfig(config);
        }
      } else {
        config = AppConfig.defaultConfig();
        final loc = AppLocalizations(config.language);
        _logger.info(loc.get('log_load_config_default'));
        saveConfig(config);
      }
    } catch (e) {
      _logger.severe('Error loading config.json: $e');
    }
  }

  void saveConfig(AppConfig newConfig) {
    config = newConfig;

    // Sync current active settings to the active profile in the profiles map
    config.profiles[config.activeProfile] = {
      'internetGateway': config.internetGateway,
      'backupGateway': config.backupGateway,
      'lanGateway': config.lanGateway,
      'lanNetwork': config.lanNetwork,
      'lanMask': config.lanMask,
      'customLanRoutes': config.customLanRoutes,
      'customInternetRoutes': config.customInternetRoutes,
    };

    try {
      // Save JSON
      final fileJson = File('config.json');
      const encoder = JsonEncoder.withIndent('  ');
      fileJson.writeAsStringSync(encoder.convert(config.toJson()));

      // Save INI
      final fileIni = File('config.ini');
      fileIni.writeAsStringSync(config.toIniString());

      final loc = AppLocalizations(config.language);
      _logger.info(loc.get('log_save_config_ok'));

      // Update logger file path dynamically
      LoggerConfig.updateLogFile(config.logFilePath);
      _updateAutoFixTimer();
      notifyListeners();
    } catch (e) {
      _logger.severe('Failed to save configuration files: $e');
    }
  }

  void resetSteps() {
    for (var step in steps) {
      step.status = StepStatus.idle;
      step.message = '';
    }
    notifyListeners();
  }

  String _getPrefixPattern(String ip) {
    if (ip.isEmpty) return '';
    final parts = ip.split('.');
    if (parts.length >= 3) {
      if (parts[0] == '172') {
        return '${parts[0]}.${parts[1]}.*';
      }
      return '${parts[0]}.${parts[1]}.${parts[2]}.*';
    }
    return ip;
  }

  Iterable<RouteSpec> _parseConfiguredRoutes(
    List<String> routes,
    String routeKind,
  ) sync* {
    for (final routeStr in routes) {
      final spec = parseRouteSpec(routeStr);
      if (spec == null) {
        _logger.warning('Skipping invalid $routeKind route: $routeStr');
        continue;
      }
      yield spec;
    }
  }

  String? _validateRoutingConfig() {
    if (!isValidIPv4(config.internetGateway)) {
      return 'Invalid Internet gateway IPv4: ${config.internetGateway}';
    }
    if (config.backupGateway.isNotEmpty && !isValidIPv4(config.backupGateway)) {
      return 'Invalid backup gateway IPv4: ${config.backupGateway}';
    }
    if (!isValidIPv4(config.lanGateway)) {
      return 'Invalid LAN gateway IPv4: ${config.lanGateway}';
    }
    if (!isValidIPv4(config.lanNetwork)) {
      return 'Invalid LAN network IPv4: ${config.lanNetwork}';
    }
    if (!isValidSubnetMask(config.lanMask)) {
      return 'Invalid LAN subnet mask: ${config.lanMask}';
    }
    for (final route in [
      ...config.customLanRoutes,
      ...config.customInternetRoutes,
    ]) {
      if (!isValidRouteSpec(route)) {
        return 'Invalid custom route: $route';
      }
    }
    return null;
  }

  Future<void> runOptimization() async {
    if (isRunning) return;
    isRunning = true;
    resetSteps();

    final loc = AppLocalizations(config.language);
    _logger.info(loc.get('log_opt_start'));

    final engine = nativeBridge.engine;
    if (engine == null) {
      _logger.severe(loc.get('log_engine_missing'));
      isRunning = false;
      notifyListeners();
      return;
    }

    final configError = _validateRoutingConfig();
    if (configError != null) {
      final adminStep = steps.firstWhere((s) => s.id == 'admin');
      adminStep.status = StepStatus.error;
      adminStep.message = configError;
      _logger.severe(configError);
      isRunning = false;
      notifyListeners();
      return;
    }

    bool backupSuccess = false;

    try {
      // STEP 1: Check Administrator
      await _runStep('admin', () async {
        final hasAdmin = await checkIsAdmin();
        isAdmin = hasAdmin;
        if (!hasAdmin) {
          throw loc.get('log_admin_required');
        }
        return loc.get('log_admin_ok');
      });

      // Silently backup settings for auto-rollback
      try {
        final dir = Directory('backups');
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        backupSuccess = await engine.backupSettings(
          'backups/backup_auto_rollback.reg',
          'backups/backup_auto_rollback.json',
        );
        if (backupSuccess) {
          if (File('config.json').existsSync()) {
            File(
              'config.json',
            ).copySync('backups/backup_auto_rollback_config.json');
          }
          _logger.info('Auto-rollback backup created successfully.');
        } else {
          _logger.warning('Failed to create auto-rollback backup.');
        }
      } catch (e) {
        _logger.warning('Failed to prepare auto-rollback backup: $e');
      }

      // STEP 2: IgnoreDefaultRoutes on LAN adapter (dynamic)
      await _runStep('lan_adapter', () async {
        final pattern = _getPrefixPattern(config.lanGateway);
        final success = await engine.enableIgnoreDefaultRoutes(pattern, 80);
        if (!success) {
          throw Exception(
            loc.getWithParams('log_lan_adapter_warn', {'pattern': pattern}),
          );
        }
        return loc.getWithParams('log_lan_adapter_ok', {'pattern': pattern});
      });

      // STEP 3: Priority Metrics on Internet & Backup
      await _runStep('metrics', () async {
        final internetPattern = _getPrefixPattern(config.internetGateway);
        final backupPattern = _getPrefixPattern(config.backupGateway);

        bool internetSuccess = false;
        if (internetPattern.isNotEmpty) {
          internetSuccess = await engine.setInterfaceMetric(
            internetPattern,
            10,
          );
        }

        bool backupSuccessMetric = false;
        if (backupPattern.isNotEmpty) {
          backupSuccessMetric = await engine.setInterfaceMetric(
            backupPattern,
            25,
          );
        }

        if (!internetSuccess && !backupSuccessMetric) {
          throw Exception(
            loc.getWithParams('log_metrics_warn', {
              'ip1': internetPattern,
              'ip2': backupPattern,
            }),
          );
        }
        return loc.get('log_metrics_ok');
      });

      // STEP 4: Flush ARP/DNS Cache
      await _runStep('flush', () async {
        await engine.flushArpDns();
        return loc.get('log_flush_ok');
      });

      // STEP 5: Clean old/incorrect routes
      await _runStep('clean', () async {
        await engine.cleanOldRoutes(
          config.internetGateway,
          config.lanGateway,
          config.lanNetwork,
          config.lanMask,
        );

        // Clean custom LAN routes
        for (final route in _parseConfiguredRoutes(
          config.customLanRoutes,
          'LAN',
        )) {
          try {
            await engine.deleteRoute(
              route.destination,
              route.mask,
              config.lanGateway,
              persistent: true,
            );
            await engine.deleteRoute(
              route.destination,
              route.mask,
              config.lanGateway,
              persistent: false,
            );
          } catch (_) {}
        }

        // Clean custom Internet routes
        for (final route in _parseConfiguredRoutes(
          config.customInternetRoutes,
          'Internet',
        )) {
          try {
            await engine.deleteRoute(
              route.destination,
              route.mask,
              config.internetGateway,
              persistent: true,
            );
            await engine.deleteRoute(
              route.destination,
              route.mask,
              config.internetGateway,
              persistent: false,
            );
          } catch (_) {}
        }

        return loc.getWithParams('log_clean_ok', {
          'internetGw': config.internetGateway,
          'lanGw': config.lanGateway,
        });
      });

      // STEP 6: Inject persistent routes
      await _runStep('persistent_routes', () async {
        final gwOk = await engine.addRoute(
          '0.0.0.0',
          '0.0.0.0',
          config.internetGateway,
          5,
        );
        if (!gwOk) {
          _logger.warning(
            loc.getWithParams('log_persistent_warn', {
              'gw': config.internetGateway,
            }),
          );
        }

        // Inject custom LAN routes
        int lanSuccess = 0;
        for (final route in _parseConfiguredRoutes(
          config.customLanRoutes,
          'LAN',
        )) {
          try {
            final ok = await engine.addRoute(
              route.destination,
              route.mask,
              config.lanGateway,
              1,
            );
            if (ok) lanSuccess++;
          } catch (_) {}
        }

        // Inject custom Internet routes (high priority bypass)
        int internetSuccess = 0;
        for (final route in _parseConfiguredRoutes(
          config.customInternetRoutes,
          'Internet',
        )) {
          try {
            final ok = await engine.addRoute(
              route.destination,
              route.mask,
              config.internetGateway,
              2,
            );
            if (ok) internetSuccess++;
          } catch (_) {}
        }

        return loc.getWithParams('log_persistent_ok', {
          'internetGw': config.internetGateway,
          'lanGw': config.lanGateway,
          'lanCount': lanSuccess.toString(),
          'internetCount': internetSuccess.toString(),
        });
      });

      // STEP 7: Block default route via LAN GW (sanity check)
      await _runStep('clean_lan_gw', () async {
        await engine.deleteRoute(
          '0.0.0.0',
          '0.0.0.0',
          config.lanGateway,
          persistent: false,
        );
        await engine.deleteRoute(
          '0.0.0.0',
          '0.0.0.0',
          config.lanGateway,
          persistent: true,
        );
        return loc.getWithParams('log_clean_lan_gw_ok', {
          'gw': config.lanGateway,
        });
      });

      // STEP 8: Verify routing table
      await _runStep('verify', () async {
        final routes = await engine.getRoutingTable();
        final hasLanGwDefault = RegExp(
          r'0\.0\.0\.0\s+0\.0\.0\.0\s+' + RegExp.escape(config.lanGateway),
        ).hasMatch(routes);
        if (hasLanGwDefault) {
          throw Exception(
            loc.getWithParams('log_verify_warn', {'gw': config.lanGateway}),
          );
        }
        return loc.getWithParams('log_verify_ok', {'gw': config.lanGateway});
      });

      // STEP 9: Test internet ping
      await _runStep('ping_test', () async {
        final pingRes = await engine.runPing('1.1.1.1', count: 4);
        final success =
            pingRes.contains('Reply from') || pingRes.contains('bytes from');
        if (!success) {
          throw Exception(loc.get('log_ping_warn'));
        }
        return loc.getWithParams('log_ping_ok', {'res': pingRes});
      });
    } catch (e) {
      _logger.severe('Optimization failed: $e');
      if (backupSuccess) {
        _logger.warning(loc.get('log_rollback_start'));
        final ok = await engine.restoreSettings(
          'backups/backup_auto_rollback.reg',
          'backups/backup_auto_rollback.json',
        );
        if (ok) {
          try {
            final configBackup = File(
              'backups/backup_auto_rollback_config.json',
            );
            if (configBackup.existsSync()) {
              configBackup.copySync('config.json');
              _loadConfig();
            }
          } catch (ex) {
            _logger.warning(
              'Failed to restore config file during rollback: $ex',
            );
          }
          _logger.warning(loc.get('log_rollback_ok'));
        } else {
          _logger.severe(loc.get('log_rollback_fail'));
        }
      }
    }

    _logger.info(loc.get('log_opt_end'));
    isRunning = false;
    notifyListeners();
  }

  Future<bool> runRestoreSystemDefaults() async {
    final engine = nativeBridge.engine;
    if (engine == null) return false;
    final loc = AppLocalizations(config.language);
    _logger.info(
      '===== ${loc.get('config_restore_defaults').toUpperCase()} =====',
    );

    final ok = await engine.restoreSystemDefaults();
    if (ok) {
      // Also restore the default app configuration, preserving language & theme
      final defaultConfig = AppConfig.defaultConfig();
      final newConfig = defaultConfig.copyWith(
        themeMode: config.themeMode,
        language: config.language,
      );
      saveConfig(newConfig);
      _logger.info(
        '===== ${loc.get('config_dialog_restore_defaults_success').toUpperCase()} =====',
      );
    } else {
      _logger.severe(
        '===== ${loc.get('config_dialog_restore_defaults_fail').toUpperCase()} =====',
      );
    }
    notifyListeners();
    return ok;
  }

  Future<void> _runStep(String id, Future<String> Function() action) async {
    final step = steps.firstWhere((s) => s.id == id);
    step.status = StepStatus.running;
    notifyListeners();

    final loc = AppLocalizations(config.language);
    final stepName = loc.get('step_$id');

    try {
      final msg = await action();
      step.message = msg;
      if (msg.startsWith('WARN')) {
        step.status = StepStatus.warning;
        _logger.warning('[$stepName] $msg');
      } else {
        step.status = StepStatus.success;
        _logger.info('[$stepName] $msg');
      }
    } catch (e) {
      step.status = StepStatus.error;
      step.message = e.toString();
      _logger.severe('[$stepName] error: $e');
      rethrow;
    }
    notifyListeners();
  }

  // --- Profile Manager & Auto-Healing Background Timer ---
  Timer? _autoFixTimer;

  void _updateAutoFixTimer() {
    _autoFixTimer?.cancel();
    if (config.autoFixEnabled) {
      _logger.info(
        'Auto-Healing daemon activated. Monitoring routing table every 30 seconds.',
      );
      _autoFixTimer = Timer.periodic(const Duration(seconds: 30), (
        timer,
      ) async {
        if (isRunning) return;

        final engine = nativeBridge.engine;
        if (engine == null) return;

        try {
          final routes = await engine.getRoutingTable();
          final hasLanGwDefault = RegExp(
            r'0\.0\.0\.0\s+0\.0\.0\.0\s+' + RegExp.escape(config.lanGateway),
          ).hasMatch(routes);
          if (hasLanGwDefault) {
            _logger.info(
              'Auto-Healing: Detected default route leaking via LAN gateway (${config.lanGateway}). Healing routing table silently...',
            );
            runOptimization();
          }
        } catch (e) {
          _logger.warning('Auto-Healing daemon failed check: $e');
        }
      });
    } else {
      _logger.info('Auto-Healing daemon deactivated.');
    }
  }

  void switchProfile(String name) {
    if (!config.profiles.containsKey(name)) return;

    config.profiles[config.activeProfile] = {
      'internetGateway': config.internetGateway,
      'backupGateway': config.backupGateway,
      'lanGateway': config.lanGateway,
      'lanNetwork': config.lanNetwork,
      'lanMask': config.lanMask,
      'customLanRoutes': config.customLanRoutes,
      'customInternetRoutes': config.customInternetRoutes,
    };

    final target = config.profiles[name]!;
    final newConfig = config.copyWith(
      activeProfile: name,
      internetGateway: target['internetGateway'] ?? '192.168.100.1',
      backupGateway: target['backupGateway'] ?? '192.168.1.1',
      lanGateway: target['lanGateway'] ?? '172.21.168.1',
      lanNetwork: target['lanNetwork'] ?? '10.0.0.0',
      lanMask: target['lanMask'] ?? '255.0.0.0',
      customLanRoutes: List<String>.from(target['customLanRoutes'] ?? []),
      customInternetRoutes: List<String>.from(
        target['customInternetRoutes'] ?? [],
      ),
    );

    saveConfig(newConfig);
  }

  void createNewProfile(String name) {
    if (name.isEmpty || config.profiles.containsKey(name)) return;

    config.profiles[name] = {
      'internetGateway': config.internetGateway,
      'backupGateway': config.backupGateway,
      'lanGateway': config.lanGateway,
      'lanNetwork': config.lanNetwork,
      'lanMask': config.lanMask,
      'customLanRoutes': List<String>.from(config.customLanRoutes),
      'customInternetRoutes': List<String>.from(config.customInternetRoutes),
    };

    final newConfig = config.copyWith(activeProfile: name);
    saveConfig(newConfig);
  }

  void deleteProfile(String name) {
    if (name == 'Mặc định' || !config.profiles.containsKey(name)) return;

    config.profiles.remove(name);
    if (config.activeProfile == name) {
      switchProfile('Mặc định');
    } else {
      saveConfig(config);
    }
  }

  void setLanguage(String newLanguage) {
    if (config.language == newLanguage) return;
    final newConfig = config.copyWith(language: newLanguage);
    saveConfig(newConfig);
    notifyListeners();
  }

  @override
  void dispose() {
    _autoFixTimer?.cancel();
    super.dispose();
  }
}
