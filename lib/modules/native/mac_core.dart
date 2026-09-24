// lib/modules/native/mac_core.dart
import 'dart:io';
import '../native_bridge.dart';

class MacNativeEngine implements NativeEngine {
  @override
  Future<bool> enableIgnoreDefaultRoutes(
    String lanIpPattern,
    int metric,
  ) async {
    return true; // Mocked for macOS development
  }

  @override
  Future<bool> setInterfaceMetric(String ipPattern, int metric) async {
    return true; // Mocked for macOS development
  }

  @override
  Future<bool> flushArpDns() async {
    return true; // Mocked for macOS development
  }

  @override
  Future<bool> cleanOldRoutes(
    String internetGw,
    String lanGw,
    String lanNet,
    String lanMask,
  ) async {
    return true; // Mocked for macOS development
  }

  @override
  Future<bool> addRoute(
    String dest,
    String mask,
    String gw,
    int metric, {
    bool persistent = true,
  }) async {
    return true; // Mocked for macOS development
  }

  @override
  Future<bool> deleteRoute(
    String dest,
    String mask,
    String gw, {
    bool persistent = true,
  }) async {
    return true; // Mocked for macOS development
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
    final result = await Process.run('netstat', ['-rn']);
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
      final res = await Process.run('route', ['-n', 'get', destinationIp]);
      if (res.exitCode == 0) {
        final out = res.stdout.toString();
        String? gw;
        String? iface;
        for (final line in out.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.startsWith('gateway:')) {
            gw = trimmed.replaceFirst('gateway:', '').trim();
          } else if (trimmed.startsWith('interface:')) {
            iface = trimmed.replaceFirst('interface:', '').trim();
          }
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
      await Process.run('open', [url]);
    } catch (_) {}
  }
}
