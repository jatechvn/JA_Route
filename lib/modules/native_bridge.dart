// lib/modules/native_bridge.dart
import 'dart:io' show Platform;
import 'package:logging/logging.dart';
import 'native/win_core.dart';
import 'native/mac_core.dart';
import 'native/linux_core.dart';

final _logger = Logger('NativeBridge');

abstract class NativeEngine {
  /// Enables IgnoreDefaultRoutes and sets metric on the network adapter matching [lanIpPattern] (e.g. 172.21.*)
  Future<bool> enableIgnoreDefaultRoutes(String lanIpPattern, int metric);

  /// Sets the interface metric for the adapter matching [ipPattern] (e.g. 192.168.100.*)
  Future<bool> setInterfaceMetric(String ipPattern, int metric);

  /// Flushes the ARP cache and DNS resolver cache
  Future<bool> flushArpDns();

  /// Cleans old/incorrect routes from the routing table
  Future<bool> cleanOldRoutes(
    String internetGw,
    String lanGw,
    String lanNet,
    String lanMask,
  );

  /// Adds a routing table entry
  Future<bool> addRoute(
    String dest,
    String mask,
    String gw,
    int metric, {
    bool persistent = true,
  });

  /// Deletes a routing table entry
  Future<bool> deleteRoute(
    String dest,
    String mask,
    String gw, {
    bool persistent = true,
  });

  /// Tests connectivity to [host] via ICMP ping
  Future<String> runPing(String host, {int count = 4});

  /// Tests TCP connection to [host] on [port]
  Future<String> testConnection(String host, int port);

  /// Gets the status of the Tailscale service
  Future<String> getTailscaleStatus();

  /// Gets the active IPv4 routing table
  Future<String> getRoutingTable();

  /// Backs up Windows persistent routes (Registry) and network adapter configurations
  Future<bool> backupSettings(String backupRegPath, String backupJsonPath);

  /// Restores Windows persistent routes and network adapter configurations
  Future<bool> restoreSettings(String backupRegPath, String backupJsonPath);

  /// Restores network settings to Windows/OS defaults (e.g. disable IgnoreDefaultRoutes, automatic metric, clear routes)
  Future<bool> restoreSystemDefaults();

  /// Picks a configuration JSON file using a native file dialog
  Future<String?> pickConfigFile();

  /// Selects a file path to save a configuration file using a native dialog
  Future<String?> selectSaveFilePath(String defaultFileName, {String? filter});

  /// Automatically detects active internet and LAN gateways from the system
  Future<Map<String, String>> detectActiveGateways();

  /// Queries the active operating system route assigned to a specific destination IP
  Future<Map<String, dynamic>?> queryRouteForIp(String destinationIp);

  /// Opens a URL in the default system browser
  Future<void> openUrl(String url);
}

class NativeBridge {
  final String osName;
  NativeEngine? engine;

  NativeBridge() : osName = Platform.operatingSystem {
    _initializeEngine();
  }

  /// Dynamically initializes OS-specific optimized engine
  void _initializeEngine() {
    try {
      if (Platform.isWindows) {
        engine = WindowsNativeEngine();
      } else if (Platform.isMacOS) {
        engine = MacNativeEngine();
      } else if (Platform.isLinux) {
        engine = LinuxNativeEngine();
      } else {
        _logger.warning(
          '[BRIDGE] OS $osName is not supported by Hybrid Core. Using fallback.',
        );
      }
    } catch (e) {
      _logger.severe('[BRIDGE] Failed to initialize engine for $osName: $e');
    }
  }

  /// Check if an engine is loaded
  bool get hasEngine => engine != null;
}

// Singleton instance to be shared across modules
final nativeBridge = NativeBridge();
