import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_route/modules/logic.dart';
import 'package:ja_route/modules/models/verification_model.dart';
import 'package:ja_route/modules/native_bridge.dart';
import 'package:ja_route/modules/services/verification_service.dart';
import 'test_environment.dart';

class MockNativeEngine implements NativeEngine {
  Map<String, dynamic>? routeToReturn;
  String? pingOutput;
  String? lastAddedRouteDestination;
  String? lastAddedRouteMask;
  String? lastAddedRouteGateway;
  int? lastAddedRouteMetric;
  bool? lastAddedRoutePersistent;

  @override
  Future<bool> addRoute(
    String dest,
    String mask,
    String gw,
    int metric, {
    bool persistent = true,
  }) async {
    lastAddedRouteDestination = dest;
    lastAddedRouteMask = mask;
    lastAddedRouteGateway = gw;
    lastAddedRouteMetric = metric;
    lastAddedRoutePersistent = persistent;
    return true;
  }

  @override
  Future<Map<String, dynamic>?> queryRouteForIp(String destinationIp) async {
    return routeToReturn;
  }

  @override
  Future<bool> enableIgnoreDefaultRoutes(
    String lanIpPattern,
    int metric,
  ) async => true;

  @override
  Future<bool> setInterfaceMetric(String ipPattern, int metric) async => true;

  @override
  Future<bool> flushArpDns() async => true;

  @override
  Future<bool> cleanOldRoutes(
    String internetGw,
    String lanGw,
    String lanNet,
    String lanMask,
  ) async => true;

  @override
  Future<bool> deleteRoute(
    String dest,
    String mask,
    String gw, {
    bool persistent = true,
  }) async => true;

  @override
  Future<String> runPing(String host, {int count = 4}) async =>
      pingOutput ?? 'Reply from $host: bytes=32 time=5ms TTL=64';

  @override
  Future<String> testConnection(String host, int port) async => 'Success';

  @override
  Future<String> getTailscaleStatus() async => 'Running';

  @override
  Future<String> getRoutingTable() async => 'Active Routes:';

  @override
  Future<bool> backupSettings(
    String backupRegPath,
    String backupJsonPath,
  ) async => true;

  @override
  Future<bool> restoreSettings(
    String backupRegPath,
    String backupJsonPath,
  ) async => true;

  @override
  Future<bool> restoreSystemDefaults() async => true;

  @override
  Future<String?> pickConfigFile() async => null;

  @override
  Future<String?> selectSaveFilePath(
    String defaultFileName, {
    String? filter,
  }) async => null;

  @override
  Future<Map<String, String>> detectActiveGateways() async => {
    'internet': '192.168.50.1',
    'lan': '172.21.168.1',
  };

  @override
  Future<void> openUrl(String url) async {}
}

void main() {
  useIsolatedEnvironment();

  group('VerifyTarget.parse tests', () {
    test('parses plain IPv4 address correctly', () {
      final target = VerifyTarget.parse('192.168.1.50');
      expect(target.targetType, TargetType.ip);
      expect(target.host, '192.168.1.50');
      expect(target.port, isNull);
      expect(target.rawInput, '192.168.1.50');
    });

    test('parses IPv4 with port correctly', () {
      final target = VerifyTarget.parse('10.20.30.40:8443');
      expect(target.targetType, TargetType.ip);
      expect(target.host, '10.20.30.40');
      expect(target.port, 8443);
    });

    test('parses domain with https URL correctly', () {
      final target = VerifyTarget.parse('https://example.com/api/v1?test=1');
      expect(target.targetType, TargetType.url);
      expect(target.host, 'example.com');
      expect(target.port, 443);
      expect(target.scheme, 'https');
    });

    test('parses domain with http URL and custom port correctly', () {
      final target = VerifyTarget.parse(
        'http://portal.company.internal:8080/app',
      );
      expect(target.targetType, TargetType.url);
      expect(target.host, 'portal.company.internal');
      expect(target.port, 8080);
      expect(target.scheme, 'http');
    });

    test('parses plain domain name correctly', () {
      final target = VerifyTarget.parse('intranet.local');
      expect(target.targetType, TargetType.domain);
      expect(target.host, 'intranet.local');
      expect(target.port, isNull);
    });

    test('rejects malformed targets and credential URLs', () {
      for (final input in [
        '999.1.1.1',
        'host:0',
        'host:65536',
        'host:abc',
        'https://',
        'https://user:pass@example.com',
        'ftp://example.com',
      ]) {
        expect(
          () => VerifyTarget.parse(input),
          throwsArgumentError,
          reason: input,
        );
      }
    });

    test('throws ArgumentError on empty input', () {
      expect(() => VerifyTarget.parse(''), throwsArgumentError);
      expect(() => VerifyTarget.parse('   '), throwsArgumentError);
    });
  });

  group('VerificationService misroute & fix tests', () {
    late MockNativeEngine mockEngine;
    late RouteFixerLogic logic;
    late VerificationService service;

    setUp(() {
      mockEngine = MockNativeEngine();
      nativeBridge.engine = mockEngine;
      logic = RouteFixerLogic();
      logic.config = logic.config.copyWith(
        internetGateway: '192.168.50.1',
        lanGateway: '172.21.168.1',
        lanNetwork: '172.21.0.0',
        lanMask: '255.255.0.0',
      );
      service = VerificationService(nativeBridge: nativeBridge, logic: logic);
    });

    test('detects LAN target misrouted through Internet gateway', () async {
      mockEngine.routeToReturn = {
        'NextHop': '192.168.50.1',
        'InterfaceAlias': 'Wi-Fi',
        'InterfaceIndex': 12,
        'RouteMetric': 25,
      };

      final target = VerifyTarget.parse(
        '172.21.168.200',
        expectedRoute: ExpectedRoute.lan,
      );
      final result = await service.verify(target);

      expect(result.status, VerifyStatus.warning);
      expect(result.isMisrouted, isTrue);
      expect(result.activeGateway, '192.168.50.1');
      expect(result.rootCause, contains('192.168.50.1'));
      expect(result.rootCause, contains('Cổng Internet'));
      expect(result.recommendations.isNotEmpty, isTrue);
      expect(result.recommendations.any((r) => r.isQuickFixable), isTrue);
    });

    test('detects Public target misrouted through LAN gateway', () async {
      mockEngine.routeToReturn = {
        'NextHop': '172.21.168.1',
        'InterfaceAlias': 'Ethernet',
        'InterfaceIndex': 5,
        'RouteMetric': 10,
      };

      final target = VerifyTarget.parse(
        '8.8.8.8',
        expectedRoute: ExpectedRoute.internet,
      );
      final result = await service.verify(target);

      expect(result.status, VerifyStatus.warning);
      expect(result.isMisrouted, isTrue);
      expect(result.activeGateway, '172.21.168.1');
      expect(result.rootCause, contains('172.21.168.1'));
      expect(result.rootCause, contains('Cổng LAN'));
      expect(result.recommendations.isNotEmpty, isTrue);
    });

    test('verifies correctly routed target without misroute warning', () async {
      mockEngine.routeToReturn = {
        'NextHop': '172.21.168.1',
        'InterfaceAlias': 'Ethernet',
        'InterfaceIndex': 5,
        'RouteMetric': 10,
      };

      final target = VerifyTarget.parse(
        '172.21.168.50',
        expectedRoute: ExpectedRoute.lan,
      );
      final result = await service.verify(target);

      expect(result.isMisrouted, isFalse);
      expect(result.activeGateway, '172.21.168.1');
    });

    test('HTTP 503 does not pass just because TCP and ping succeed', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final subscription = server.listen((request) async {
        request.response.statusCode = 503;
        await request.response.close();
      });
      try {
        mockEngine.routeToReturn = {'gateway': '0.0.0.0'};
        final result = await service.verify(
          VerifyTarget.parse('http://127.0.0.1:${server.port}/'),
        );
        expect(result.httpStatusCode, 503);
        expect(result.tcpConnectTimeMs, isNotNull);
        expect(result.status, VerifyStatus.fail);
      } finally {
        await server.close(force: true);
        await subscription.cancel();
      }
    });

    test('closed TCP port does not pass just because ping succeeds', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      await server.close();
      mockEngine.routeToReturn = {'gateway': '0.0.0.0'};
      final result = await service.verify(
        VerifyTarget.parse('127.0.0.1:$port'),
      );
      expect(result.tcpError, isNotNull);
      expect(result.status, VerifyStatus.fail);
    });

    test('Auto public fix uses Internet gateway, not LAN', () async {
      mockEngine.routeToReturn = {'gateway': '172.21.168.1'};
      final result = await service.verify(VerifyTarget.parse('8.8.8.8'));
      logic.isAdmin = true;
      expect(await service.executeQuickFix(result), isTrue);
      expect(mockEngine.lastAddedRouteGateway, '192.168.50.1');
    });

    test('unreachable reply must not be treated as ping success', () async {
      mockEngine.pingOutput =
          'Reply from 172.21.168.1: Destination host unreachable.';
      final result = await service.verify(VerifyTarget.parse('172.21.168.200'));
      expect(result.status, VerifyStatus.fail);
      expect(result.packetLossPercent, 100);
      expect(result.recommendations.any((r) => r.isQuickFixable), isFalse);
    });

    test('unknown route cannot claim optimal routing', () async {
      final result = await service.verify(VerifyTarget.parse('8.8.8.8'));
      expect(result.status, VerifyStatus.warning);
      expect(await service.executeQuickFix(result), isFalse);
      expect(mockEngine.lastAddedRouteDestination, isNull);
    });

    test('partial packet loss is retained and warns', () async {
      mockEngine.routeToReturn = {'gateway': '192.168.50.1'};
      mockEngine.pingOutput =
          'Reply from 8.8.8.8: bytes=32 time=5ms TTL=64\n(50% loss)';
      final result = await service.verify(VerifyTarget.parse('8.8.8.8'));
      expect(result.packetLossPercent, 50);
      expect(result.status, VerifyStatus.warning);
    });

    test('executeQuickFix invokes addRoute on native bridge engine', () async {
      final target = VerifyTarget.parse(
        '172.21.168.200',
        expectedRoute: ExpectedRoute.lan,
      );
      final mockResult = VerifyResult(
        target: target,
        status: VerifyStatus.warning,
        resolvedIp: '172.21.168.200',
        activeGateway: '192.168.50.1',
        isMisrouted: true,
        logs: ['Test log'],
      );

      logic.isAdmin = true;
      final ok = await service.executeQuickFix(mockResult);
      expect(ok, isTrue);
      expect(mockEngine.lastAddedRouteDestination, '172.21.168.200');
      expect(mockEngine.lastAddedRouteMask, '255.255.255.255');
      expect(mockEngine.lastAddedRouteGateway, '172.21.168.1');
      expect(mockEngine.lastAddedRouteMetric, 10);
      expect(mockEngine.lastAddedRoutePersistent, true);
    });
  });
}
