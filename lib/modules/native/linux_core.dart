// lib/modules/native/linux_core.dart
import 'dart:io';
import '../native_bridge.dart';

class LinuxNativeEngine implements NativeEngine {
  @override
  Future<bool> enableIgnoreDefaultRoutes(
    String lanIpPattern,
    int metric,
  ) async {
    return true; // Mocked for Linux development
  }

  @override
  Future<bool> setInterfaceMetric(String ipPattern, int metric) async {
    return true; // Mocked for Linux development
  }

  @override
  Future<bool> flushArpDns() async {
    return true; // Mocked for Linux development
  }

  @override
  Future<bool> cleanOldRoutes(
    String internetGw,
    String lanGw,
    String lanNet,
    String lanMask,
  ) async {
    return true; // Mocked for Linux development
  }

  @override
  Future<bool> addRoute(
    String dest,
    String mask,
    String gw,
    int metric, {
    bool persistent = true,
  }) async {
    return true; // Mocked for Linux development
  }

  @override
  Future<bool> deleteRoute(
    String dest,
    String mask,
    String gw, {
    bool persistent = true,
  }) async {
    return true; // Mocked for Linux development
  }

  @override
  Future<String> runPing(String host, {int count = 4}) async {
    final result = await Process.run('ping', ['-c', count.toString(), host]);
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
      return 'OK: $host:$port reachable';
    } catch (e) {
      return 'WARN: $host:$port not reachable: $e';
    }
  }

  @override
  Future<String> getTailscaleStatus() async {
    try {
      final result = await Process.run('tailscale', ['status']);
      return result.stdout.toString() + result.stderr.toString();
    } catch (e) {
      return 'INFO: Tailscale CLI is not installed or not in PATH ($e).';
    }
  }

  @override
  Future<String> getRoutingTable() async {
    final result = await Process.run('route', ['-n']);
    return result.stdout.toString();
  }

  @override
  Future<bool> backupSettings(
    String backupRegPath,
    String backupJsonPath,
  ) async {
    return true;
  }

  @override
  Future<bool> restoreSettings(
    String backupRegPath,
    String backupJsonPath,
  ) async {
    return true;
  }

  @override
  Future<bool> restoreSystemDefaults() async {
    return true;
  }

  @override
  Future<String?> pickConfigFile() async {
    return null;
  }

  @override
  Future<String?> selectSaveFilePath(
    String defaultFileName, {
    String? filter,
  }) async {
    return null;
  }

  @override
  Future<Map<String, String>> detectActiveGateways() async {
    return {'internetGateway': '', 'lanGateway': ''};
  }

  @override
  Future<Map<String, dynamic>?> queryRouteForIp(String destinationIp) async {
    try {
      final res = await Process.run('ip', ['route', 'get', destinationIp]);
      if (res.exitCode == 0) {
        final out = res.stdout.toString().trim();
        final parts = out.split(RegExp(r'\s+'));
        String? gw;
        String? iface;
        for (var i = 0; i < parts.length - 1; i++) {
          if (parts[i] == 'via') gw = parts[i + 1];
          if (parts[i] == 'dev') iface = parts[i + 1];
        }
        return {
          'gateway': gw ?? '',
          'interfaceAlias': iface ?? '',
          'interfaceIndex': null,
          'metric': null,
        };
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http')) {
      return;
    }
    try {
      await Process.run('xdg-open', [url]);
    } catch (_) {}
  }
}
