// lib/modules/utils.dart
import 'dart:io';
import 'package:logging/logging.dart';

final _logger = Logger('Utils');

/// Checks if the application currently has Administrator privileges on Windows.
Future<bool> checkIsAdmin() async {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    // Return true in unit tests to simulate admin rights and avoid spawning processes
    return true;
  }
  if (!Platform.isWindows) {
    // Non-Windows systems return true for testing convenience
    return true;
  }
  try {
    final result = await Process.run('net', ['session']);
    return result.exitCode == 0;
  } catch (e) {
    _logger.warning('Failed to check administrative privileges: $e');
    return false;
  }
}

/// Validates whether a string is a valid IPv4 address.
bool isValidIPv4(String ip) {
  final regExp = RegExp(
    r'^((25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})\.){3}(25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})$',
  );
  return regExp.hasMatch(ip.trim());
}

/// Validates whether a string is a valid subnet mask.
bool isValidSubnetMask(String mask) {
  if (!isValidIPv4(mask)) return false;

  // A valid subnet mask in binary must have all 1s followed by all 0s
  try {
    final parts = mask.trim().split('.').map(int.parse).toList();
    int binary =
        (parts[0] << 24) + (parts[1] << 16) + (parts[2] << 8) + parts[3];

    // Find the first occurrence of 0 from right to left
    int firstZero = 0;
    while (firstZero < 32 && ((binary >> firstZero) & 1) == 0) {
      firstZero++;
    }

    // The remaining bits must be all 1s
    for (int i = firstZero; i < 32; i++) {
      if (((binary >> i) & 1) == 0) {
        return false; // Found a 0 after a 1 (invalid mask)
      }
    }
    return true;
  } catch (_) {
    return false;
  }
}

class RouteSpec {
  final String destination;
  final String mask;

  const RouteSpec({required this.destination, required this.mask});

  String get configValue => '$destination/$mask';
}

/// Converts a CIDR prefix length (0-32) to a dotted IPv4 subnet mask.
String? subnetMaskFromPrefixLength(int prefixLength) {
  if (prefixLength < 0 || prefixLength > 32) return null;

  final octets = List<int>.generate(4, (index) {
    final remainingBits = prefixLength - (index * 8);
    if (remainingBits >= 8) return 255;
    if (remainingBits <= 0) return 0;
    return 256 - (1 << (8 - remainingBits));
  });

  return octets.join('.');
}

/// Parses "10.0.0.0/255.0.0.0", "10.0.0.0/8", or "10.0.0.0 255.0.0.0".
RouteSpec? parseRouteSpec(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  String destination;
  String maskValue;

  if (trimmed.contains('/')) {
    final parts = trimmed.split('/');
    if (parts.length != 2) return null;
    destination = parts[0].trim();
    maskValue = parts[1].trim();
  } else {
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length != 2) return null;
    destination = parts[0].trim();
    maskValue = parts[1].trim();
  }

  if (!isValidIPv4(destination)) return null;

  final mask = maskValue.contains('.')
      ? maskValue
      : subnetMaskFromPrefixLength(int.tryParse(maskValue) ?? -1);

  if (mask == null || !isValidSubnetMask(mask)) return null;

  return RouteSpec(destination: destination, mask: mask);
}

bool isValidRouteSpec(String value) => parseRouteSpec(value) != null;

String? normalizeRouteSpec(String value) => parseRouteSpec(value)?.configValue;
