// lib/modules/services/verification_service.dart
import 'dart:async';
import 'dart:io';
import 'package:logging/logging.dart';
import '../logic.dart';
import '../models/verification_model.dart';
import '../native_bridge.dart';
import '../utils.dart';

final _logger = Logger('VerificationService');

class VerificationService {
  final NativeBridge nativeBridge;
  final RouteFixerLogic logic;

  VerificationService({required this.nativeBridge, required this.logic});

  bool _isIpInSubnet(String ip, String subnet, String mask) {
    try {
      final ipParts = ip.split('.').map(int.parse).toList();
      final subnetParts = subnet.split('.').map(int.parse).toList();
      final maskParts = mask.split('.').map(int.parse).toList();
      if (ipParts.length != 4 ||
          subnetParts.length != 4 ||
          maskParts.length != 4) {
        return false;
      }
      for (var i = 0; i < 4; i++) {
        if ((ipParts[i] & maskParts[i]) != (subnetParts[i] & maskParts[i])) {
          return false;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _isPrivateIp(String ip) {
    try {
      final parts = ip.split('.').map(int.parse).toList();
      if (parts.length != 4) return false;
      // 10.0.0.0/8
      if (parts[0] == 10) return true;
      // 172.16.0.0/12 (172.16.0.0 - 172.31.255.255)
      if (parts[0] == 172 && parts[1] >= 16 && parts[1] <= 31) return true;
      // 192.168.0.0/16
      if (parts[0] == 192 && parts[1] == 168) return true;
      // 127.0.0.0/8
      if (parts[0] == 127) return true;
    } catch (_) {}
    return false;
  }

  String _formatTime() {
    final now = DateTime.now();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(now.hour)}:${pad(now.minute)}:${pad(now.second)}';
  }

  Future<VerifyResult> verify(VerifyTarget target) async {
    final logs = <String>[];
    void log(String msg) {
      final line = '[${_formatTime()}] $msg';
      logs.add(line);
      _logger.info(line);
    }

    log(
      'Bắt đầu kiểm tra: ${target.host} (Kỳ vọng: ${target.expectedRoute.name.toUpperCase()})',
    );

    String? resolvedIp;
    final allResolvedIps = <String>[];
    int? dnsTimeMs;
    String? dnsError;

    // 1. Phân giải DNS nếu là domain/url
    if (target.targetType == TargetType.ip) {
      resolvedIp = target.host;
      allResolvedIps.add(target.host);
      log('Địa chỉ đích là IPv4: $resolvedIp (Bỏ qua DNS lookup)');
    } else {
      log('Đang phân giải DNS cho tên miền: ${target.host}...');
      final sw = Stopwatch()..start();
      try {
        final addresses = await InternetAddress.lookup(
          target.host,
        ).timeout(const Duration(seconds: 4));
        sw.stop();
        dnsTimeMs = sw.elapsedMilliseconds;
        final ipv4s = addresses
            .where((a) => a.type == InternetAddressType.IPv4)
            .toList();
        if (ipv4s.isNotEmpty) {
          resolvedIp = ipv4s.first.address;
          allResolvedIps.addAll(ipv4s.map((a) => a.address));
          log(
            'Phân giải DNS thành công: ${target.host} -> $resolvedIp (${dnsTimeMs}ms)',
          );
          if (allResolvedIps.length > 1) {
            log('   Các IP phụ: ${allResolvedIps.sublist(1).join(", ")}');
          }
        } else if (addresses.isNotEmpty) {
          resolvedIp = addresses.first.address;
          allResolvedIps.addAll(addresses.map((a) => a.address));
          log(
            'Phân giải DNS (IPv6): ${target.host} -> $resolvedIp (${dnsTimeMs}ms)',
          );
        } else {
          throw const SocketException('No address found');
        }
      } catch (e) {
        sw.stop();
        dnsTimeMs = sw.elapsedMilliseconds;
        dnsError = e.toString();
        log('Lỗi phân giải DNS: $e (${dnsTimeMs}ms)');
        return VerifyResult(
          target: target,
          status: VerifyStatus.fail,
          dnsTimeMs: dnsTimeMs,
          dnsError: dnsError,
          logs: logs,
          rootCause:
              'Không thể phân giải tên miền "${target.host}" thành địa chỉ IP. Máy chủ DNS hiện tại không tìm thấy bản ghi cho địa chỉ này.',
          recommendations: const [
            FixRecommendation(
              title: 'Kiểm tra máy chủ DNS',
              description:
                  'Đảm bảo card mạng của bạn được cấu hình DNS Server đúng (DNS nội bộ cho web nội bộ hoặc 8.8.8.8/1.1.1.1 cho Internet).',
            ),
            FixRecommendation(
              title: 'Xóa bộ nhớ đệm DNS (Flush DNS)',
              description:
                  'Bấm nút "Dọn dẹp DNS & ARP" trong tab Diagnostics để làm sạch cache phân giải bị lỗi.',
            ),
            FixRecommendation(
              title: 'Thử kiểm tra trực tiếp bằng địa chỉ IP',
              description:
                  'Nếu biết IP máy chủ của trang web, hãy nhập trực tiếp IP vào ô verify.',
            ),
          ],
        );
      }
    }

    // 2. Truy vấn Bảng định tuyến Hệ thống (Windows Route Query)
    String? activeGw;
    String? activeIface;
    int? metric;
    log('Đang truy vấn bảng định tuyến hệ điều hành cho IP: $resolvedIp...');
    try {
      final routeInfo = await nativeBridge.engine?.queryRouteForIp(resolvedIp);
      if (routeInfo != null) {
        activeGw = (routeInfo['gateway'] ?? routeInfo['NextHop'])?.toString();
        activeIface =
            (routeInfo['interfaceAlias'] ?? routeInfo['InterfaceAlias'])
                ?.toString();
        metric = (routeInfo['metric'] ?? routeInfo['RouteMetric']) != null
            ? int.tryParse(
                (routeInfo['metric'] ?? routeInfo['RouteMetric']).toString(),
              )
            : null;
        log('Tuyến đường Windows xác định:');
        log(
          '   Gateway phụ trách: ${activeGw?.isEmpty ?? true ? 'On-link (Trực tiếp)' : activeGw}',
        );
        log('   Card mạng (Interface): ${activeIface ?? 'Chưa rõ'}');
        log('   Metric: ${metric ?? 'Mặc định'}');
      } else {
        log(
          'Không thể trích xuất chính xác route từ Windows, sử dụng phân tích dự báo cấu hình.',
        );
      }
    } catch (e) {
      log('Lỗi truy vấn route: $e');
    }

    // 3. Phân tích đối soát Tuyến đường (Misrouted Check)
    final cfg = logic.config;
    final isPrivate = _isPrivateIp(resolvedIp);
    final isInLanSubnet = _isIpInSubnet(
      resolvedIp,
      cfg.lanNetwork,
      cfg.lanMask,
    );
    bool isMisrouted = false;
    String? misrouteReason;

    // Kiểm tra xem IP này có nên đi qua LAN không
    final isLanTarget =
        target.expectedRoute == ExpectedRoute.lan ||
        (target.expectedRoute == ExpectedRoute.auto &&
            (isInLanSubnet || (isPrivate && cfg.lanGateway.isNotEmpty)));

    final isInternetTarget =
        target.expectedRoute == ExpectedRoute.internet ||
        (target.expectedRoute == ExpectedRoute.auto &&
            !isPrivate &&
            cfg.internetGateway.isNotEmpty);

    if (isLanTarget &&
        activeGw != null &&
        activeGw.isNotEmpty &&
        activeGw != '0.0.0.0') {
      if (cfg.internetGateway.isNotEmpty && activeGw == cfg.internetGateway) {
        isMisrouted = true;
        misrouteReason =
            'Đích $resolvedIp thuộc mạng nội bộ LAN nhưng đang bị Windows chuyển tiếp ra Cổng Internet ($activeGw)!';
        log('CẢNH BÁO TUYẾN ĐƯỜNG: $misrouteReason');
      }
    } else if (isInternetTarget &&
        activeGw != null &&
        activeGw.isNotEmpty &&
        activeGw != '0.0.0.0') {
      if (cfg.lanGateway.isNotEmpty && activeGw == cfg.lanGateway) {
        isMisrouted = true;
        misrouteReason =
            'Đích $resolvedIp thuộc Internet công cộng nhưng đang bị gửi vào Cổng LAN nội bộ ($activeGw)!';
        log('CẢNH BÁO TUYẾN ĐƯỜNG: $misrouteReason');
      }
    }

    // 4. Kiểm tra Kết nối Thực tế (TCP / Ping / HTTP)
    int? pingLatencyMs;
    int? packetLossPercent;
    int? tcpConnectTimeMs;
    String? tcpError;
    int? httpStatusCode;

    // TCP Connect nếu có port
    if (target.port != null || target.targetType == TargetType.url) {
      final portToTest = target.port ?? 80;
      log('Đang thử bắt tay TCP tới $resolvedIp:$portToTest...');
      final swTcp = Stopwatch()..start();
      try {
        final socket = await Socket.connect(
          resolvedIp,
          portToTest,
          timeout: const Duration(seconds: 3),
        );
        swTcp.stop();
        tcpConnectTimeMs = swTcp.elapsedMilliseconds;
        socket.destroy();
        log('Kết nối TCP cổng $portToTest thành công (${tcpConnectTimeMs}ms)');
      } catch (e) {
        swTcp.stop();
        tcpError = e.toString();
        log('Không thể kết nối TCP tới cổng $portToTest: $e');
      }
    }

    // HTTP Request nếu là URL
    if (target.targetType == TargetType.url) {
      log('Đang gửi HTTP HEAD request tới ${target.host}...');
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 3);
      try {
        final uri = Uri.parse(target.rawInput.trim());
        final req = await client
            .headUrl(uri)
            .timeout(const Duration(seconds: 4));
        req.followRedirects = false;
        final resp = await req.close().timeout(const Duration(seconds: 4));
        httpStatusCode = resp.statusCode;
        log('Máy chủ HTTP phản hồi mã trạng thái: $httpStatusCode');
      } catch (e) {
        log('HTTP request không phản hồi: ${e.runtimeType}');
      } finally {
        client.close(force: true);
      }
    }

    // ICMP Ping
    log('Đang gửi gói tin ICMP Ping tới $resolvedIp...');
    try {
      final pingOut = await nativeBridge.engine?.runPing(resolvedIp, count: 2);
      if (pingOut != null) {
        if (RegExp(
          r'time[=<]\s*\d+(?:\.\d+)?\s*ms',
          caseSensitive: false,
        ).hasMatch(pingOut)) {
          final timeMatch = RegExp(r'time[=<](\d+)ms').firstMatch(pingOut);
          if (timeMatch != null) {
            pingLatencyMs = int.tryParse(timeMatch.group(1) ?? '');
          }
          final loss = RegExp(
            r'(\d+)%\s*(?:packet\s+)?loss',
          ).firstMatch(pingOut);
          packetLossPercent = loss == null ? 0 : int.tryParse(loss.group(1)!);
          log(
            'Ping ICMP phản hồi tốt: ${pingLatencyMs != null ? "${pingLatencyMs}ms" : "OK"}',
          );
        } else if (pingOut.contains('100% loss') ||
            pingOut.contains('Request timed out') ||
            pingOut.contains('Destination host unreachable')) {
          packetLossPercent = 100;
          log('Ping ICMP không nhận được phản hồi (100% loss)');
        }
      }
    } catch (e) {
      log('Lỗi kiểm tra Ping: $e');
    }

    // 5. Xác định Trạng thái Tổng thể & Hướng dẫn Khắc phục
    VerifyStatus status;
    String? rootCause;
    final recommendations = <FixRecommendation>[];

    final isReachable = target.targetType == TargetType.url
        ? httpStatusCode != null && httpStatusCode < 400
        : target.port != null
        ? tcpConnectTimeMs != null
        : packetLossPercent != null && packetLossPercent < 100;

    if (isMisrouted) {
      status = VerifyStatus.warning;
      rootCause =
          misrouteReason ??
          'Tuyến đường đang chuyển tiếp gói tin qua sai Gateway mạng.';

      final targetGw = isLanTarget ? cfg.lanGateway : cfg.internetGateway;
      if (targetGw.isNotEmpty) {
        recommendations.add(
          FixRecommendation(
            title: 'Sửa Route Nhanh (1-Click Quick Fix)',
            description:
                'Thêm tuyến tĩnh cố định để ép lưu lượng tới $resolvedIp đi qua Gateway $targetGw.',
            command:
                'route add $resolvedIp mask 255.255.255.255 $targetGw metric 10 -p',
            isQuickFixable: true,
          ),
        );
      }
      recommendations.add(
        FixRecommendation(
          title: 'Cập nhật dải mạng trong tab Cấu hình',
          description: isLanTarget
              ? 'Thêm dải mạng chứa IP này (vd: $resolvedIp/32) vào Custom LAN Routes để được tự động bảo trì.'
              : 'Thêm địa chỉ này vào Custom Internet Routes.',
        ),
      );
      recommendations.add(
        const FixRecommendation(
          title: 'Tối ưu lại toàn bộ định tuyến',
          description:
              'Quay lại tab Dashboard và bấm "BẮT ĐẦU FIX" để cân bằng metric 2 card mạng tự động.',
        ),
      );
    } else if (!isReachable) {
      status = VerifyStatus.fail;
      rootCause = httpStatusCode != null
          ? 'Máy chủ HTTP trả về mã lỗi $httpStatusCode; kiểm tra dịch vụ hoặc quyền truy cập.'
          : 'Không nhận được phản hồi từ $resolvedIp (Timeout / Packet Loss). Máy chủ có thể đang tắt, tường lửa chặn cổng, hoặc không có tuyến đường tới đích.';
      recommendations.add(
        const FixRecommendation(
          title: 'Kiểm tra máy chủ và dịch vụ đích',
          description:
              'Xác minh máy chủ đích đang hoạt động và cổng dịch vụ đang mở lắng nghe.',
        ),
      );
      recommendations.add(
        const FixRecommendation(
          title: 'Dọn dẹp ARP và DNS',
          description:
              'Bấm nút "Dọn dẹp DNS & ARP" ở công cụ bên cạnh để làm mới bảng địa chỉ vật lý.',
        ),
      );
    } else if (activeGw == null ||
        (packetLossPercent != null && packetLossPercent > 0)) {
      status = VerifyStatus.warning;
      rootCause =
          'Kết nối có phản hồi nhưng chưa xác minh được tuyến đường hoặc có mất gói.';
    } else {
      status = VerifyStatus.pass;
      log(
        'HOÀN TẤT: Kết nối tối ưu, đi đúng tuyến đường và phản hồi nhanh chóng.',
      );
    }

    return VerifyResult(
      target: target,
      status: status,
      resolvedIp: resolvedIp,
      allResolvedIps: allResolvedIps,
      dnsTimeMs: dnsTimeMs,
      activeGateway: activeGw,
      activeInterface: activeIface,
      metric: metric,
      isMisrouted: isMisrouted,
      pingLatencyMs: pingLatencyMs,
      packetLossPercent: packetLossPercent,
      tcpConnectTimeMs: tcpConnectTimeMs,
      tcpError: tcpError,
      httpStatusCode: httpStatusCode,
      logs: logs,
      rootCause: rootCause,
      recommendations: recommendations,
    );
  }

  Future<bool> executeQuickFix(VerifyResult result) async {
    final ip = result.resolvedIp;
    if (ip == null ||
        !isValidIPv4(ip) ||
        !logic.isAdmin ||
        !result.isMisrouted) {
      return false;
    }

    final cfg = logic.config;
    final useLan =
        result.target.expectedRoute == ExpectedRoute.lan ||
        (result.target.expectedRoute == ExpectedRoute.auto &&
            (_isPrivateIp(ip) ||
                _isIpInSubnet(ip, cfg.lanNetwork, cfg.lanMask)));
    final gw = useLan ? cfg.lanGateway : cfg.internetGateway;

    if (!isValidIPv4(gw)) return false;

    _logger.info('Executing Quick Fix for $ip via gateway $gw...');
    final ok = await nativeBridge.engine?.addRoute(
      ip,
      '255.255.255.255',
      gw,
      10,
      persistent: true,
    );

    return ok ?? false;
  }
}
