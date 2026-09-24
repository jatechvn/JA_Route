// lib/modules/native/win_core.dart
import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import '../native_bridge.dart';

final _logger = Logger('WindowsNativeEngine');

class WindowsNativeEngine implements NativeEngine {
  WindowsNativeEngine() {
    _logger.info('Windows Native Engine Initialized.');
  }

  String _psSingleQuoted(String value) => "'${value.replaceAll("'", "''")}'";

  bool _isSafeIpLikePattern(String pattern) {
    final parts = pattern.split('.');
    if (parts.length < 2 || parts.length > 4) return false;

    var wildcardSeen = false;
    for (final part in parts) {
      if (part == '*') {
        wildcardSeen = true;
        continue;
      }
      if (wildcardSeen) return false;

      final octet = int.tryParse(part);
      if (octet == null || octet < 0 || octet > 255) return false;
    }

    return true;
  }

  /// Run command via Process.run with UTF-8 encoding support and logs output
  Future<ProcessResult> _runCommand(
    String executable,
    List<String> arguments, {
    bool runAsCmd = false,
  }) async {
    try {
      if (runAsCmd) {
        final cmdArgs = ['/c', executable, ...arguments];
        _logger.fine('Executing: cmd ${cmdArgs.join(" ")}');
        final result = await Process.run(
          'cmd.exe',
          cmdArgs,
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );
        return result;
      } else {
        _logger.fine('Executing: $executable ${arguments.join(" ")}');
        final result = await Process.run(
          executable,
          arguments,
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );
        return result;
      }
    } catch (e) {
      _logger.severe('Failed to run command $executable: $e');
      return ProcessResult(0, 1, '', 'Failed to run command: $e');
    }
  }

  Future<ProcessResult> _runPowerShell(String command) async {
    _logger.fine('Executing PowerShell: $command');
    return await Process.run(
      'powershell.exe',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', command],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
  }

  @override
  Future<bool> enableIgnoreDefaultRoutes(
    String lanIpPattern,
    int metric,
  ) async {
    if (!_isSafeIpLikePattern(lanIpPattern)) {
      _logger.warning('Rejected unsafe LAN IP pattern: $lanIpPattern');
      return false;
    }

    final patternLiteral = _psSingleQuoted(lanIpPattern);
    final script =
        '\$lan = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {\$_.IPAddress -like $patternLiteral} | Select-Object -First 1; '
        'if (\$lan) { '
        '  \$idx = \$lan.InterfaceIndex; '
        '  \$alias = (Get-NetIPInterface -InterfaceIndex \$idx -AddressFamily IPv4).InterfaceAlias; '
        '  Set-NetIPInterface -InterfaceIndex \$idx -AddressFamily IPv4 -IgnoreDefaultRoutes Enabled -InterfaceMetric $metric -ErrorAction Stop; '
        '  Write-Output "[OK] IgnoreDefaultRoutes enabled on interface: \$alias (Index: \$idx, IP: \$(\$lan.IPAddress))"; '
        '} else { '
        '  throw "LAN adapter matching $lanIpPattern not found"; '
        '}';

    final result = await _runPowerShell(script);
    if (result.exitCode == 0) {
      _logger.info(result.stdout.toString().trim());
      return true;
    } else {
      _logger.warning('Enable IgnoreDefaultRoutes failed: ${result.stderr}');
      return false;
    }
  }

  @override
  Future<bool> setInterfaceMetric(String ipPattern, int metric) async {
    if (!_isSafeIpLikePattern(ipPattern)) {
      _logger.warning('Rejected unsafe adapter IP pattern: $ipPattern');
      return false;
    }

    final patternLiteral = _psSingleQuoted(ipPattern);
    final script =
        '\$n = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {\$_.IPAddress -like $patternLiteral} | Select-Object -First 1; '
        'if (\$n) { '
        '  \$idx = \$n.InterfaceIndex; '
        '  Set-NetIPInterface -InterfaceIndex \$idx -AddressFamily IPv4 -InterfaceMetric $metric -ErrorAction Stop; '
        '  Write-Output "[OK] Set metric $metric on interface with IP pattern $ipPattern (IF index: \$idx)"; '
        '} else { '
        '  throw "Adapter matching $ipPattern not found"; '
        '}';

    final result = await _runPowerShell(script);
    if (result.exitCode == 0) {
      _logger.info(result.stdout.toString().trim());
      return true;
    } else {
      _logger.info(
        'Set interface metric warning: ${result.stderr.toString().trim()} (Adapter $ipPattern might not be active)',
      );
      return false;
    }
  }

  @override
  Future<bool> flushArpDns() async {
    bool ok = true;

    // Flush ARP cache
    final arpRes = await _runCommand('arp', ['-d', '*']);
    if (arpRes.exitCode != 0) {
      _logger.warning(
        'ARP Flush warning (some entries may require administrator rights): ${arpRes.stderr.toString().trim()}',
      );
    } else {
      _logger.info('[OK] ARP cache flushed.');
    }

    // Flush DNS cache
    final dnsRes = await _runCommand('ipconfig', ['/flushdns']);
    if (dnsRes.exitCode != 0) {
      _logger.warning('DNS Flush failed: ${dnsRes.stderr.toString().trim()}');
      ok = false;
    } else {
      _logger.info('[OK] DNS cache flushed.');
    }

    return ok;
  }

  @override
  Future<bool> cleanOldRoutes(
    String internetGw,
    String lanGw,
    String lanNet,
    String lanMask,
  ) async {
    // Perform cleanup commands sequentially
    final commands = [
      ['delete', '0.0.0.0', 'mask', '0.0.0.0', lanGw],
      ['-p', 'delete', '0.0.0.0', 'mask', '0.0.0.0', lanGw],
      ['-p', 'delete', '0.0.0.0', 'mask', '0.0.0.0', internetGw],
      ['-p', 'delete', lanNet, 'mask', lanMask, lanGw],
      ['delete', '0.0.0.0', 'mask', '0.0.0.0', internetGw],
      ['delete', lanNet, 'mask', lanMask, lanGw],
    ];

    for (final args in commands) {
      await _runCommand('route', args);
    }
    _logger.info('[OK] Cleaned old routing entries.');
    return true;
  }

  @override
  Future<bool> addRoute(
    String dest,
    String mask,
    String gw,
    int metric, {
    bool persistent = true,
  }) async {
    final args = <String>[];
    if (persistent) {
      args.add('-p');
    }
    args.addAll(['add', dest, 'mask', mask, gw, 'metric', metric.toString()]);

    final result = await _runCommand('route', args);
    if (result.exitCode == 0) {
      _logger.info(
        '[OK] Added route: $dest mask $mask via $gw (metric $metric, persistent: $persistent)',
      );
      return true;
    } else {
      _logger.warning(
        'Failed to add route $dest via $gw: ${result.stderr.toString().trim()}',
      );
      return false;
    }
  }

  @override
  Future<bool> deleteRoute(
    String dest,
    String mask,
    String gw, {
    bool persistent = true,
  }) async {
    final args = <String>[];
    if (persistent) {
      args.add('-p');
    }
    args.addAll(['delete', dest, 'mask', mask, gw]);

    final result = await _runCommand('route', args);
    return result.exitCode == 0;
  }

  @override
  Future<String> runPing(String host, {int count = 4}) async {
    final result = await _runCommand('ping', ['-n', count.toString(), host]);
    return result.stdout.toString() + result.stderr.toString();
  }

  @override
  Future<String> testConnection(String host, int port) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 4),
      );
      socket.destroy();
      return 'OK: $host:$port is reachable.';
    } catch (e) {
      return 'WARN: $host:$port is NOT reachable ($e).';
    }
  }

  @override
  Future<String> getTailscaleStatus() async {
    // Check if tailscale exists first
    final whereRes = await _runCommand('where', ['tailscale']);
    if (whereRes.exitCode != 0) {
      return 'INFO: Tailscale CLI is not installed or not in PATH.';
    }

    final result = await _runCommand('tailscale', ['status']);
    return result.stdout.toString() + result.stderr.toString();
  }

  @override
  Future<String> getRoutingTable() async {
    final result = await _runCommand('route', ['print', '-4']);
    return result.stdout.toString();
  }

  @override
  Future<bool> backupSettings(
    String backupRegPath,
    String backupJsonPath,
  ) async {
    try {
      // 1. Export registry
      final regRes = await _runCommand('reg', [
        'export',
        'HKLM\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters\\PersistentRoutes',
        backupRegPath,
        '/y',
      ]);
      if (regRes.exitCode != 0) {
        _logger.info(
          'Registry backup warning (No persistent routes to export?): ${regRes.stderr}',
        );
        // Create an empty file to indicate backup was attempted
        File(backupRegPath).writeAsStringSync('; Empty Backup');
      } else {
        _logger.info('[OK] Persistent routes registry exported.');
      }

      // 2. Query NetIPInterface configuration
      final psRes = await _runPowerShell(
        'Get-NetIPInterface -AddressFamily IPv4 | '
        'Select-Object InterfaceIndex, InterfaceAlias, IgnoreDefaultRoutes, InterfaceMetric | '
        'ConvertTo-Json -Compress',
      );
      if (psRes.exitCode == 0 && psRes.stdout.toString().trim().isNotEmpty) {
        final jsonFile = File(backupJsonPath);
        jsonFile.writeAsStringSync(psRes.stdout.toString().trim());
        _logger.info(
          '[OK] Network adapter interface settings backed up to JSON.',
        );
        return true;
      } else {
        _logger.warning('Failed to query adapter settings: ${psRes.stderr}');
        return false;
      }
    } catch (e) {
      _logger.severe('Failed to backup settings: $e');
      return false;
    }
  }

  @override
  Future<bool> restoreSettings(
    String backupRegPath,
    String backupJsonPath,
  ) async {
    try {
      bool ok = true;

      // 1. Restore registry
      if (File(backupRegPath).existsSync()) {
        // First delete existing persistent routes to avoid merge conflicts
        await _runCommand('reg', [
          'delete',
          'HKLM\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters\\PersistentRoutes',
          '/f',
        ]);

        final regRes = await _runCommand('reg', ['import', backupRegPath]);
        if (regRes.exitCode == 0) {
          _logger.info('[OK] Persistent routes restored from registry.');
        } else {
          _logger.warning(
            'Failed to restore persistent routes registry: ${regRes.stderr}',
          );
          ok = false;
        }
      }

      // 2. Restore NetIPInterface configs
      final jsonFile = File(backupJsonPath);
      if (jsonFile.existsSync()) {
        final jsonContent = _psSingleQuoted(jsonFile.readAsStringSync());
        final script =
            '\$adapters = $jsonContent | ConvertFrom-Json; '
            'foreach (\$a in \$adapters) { '
            '  \$ignoreVal = if (\$a.IgnoreDefaultRoutes.value -ne \$null) { \$a.IgnoreDefaultRoutes.value } else { \$a.IgnoreDefaultRoutes }; '
            '  Set-NetIPInterface -InterfaceIndex \$a.InterfaceIndex -AddressFamily IPv4 -IgnoreDefaultRoutes \$ignoreVal -InterfaceMetric \$a.InterfaceMetric -ErrorAction SilentlyContinue; '
            '}';
        final psRes = await _runPowerShell(script);
        if (psRes.exitCode == 0) {
          _logger.info('[OK] Network adapter settings restored.');
        } else {
          _logger.warning(
            'Failed to restore network adapter settings: ${psRes.stderr}',
          );
          ok = false;
        }
      }

      // Flush DNS/ARP
      await flushArpDns();

      return ok;
    } catch (e) {
      _logger.severe('Failed to restore settings: $e');
      return false;
    }
  }

  @override
  Future<bool> restoreSystemDefaults() async {
    try {
      // 1. Delete and recreate persistent routes registry key to clear all persistent routes
      await _runCommand('reg', [
        'delete',
        'HKLM\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters\\PersistentRoutes',
        '/f',
      ]);
      await _runCommand('reg', [
        'add',
        'HKLM\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters\\PersistentRoutes',
        '/f',
      ]);
      _logger.info('[OK] Persistent routes key cleared.');

      // 2. Reset IgnoreDefaultRoutes and AutomaticMetric on all IPv4 adapters
      final script =
          '\$adapters = Get-NetIPInterface -AddressFamily IPv4; '
          'foreach (\$a in \$adapters) { '
          '  Set-NetIPInterface -InterfaceIndex \$a.InterfaceIndex -AddressFamily IPv4 -IgnoreDefaultRoutes Disabled -AutomaticMetric Enabled -ErrorAction SilentlyContinue; '
          '}';
      final psRes = await _runPowerShell(script);
      if (psRes.exitCode == 0) {
        _logger.info(
          '[OK] All network adapters reset to system default (IgnoreDefaultRoutes: Disabled, AutomaticMetric: Enabled).',
        );
      } else {
        _logger.warning(
          'Failed to reset network adapters to default: ${psRes.stderr}',
        );
        return false;
      }

      // 3. Flush DNS/ARP
      await flushArpDns();
      return true;
    } catch (e) {
      _logger.severe('Failed to restore system defaults: $e');
      return false;
    }
  }

  @override
  Future<String?> pickConfigFile() async {
    final script =
        "Add-Type -AssemblyName System.Windows.Forms; "
        "\$f = New-Object System.Windows.Forms.OpenFileDialog; "
        "\$f.Filter = 'JSON Files (*.json)|*.json|All Files (*.*)|*.*'; "
        "\$f.InitialDirectory = (Get-Location).Path; "
        "\$ok = \$f.ShowDialog(); "
        "if (\$ok -eq 'OK') { \$f.FileName }";
    final res = await _runPowerShell(script);
    if (res.exitCode == 0) {
      final path = res.stdout.toString().trim();
      return path.isNotEmpty ? path : null;
    }
    return null;
  }

  @override
  Future<String?> selectSaveFilePath(
    String defaultFileName, {
    String? filter,
  }) async {
    final filterStr =
        filter ?? 'JSON Files (*.json)|*.json|All Files (*.*)|*.*';
    final filterLiteral = _psSingleQuoted(filterStr);
    final fileNameLiteral = _psSingleQuoted(defaultFileName);
    final script =
        "Add-Type -AssemblyName System.Windows.Forms; "
        "\$f = New-Object System.Windows.Forms.SaveFileDialog; "
        "\$f.Filter = $filterLiteral; "
        "\$f.FileName = $fileNameLiteral; "
        "\$f.InitialDirectory = (Get-Location).Path; "
        "\$ok = \$f.ShowDialog(); "
        "if (\$ok -eq 'OK') { \$f.FileName }";
    final res = await _runPowerShell(script);
    if (res.exitCode == 0) {
      final path = res.stdout.toString().trim();
      return path.isNotEmpty ? path : null;
    }
    return null;
  }

  @override
  Future<Map<String, String>> detectActiveGateways() async {
    final script =
        "\$routes = Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Sort-Object RouteMetric; "
        "\$internetGw = ''; "
        "\$lanGw = ''; "
        "foreach (\$r in \$routes) { "
        "  \$gw = \$r.NextHop; "
        "  if (\$gw -and \$gw -ne '0.0.0.0') { "
        "    \$ip = (Get-NetIPAddress -InterfaceIndex \$r.InterfaceIndex -AddressFamily IPv4 | Select-Object -First 1).IPAddress; "
        "    if (\$ip) { "
        "      if (\$ip.StartsWith('172.') -or \$ip.StartsWith('10.')) { "
        "        if (-not \$lanGw) { \$lanGw = \$gw; } "
        "      } else { "
        "        if (-not \$internetGw) { \$internetGw = \$gw; } "
        "      } "
        "    } "
        "  } "
        "} "
        "if (-not \$internetGw -and \$lanGw) { "
        "  \$internetGw = \$lanGw; "
        "  \$lanGw = ''; "
        "} "
        "Write-Output \"\$internetGw,\$lanGw\";";

    final res = await _runPowerShell(script);
    if (res.exitCode == 0) {
      final parts = res.stdout.toString().trim().split(',');
      if (parts.length >= 2) {
        return {
          'internetGateway': parts[0].trim(),
          'lanGateway': parts[1].trim(),
        };
      }
    }
    return {'internetGateway': '', 'lanGateway': ''};
  }

  @override
  Future<Map<String, dynamic>?> queryRouteForIp(String destinationIp) async {
    if (!_isSafeIpLikePattern(destinationIp)) {
      _logger.warning(
        'Rejected unsafe destination IP for route query: $destinationIp',
      );
      return null;
    }

    try {
      final ipLiteral = _psSingleQuoted(destinationIp);
      final psCmd =
          'Find-NetRoute -RemoteIPAddress $ipLiteral | Where-Object NextHop | Select-Object -First 1 NextHop, InterfaceAlias, InterfaceIndex, RouteMetric | ConvertTo-Json -Compress';
      final res = await _runPowerShell(psCmd);
      if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
        final decoded = jsonDecode(res.stdout.toString().trim());
        if (decoded is Map<String, dynamic>) {
          return {
            'gateway': decoded['NextHop']?.toString() ?? '',
            'interfaceAlias': decoded['InterfaceAlias']?.toString() ?? '',
            'interfaceIndex': decoded['InterfaceIndex'] != null
                ? int.tryParse(decoded['InterfaceIndex'].toString())
                : null,
            'metric': decoded['RouteMetric'] != null
                ? int.tryParse(decoded['RouteMetric'].toString())
                : null,
          };
        }
      }
    } catch (e) {
      _logger.warning('Find-NetRoute failed: $e, falling back to route print');
    }

    // A route-print destination filter is not an OS best-route lookup.
    // Report unavailable rather than interpreting interface/header rows as routes.
    return null;
  }

  @override
  Future<void> openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http')) {
      _logger.warning('Rejected unsupported URL: $url');
      return;
    }
    await _runPowerShell('Start-Process ${_psSingleQuoted(url)}');
  }
}
