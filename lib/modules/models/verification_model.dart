// lib/modules/models/verification_model.dart
import '../utils.dart';

enum TargetType { ip, domain, url }

enum ExpectedRoute { auto, lan, internet }

enum VerifyStatus { pass, warning, fail }

class VerifyTarget {
  final String rawInput;
  final String host;
  final int? port;
  final String? scheme;
  final TargetType targetType;
  final ExpectedRoute expectedRoute;

  const VerifyTarget({
    required this.rawInput,
    required this.host,
    this.port,
    this.scheme,
    required this.targetType,
    this.expectedRoute = ExpectedRoute.auto,
  });

  static void _validateHostPort(String host, int? port) {
    if (port != null && (port < 1 || port > 65535)) {
      throw ArgumentError('Invalid port');
    }
    if (host.isEmpty ||
        !RegExp(r'^[a-zA-Z0-9.-]+$').hasMatch(host) ||
        (RegExp(r'^[0-9.]+$').hasMatch(host) && !isValidIPv4(host))) {
      throw ArgumentError('Expected an IPv4 address or hostname');
    }
  }

  factory VerifyTarget.parse(
    String input, {
    ExpectedRoute expectedRoute = ExpectedRoute.auto,
  }) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Input cannot be empty');
    }

    String candidate = trimmed;
    String? scheme;
    int? port;

    // Check if starts with http:// or https://
    final uri = Uri.tryParse(candidate);
    if (uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https')) {
      scheme = uri.scheme;
      candidate = uri.host;
      if (uri.hasPort) {
        port = uri.port;
      } else {
        port = scheme == 'https' ? 443 : 80;
      }
      _validateHostPort(candidate, port);
      if (uri.userInfo.isNotEmpty) {
        throw ArgumentError('Credentials are not supported');
      }
      return VerifyTarget(
        rawInput: input,
        host: candidate,
        port: port,
        scheme: scheme,
        targetType: TargetType.url,
        expectedRoute: expectedRoute,
      );
    }

    // Check for host:port pattern
    if (candidate.contains(':') && !candidate.contains('::')) {
      final parts = candidate.split(':');
      if (parts.length == 2 && int.tryParse(parts[1]) != null) {
        candidate = parts[0];
        port = int.tryParse(parts[1]);
      }
    }

    // Check if IPv4
    final isIpv4 = RegExp(
      r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$',
    ).hasMatch(candidate);

    _validateHostPort(candidate, port);
    return VerifyTarget(
      rawInput: trimmed,
      host: candidate,
      port: port,
      scheme: scheme,
      targetType: isIpv4 ? TargetType.ip : TargetType.domain,
      expectedRoute: expectedRoute,
    );
  }
}

class FixRecommendation {
  final String title;
  final String description;
  final String? command;
  final bool isQuickFixable;

  const FixRecommendation({
    required this.title,
    required this.description,
    this.command,
    this.isQuickFixable = false,
  });
}

class VerifyResult {
  final VerifyTarget target;
  final VerifyStatus status;
  final String? resolvedIp;
  final List<String> allResolvedIps;
  final int? dnsTimeMs;
  final String? dnsError;
  final String? activeGateway;
  final String? activeInterface;
  final int? metric;
  final bool isMisrouted;
  final int? pingLatencyMs;
  final int? packetLossPercent;
  final int? tcpConnectTimeMs;
  final String? tcpError;
  final int? httpStatusCode;
  final List<String> logs;
  final String? rootCause;
  final List<FixRecommendation> recommendations;

  const VerifyResult({
    required this.target,
    required this.status,
    this.resolvedIp,
    this.allResolvedIps = const [],
    this.dnsTimeMs,
    this.dnsError,
    this.activeGateway,
    this.activeInterface,
    this.metric,
    this.isMisrouted = false,
    this.pingLatencyMs,
    this.packetLossPercent,
    this.tcpConnectTimeMs,
    this.tcpError,
    this.httpStatusCode,
    required this.logs,
    this.rootCause,
    this.recommendations = const [],
  });
}
